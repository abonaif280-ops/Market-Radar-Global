import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/db/audit_logger.dart';
import 'package:field_cases/core/db/seed_data.dart';
import 'package:field_cases/core/files/attachment_storage.dart';
import 'package:field_cases/core/ids/case_id_generator.dart';
import 'package:field_cases/features/cases/data/case_search_index.dart';
import 'package:field_cases/features/cases/data/cases_repository.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_form_data.dart';
import 'package:field_cases/features/cases/domain/case_query.dart';
import 'package:field_cases/features/settings/data/lookup_repository.dart';
import 'package:field_cases/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

void main() {
  late AppDatabase db;
  late CasesRepository repo;
  // الجمعة 25/09/2026 مساءً؛ الأسبوع يبدأ الأحد 20/09.
  final now = DateTime(2026, 9, 25, 20, 0);

  String type(String c) => lookupId(LookupKeys.caseType, c);
  String gov(String c) => lookupId(LookupKeys.governorate, c);
  String src(String c) => lookupId(LookupKeys.reportSource, c);
  String party(String c) => lookupId(LookupKeys.party, c);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CasesRepository(
      db,
      settings: SettingsRepository(db),
      audit: AuditLogger(db),
      storage: AttachmentStorage(Directory.systemTemp),
      idGenerator: CaseIdGenerator(clock: () => now),
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  Future<String> add({
    String caseType = 'SOLID_OBJECT',
    String? governorate = 'YNB',
    String source = '911',
    required DateTime at,
    String location = '',
    String info = '',
    Set<String> parties = const {},
    String? finalText,
  }) {
    return repo.createCase(
      CaseFormData(
        caseTypeId: type(caseType),
        occurredAt: at,
        governorateId: governorate == null ? null : gov(governorate),
        reportSourceId: src(source),
        locationText: location,
        caseInfo: info,
        partyIds: {for (final p in parties) party(p)},
        finalText: finalText,
      ),
      status: CaseStatus.completed,
    );
  }

  Future<Set<String>> ids(CaseQuery q) async =>
      (await repo.searchCases(q, limit: 500)).items.map((i) => i.id).toSet();

  group('text search', () {
    test(
      'finds words regardless of hamza, taa marbuta and attached و',
      () async {
        final a = await add(at: now, parties: {'EOD'});
        final b = await add(at: now, parties: {'CIVIL_DEF'});

        expect(await ids(const CaseQuery(text: 'اداره')), {a});
        expect(await ids(const CaseQuery(text: 'إدارة')), {a});
        expect(await ids(const CaseQuery(text: 'المتفجرات')), {a});
        expect(await ids(const CaseQuery(text: 'الدفاع')), {b});
      },
    );

    test(
      'searches type, governorate, source, location, info and text',
      () async {
        final a = await add(
          at: now,
          caseType: 'DRONE',
          governorate: 'ULA',
          location: 'شمال طريق الهجرة',
          info: 'بقايا محرك',
        );
        await add(at: now, source: 'PATROL', finalText: 'نص عن حريق بسيط');

        expect(await ids(const CaseQuery(text: 'مسيرة')), {a});
        expect(await ids(const CaseQuery(text: 'العلا')), {a});
        expect(await ids(const CaseQuery(text: 'الهجرة')), {a});
        expect(await ids(const CaseQuery(text: 'محرك')), {a});
        expect(await ids(const CaseQuery(text: '911')), {a});
        expect(await ids(const CaseQuery(text: 'دورية')), hasLength(1));
        expect(await ids(const CaseQuery(text: 'بسيط')), hasLength(1));
      },
    );

    test('finds a case by part of its code', () async {
      final a = await add(at: now);
      await add(at: now);
      final code = (await repo.byId(a))!.displayCode; // EVT-20260925-XXXXXX
      expect(await ids(CaseQuery(text: code.substring(13))), {a});
      expect(await ids(CaseQuery(text: code.substring(13).toLowerCase())), {a});
    });

    test('all words must match; short words use a substring scan', () async {
      final a = await add(
        at: now,
        governorate: 'BADR',
        location: 'قرب الميناء',
      );
      await add(at: now, governorate: 'BADR', location: 'وسط البلد');

      expect(await ids(const CaseQuery(text: 'بدر الميناء')), {a});
      expect(await ids(const CaseQuery(text: 'بد')), hasLength(2));
      expect(await ids(const CaseQuery(text: 'لا يوجد شيء كهذا')), isEmpty);
    });

    test('special characters in the query are treated literally', () async {
      await add(at: now, info: 'test "quoted" 50%');
      expect(await ids(const CaseQuery(text: '"quoted"')), hasLength(1));
      expect(await ids(const CaseQuery(text: '%')), hasLength(1));
      expect(await ids(const CaseQuery(text: '_')), isEmpty);
      expect(await ids(const CaseQuery(text: 'AND OR NOT *')), isEmpty);
    });

    test('edits update the index', () async {
      final a = await add(at: now, location: 'الموقع الأول');
      final form = await repo.loadForm(a)
        ..locationText = 'الموقع الجديد';
      await repo.updateCase(a, form, status: CaseStatus.completed);
      expect(await ids(const CaseQuery(text: 'الأول')), isEmpty);
      expect(await ids(const CaseQuery(text: 'الجديد')), {a});
    });

    test('renaming a list item re-indexes affected cases', () async {
      final a = await add(at: now, governorate: 'AIS');
      await LookupRepository(db).rename(gov('AIS'), 'محافظة العيص');
      expect(await ids(const CaseQuery(text: 'محافظة')), {a});
    });

    test('rebuildAll indexes cases inserted without the repository', () async {
      await add(at: now, location: 'مكان خاص');
      await db.customStatement('DELETE FROM ${CaseSearchIndex.table}');
      expect(await ids(const CaseQuery(text: 'خاص')), isEmpty);
      await CaseSearchIndex(db).rebuildAll();
      expect(await ids(const CaseQuery(text: 'خاص')), hasLength(1));
    });
  });

  group('filters', () {
    test('today and this week', () async {
      final today = await add(at: now.subtract(const Duration(hours: 2)));
      final sunday = await add(at: DateTime(2026, 9, 20, 8));
      await add(at: DateTime(2026, 9, 19, 23)); // السبت: الأسبوع الماضي

      expect(await ids(const CaseQuery(datePreset: DatePreset.today)), {today});
      expect(await ids(const CaseQuery(datePreset: DatePreset.week)), {
        today,
        sunday,
      });
    });

    test('custom date range includes both end days', () async {
      await add(at: DateTime(2026, 8, 31, 23));
      final first = await add(at: DateTime(2026, 9, 1, 0, 5));
      final last = await add(at: DateTime(2026, 9, 10, 23, 55));
      await add(at: DateTime(2026, 9, 11, 0, 1));

      final q = CaseQuery(
        datePreset: DatePreset.custom,
        customFrom: DateTime(2026, 9, 1),
        customTo: DateTime(2026, 9, 10),
      );
      expect(await ids(q), {first, last});
      expect(await repo.countCases(q), 2);
    });

    test('type, governorate and report source', () async {
      final a = await add(
        at: now,
        caseType: 'FIRE',
        governorate: 'MED',
        source: 'PATROL',
      );
      await add(at: now, caseType: 'FIRE', governorate: 'YNB');
      await add(at: now, caseType: 'DRONE', governorate: 'MED');

      expect(
        await ids(
          CaseQuery(caseTypeId: type('FIRE'), governorateId: gov('MED')),
        ),
        {a},
      );
      expect(await ids(CaseQuery(reportSourceId: src('PATROL'))), {a});
    });

    test('export states', () async {
      final notExported = await add(at: now);
      final exported = await add(at: now);
      final modified = await add(at: now);
      for (final id in [exported, modified]) {
        await (db.update(db.cases)..where((c) => c.id.equals(id))).write(
          const CasesCompanion(lastExportedRevision: Value(1)),
        );
      }
      final form = await repo.loadForm(modified)
        ..notes = 'تعديل';
      await repo.updateCase(modified, form, status: CaseStatus.completed);

      expect(await ids(const CaseQuery(exportState: ExportState.notExported)), {
        notExported,
      });
      expect(await ids(const CaseQuery(exportState: ExportState.exported)), {
        exported,
      });
      expect(
        await ids(
          const CaseQuery(exportState: ExportState.modifiedAfterExport),
        ),
        {modified},
      );
    });

    test('soft-deleted cases are hidden', () async {
      final a = await add(at: now);
      await (db.update(db.cases)..where((c) => c.id.equals(a))).write(
        CasesCompanion(deletedAt: Value(now.toUtc())),
      );
      expect(await ids(const CaseQuery()), isEmpty);
    });
  });

  group('pagination', () {
    test('pages cover every case exactly once, newest first', () async {
      final created = <String>[];
      for (var i = 0; i < 75; i++) {
        // كل 3 حالات بنفس الوقت لاختبار ترتيب التعادل.
        created.add(await add(at: now.subtract(Duration(minutes: i ~/ 3))));
      }

      final seen = <String>[];
      final times = <DateTime>[];
      CaseCursor? cursor;
      var pages = 0;
      do {
        final page = await repo.searchCases(
          const CaseQuery(),
          after: cursor,
          limit: 30,
        );
        seen.addAll(page.items.map((i) => i.id));
        times.addAll(page.items.map((i) => i.occurredAt));
        cursor = page.next;
        pages++;
      } while (cursor != null);

      expect(pages, 3);
      expect(seen, hasLength(75));
      expect(seen.toSet(), created.toSet());
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isFalse);
      }
      expect(await repo.countCases(const CaseQuery()), 75);
    });

    test('stays fast with thousands of cases', () async {
      const total = 3000;
      final base = now.toUtc();
      await db.batch((b) {
        for (var i = 0; i < total; i++) {
          b.insert(
            db.cases,
            CasesCompanion.insert(
              id: 'case-${i.toString().padLeft(5, '0')}',
              displayCode:
                  'EVT-20260925-${i.toRadixString(16).padLeft(6, '0').toUpperCase()}',
              serialNo: i + 1,
              caseTypeId: type(i.isEven ? 'SOLID_OBJECT' : 'FIRE'),
              occurredAt: base.subtract(Duration(minutes: i)),
              governorateId: Value(gov(i % 3 == 0 ? 'YNB' : 'MED')),
              locationText: Value('موقع رقم $i'),
              originDeviceId: 'DEV-PERF01',
              status: CaseStatus.completed,
              createdAt: base,
              updatedAt: base,
            ),
          );
        }
      });
      await CaseSearchIndex(db).rebuildAll();

      final watch = Stopwatch()..start();
      var page = await repo.searchCases(const CaseQuery());
      for (var i = 0; i < 20; i++) {
        page = await repo.searchCases(const CaseQuery(), after: page.next);
      }
      final pagingMs = watch.elapsedMilliseconds;

      watch.reset();
      final text = await repo.searchCases(const CaseQuery(text: 'رقم 1234'));
      final count = await repo.countCases(
        CaseQuery(caseTypeId: type('FIRE'), governorateId: gov('YNB')),
      );
      final searchMs = watch.elapsedMilliseconds;

      expect(page.items, hasLength(30));
      expect(text.items.map((i) => i.id), contains('case-01234'));
      expect(count, 500);
      // حدود متساهلة لبيئة الاختبار؛ الهدف كشف أي تراجع كبير في الأداء.
      expect(pagingMs, lessThan(2000), reason: '21 صفحة في $pagingMs ms');
      expect(searchMs, lessThan(1000), reason: 'البحث في $searchMs ms');
    });
  });
}

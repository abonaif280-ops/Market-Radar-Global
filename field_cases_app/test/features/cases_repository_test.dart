import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/db/audit_logger.dart';
import 'package:field_cases/core/db/seed_data.dart';
import 'package:field_cases/core/ids/case_id_generator.dart';
import 'package:field_cases/features/cases/data/cases_repository.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_form_data.dart';
import 'package:field_cases/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CasesRepository repo;
  late SettingsRepository settings;
  final now = DateTime(2026, 9, 25, 19, 30);

  String type(String code) => lookupId(LookupKeys.caseType, code);
  String gov(String code) => lookupId(LookupKeys.governorate, code);
  String source(String code) => lookupId(LookupKeys.reportSource, code);
  String party(String code) => lookupId(LookupKeys.party, code);

  CaseFormData sampleForm() => CaseFormData(
    caseTypeId: type('SOLID_OBJECT'),
    occurredAt: now,
    governorateId: gov('BADR'),
    locationText: 'جنوب مركز الرايس',
    reportSourceId: source('911'),
    extraFields: {'has_fire': true, 'object_state': 'أجزاء من جسم'},
    partyIds: {party('CIVIL_DEF'), party('EOD')},
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    await settings.set(SettingKeys.userCode, 'U-117');
    repo = CasesRepository(
      db,
      settings: settings,
      audit: AuditLogger(db),
      idGenerator: CaseIdGenerator(clock: () => now),
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  test('createCase stores ids, serial, parties and audit entry', () async {
    final id = await repo.createCase(
      sampleForm(),
      status: CaseStatus.completed,
    );
    final row = (await repo.byId(id))!;

    expect(row.displayCode, startsWith('EVT-20260925-'));
    expect(row.serialNo, 1);
    expect(row.revision, 1);
    expect(row.contentHash, isNotNull);
    expect(row.status, CaseStatus.completed);
    expect(row.enteredBy, 'U-117');
    expect(row.originDeviceId, await settings.deviceId());

    final form = await repo.loadForm(id);
    expect(form.partyIds, {party('CIVIL_DEF'), party('EOD')});
    expect(form.extraFields['has_fire'], isTrue);
    expect(form.occurredAt, now);

    final audit = await AuditLogger(db).recent();
    expect(audit.single.action, AuditActions.caseCreated);
    expect(audit.single.entityId, id);

    final second = await repo.createCase(
      sampleForm(),
      status: CaseStatus.draft,
    );
    expect((await repo.byId(second))!.serialNo, 2);
  });

  test('saving without content changes keeps the revision', () async {
    final id = await repo.createCase(
      sampleForm(),
      status: CaseStatus.completed,
    );
    final changed = await repo.updateCase(
      id,
      await repo.loadForm(id),
      status: CaseStatus.completed,
    );
    expect(changed, isFalse);
    expect((await repo.byId(id))!.revision, 1);
  });

  test('editing an exported case marks it modified after export', () async {
    final id = await repo.createCase(
      sampleForm(),
      status: CaseStatus.completed,
    );
    // محاكاة التصدير (ينفذ فعليًا في المرحلة 7).
    await (db.update(db.cases)..where((c) => c.id.equals(id))).write(
      const CasesCompanion(lastExportedRevision: Value(1)),
    );
    expect(
      (await repo.watchDetails(id).first)!.displayStatus,
      DisplayStatus.exported,
    );

    final form = await repo.loadForm(id)
      ..hasInjuries = true
      ..injuriesCount = 2;
    expect(
      await repo.updateCase(id, form, status: CaseStatus.completed),
      isTrue,
    );

    final details = (await repo.watchDetails(id).first)!;
    expect(details.revision, 2);
    expect(details.displayStatus, DisplayStatus.modifiedAfterExport);
    expect(details.displayStatus.label, 'تم التعديل بعد التصدير');
  });

  test('status change alone does not bump the revision', () async {
    final id = await repo.createCase(
      sampleForm(),
      status: CaseStatus.completed,
    );
    await repo.setStatus(id, CaseStatus.ready);
    final row = (await repo.byId(id))!;
    expect(row.status, CaseStatus.ready);
    expect(row.revision, 1);
  });

  test('parties are replaced on update', () async {
    final id = await repo.createCase(
      sampleForm(),
      status: CaseStatus.completed,
    );
    final form = await repo.loadForm(id);
    form.partyIds
      ..clear()
      ..add(party('RED_CRESCENT'));
    await repo.updateCase(id, form, status: CaseStatus.completed);
    expect((await repo.loadForm(id)).partyIds, {party('RED_CRESCENT')});
  });

  test('imported cases cannot be edited', () async {
    final id = await repo.createCase(
      sampleForm(),
      status: CaseStatus.completed,
    );
    await (db.update(db.cases)..where((c) => c.id.equals(id))).write(
      const CasesCompanion(reviewState: Value(ReviewState.incoming)),
    );
    expect(
      () async => repo.updateCase(
        id,
        await repo.loadForm(id),
        status: CaseStatus.completed,
      ),
      throwsA(isA<CaseNotEditableException>()),
    );
  });

  test(
    'details resolve labels for lookups, parties and extra fields',
    () async {
      final id = await repo.createCase(
        sampleForm(),
        status: CaseStatus.completed,
      );
      final details = (await repo.watchDetails(id).first)!;

      expect(details.caseTypeLabel, 'جسم صلب');
      expect(details.governorateLabel, 'بدر');
      expect(details.reportSourceLabel, 'العمليات الموحدة (911)');
      expect(details.partyLabels, [
        'الدفاع المدني',
        'إدارة الأسلحة والمتفجرات',
      ]);
      expect(details.extraFields['وجود حريق'], isTrue);
      expect(details.extraFields['حالة الجسم'], 'أجزاء من جسم');
    },
  );

  test('recent list is newest first with place labels', () async {
    await repo.createCase(
      sampleForm()..occurredAt = now.subtract(const Duration(hours: 3)),
      status: CaseStatus.completed,
    );
    await repo.createCase(
      sampleForm()
        ..governorateId = null
        ..locationText = 'طريق الهجرة',
      status: CaseStatus.draft,
    );

    final items = await repo.watchRecent().first;
    expect(items, hasLength(2));
    expect(items.first.placeLabel, 'طريق الهجرة');
    expect(items.first.displayStatus, DisplayStatus.draft);
    expect(items.last.placeLabel, 'بدر');
  });

  test('a failed create rolls back the serial number', () async {
    final bad = sampleForm()..reportSourceId = 'report_source:MISSING';
    await expectLater(
      repo.createCase(bad, status: CaseStatus.completed),
      throwsA(anything),
    );
    expect(await settings.get(SettingKeys.lastSerialNo), isNull);
    expect(await db.select(db.cases).get(), isEmpty);
  });
}

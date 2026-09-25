import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:field_cases/core/app_info.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/db/audit_logger.dart';
import 'package:field_cases/core/db/seed_data.dart';
import 'package:field_cases/core/files/attachment_storage.dart';
import 'package:field_cases/core/ids/case_id_generator.dart';
import 'package:field_cases/features/cases/data/cases_repository.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_form_data.dart';
import 'package:field_cases/features/cases/domain/case_query.dart';
import 'package:field_cases/features/export/data/case_export_service.dart';
import 'package:field_cases/features/packages/data/case_package_reader.dart';
import 'package:field_cases/features/packages/domain/package_models.dart';
import 'package:field_cases/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;
  late AppDatabase db;
  late AttachmentStorage storage;
  late SettingsRepository settings;
  late CasesRepository cases;
  late CaseExportService exporter;
  const reader = CasePackageReader();
  final now = DateTime(2026, 9, 25, 19, 30);

  String id(String key, String code) => lookupId(key, code);

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('export_test');
    db = AppDatabase(NativeDatabase.memory());
    storage = AttachmentStorage(Directory(p.join(temp.path, 'app')));
    settings = SettingsRepository(db);
    await settings.set(SettingKeys.orgName, 'شرطة ينبع');
    await settings.set(SettingKeys.orgCode, 'YNB');
    await settings.set(SettingKeys.userCode, 'U-117');
    final audit = AuditLogger(db);
    cases = CasesRepository(
      db,
      settings: settings,
      audit: audit,
      storage: storage,
      idGenerator: CaseIdGenerator(clock: () => now),
      clock: () => now,
    );
    exporter = CaseExportService(
      db,
      storage: storage,
      settings: settings,
      audit: audit,
      outputDirectory: Directory(p.join(temp.path, 'exports')),
      clock: () => now,
    );
  });
  tearDown(() async {
    await db.close();
    await temp.delete(recursive: true);
  });

  Future<String> photo(String name) async {
    final file = File(p.join(temp.path, 'cam', name));
    await file.create(recursive: true);
    await file.writeAsBytes(
      img.encodeJpg(
        img.Image(width: 64, height: 48)..clear(img.ColorRgb8(9, 9, 9)),
      ),
    );
    return file.path;
  }

  Future<String> addCase({
    CaseStatus status = CaseStatus.completed,
    int photos = 0,
    DateTime? at,
  }) async {
    final form = CaseFormData(
      caseTypeId: id(LookupKeys.caseType, 'SOLID_OBJECT'),
      occurredAt: at ?? now,
      governorateId: id(LookupKeys.governorate, 'YNB'),
      locationText: 'جنوب مركز الرايس',
      reportSourceId: id(LookupKeys.reportSource, '911'),
      extraFields: {'has_fire': true},
      partyIds: {id(LookupKeys.party, 'CIVIL_DEF')},
      latitude: 24.468245,
      longitude: 39.612354,
      finalText: 'نص الحالة',
    );
    for (var i = 0; i < photos; i++) {
      form.attachments.add(await storage.stageImage(await photo('p$i.jpg')));
    }
    return cases.createCase(form, status: status);
  }

  test('file name uses the organisation and time', () {
    expect(
      CaseExportService.fileNameFor(orgName: 'شرطة ينبع', time: now),
      'شرطة_ينبع_20260925_1930.casepkg',
    );
    expect(
      CaseExportService.fileNameFor(orgName: ' ', orgCode: 'A/B', time: now),
      'AB_20260925_1930.casepkg',
    );
    expect(
      CaseExportService.fileNameFor(time: now),
      'حالات_20260925_1930.casepkg',
    );
  });

  test('app version constant matches pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: ${AppInfo.version}'));
  });

  test('exported package round-trips through the reader', () async {
    final a = await addCase(photos: 2);
    final b = await addCase();

    final preview = await exporter.preview(const ExportRequest.unexported());
    expect(preview.caseCount, 2);
    expect(preview.imageCount, 2);

    final result = await exporter.export(const ExportRequest.unexported());
    expect(result.fileName, 'شرطة_ينبع_20260925_1930.casepkg');

    final inspection = await reader.inspect(result.file);
    expect(inspection.errors, isEmpty);
    final manifest = inspection.manifest!;
    expect(manifest.packageFormatVersion, PackageFormat.currentVersion);
    expect(manifest.caseCount, 2);
    expect(manifest.imageCount, 2);
    expect(manifest.appVersion, AppInfo.version);
    expect(manifest.source.orgName, 'شرطة ينبع');
    expect(manifest.source.orgCode, 'YNB');
    expect(manifest.source.deviceId, await settings.deviceId());
    expect(manifest.scope, 'unexported');

    final packaged = inspection.cases.firstWhere((c) => c.caseUuid == a);
    final row = (await cases.byId(a))!;
    expect(packaged.displayCode, row.displayCode);
    expect(packaged.revision, 1);
    expect(packaged.contentHash, row.contentHash);
    expect(packaged.caseType.code, 'SOLID_OBJECT');
    expect(packaged.caseType.label, 'جسم صلب');
    expect(packaged.governorate!.label, 'ينبع');
    expect(packaged.parties.single.label, 'الدفاع المدني');
    expect(packaged.extraFields['has_fire'], isTrue);
    expect(packaged.latitude, 24.468245);
    expect(packaged.finalText, 'نص الحالة');
    expect(packaged.attachments, hasLength(2));
    expect(
      packaged.attachments.first.path,
      'attachments/$a/${row.displayCode}_001.jpg',
    );
    expect(inspection.cases.any((c) => c.caseUuid == b), isTrue);

    // الاستخراج يعيد نفس الصور.
    final out = Directory(p.join(temp.path, 'extract'));
    await reader.extractAttachments(result.file, out);
    for (final att in packaged.attachments) {
      expect(File(p.join(out.path, att.path)).existsSync(), isTrue);
    }
  });

  test('export marks cases, records the batch and audit entry', () async {
    final a = await addCase();
    final result = await exporter.export(ExportRequest.single(a));

    final row = (await cases.byId(a))!;
    expect(row.lastExportedRevision, 1);
    expect(row.lastExportedAt, isNotNull);
    final details = (await cases.watchDetails(a).first)!;
    expect(details.displayStatus, DisplayStatus.exported);

    final batch = await db.select(db.exportBatches).getSingle();
    expect(batch.id, result.manifest.packageId);
    expect(batch.scope, ExportScope.single);
    expect(batch.caseCount, 1);
    final items = await db.select(db.exportBatchItems).get();
    expect(items.single.caseId, a);

    final audit = await AuditLogger(db).recent();
    expect(audit.first.action, AuditActions.packageExported);

    // تعديل بعد التصدير يظهر في "غير المصدرة" مرة أخرى.
    final form = await cases.loadForm(a)
      ..notes = 'إضافة';
    await cases.updateCase(a, form, status: CaseStatus.completed);
    expect(
      (await cases.watchDetails(a).first)!.displayStatus,
      DisplayStatus.modifiedAfterExport,
    );
    final again = await exporter.preview(const ExportRequest.unexported());
    expect(again.caseIds, [a]);
  });

  test('unexported scope skips drafts unless asked', () async {
    await addCase(status: CaseStatus.draft);
    final done = await addCase();
    expect((await exporter.preview(const ExportRequest.unexported())).caseIds, [
      done,
    ]);
    expect(
      (await exporter.preview(
        const ExportRequest.unexported(includeDrafts: true),
      )).caseCount,
      2,
    );
  });

  test('date range scope', () async {
    await addCase(at: DateTime(2026, 8, 31, 23));
    final inside = await addCase(at: DateTime(2026, 9, 5, 10));
    final range = const CaseQuery(datePreset: DatePreset.custom)
        .copyWith(
          customFrom: DateTime(2026, 9, 1),
          customTo: DateTime(2026, 9, 25),
        )
        .dateRange(now)!;
    expect((await exporter.preview(ExportRequest.dateRange(range))).caseIds, [
      inside,
    ]);
  });

  test('nothing to export raises a clear error', () async {
    expect(
      () => exporter.export(const ExportRequest.unexported()),
      throwsA(isA<ExportException>()),
    );
  });

  test('a missing photo aborts the export without marking cases', () async {
    final a = await addCase(photos: 1);
    final attachment = (await cases.loadForm(a)).attachments.single;
    await File(attachment.filePath).delete();

    await expectLater(
      exporter.export(ExportRequest.single(a)),
      throwsA(anything),
    );
    expect((await cases.byId(a))!.lastExportedRevision, isNull);
    expect(await db.select(db.exportBatches).get(), isEmpty);
    final leftovers = Directory(p.join(temp.path, 'exports')).listSync().where(
      (f) => f.path.endsWith('.partial') || f.path.endsWith('.casepkg'),
    );
    expect(leftovers, isEmpty);
  });

  group('reader rejects bad packages', () {
    Future<File> rewrite(
      File source,
      void Function(Map<String, List<int>> files) change,
    ) async {
      final archive = ZipDecoder().decodeBytes(await source.readAsBytes());
      final files = {
        for (final f in archive.files.where((f) => f.isFile))
          f.name: f.readBytes()!.toList(),
      };
      change(files);
      final out = Archive();
      for (final e in files.entries) {
        out.addFile(ArchiveFile.bytes(e.key, e.value));
      }
      final target = File(p.join(temp.path, 'bad_${files.length}.casepkg'));
      await target.writeAsBytes(ZipEncoder().encode(out));
      return target;
    }

    late File good;
    setUp(() async {
      await addCase(photos: 1);
      good = (await exporter.export(const ExportRequest.unexported())).file;
    });

    test('tampered photo', () async {
      final bad = await rewrite(good, (files) {
        final key = files.keys.firstWhere((k) => k.startsWith('attachments/'));
        files[key] = [...files[key]!, 0];
      });
      final result = await reader.inspect(bad);
      expect(result.isValid, isFalse);
      expect(result.errors.join(), contains('تالف'));
    });

    test('edited cases.json', () async {
      final bad = await rewrite(good, (files) {
        final text = utf8.decode(files['cases.json']!);
        files['cases.json'] = utf8.encode(
          text.replaceAll('نص الحالة', 'نص مزور'),
        );
      });
      expect((await reader.inspect(bad)).errors.join(), contains('cases.json'));
    });

    test('missing file and extra file', () async {
      final bad = await rewrite(good, (files) {
        files.removeWhere((k, _) => k.startsWith('attachments/'));
        files['extra.txt'] = [1, 2, 3];
      });
      final errors = (await reader.inspect(bad)).errors.join('\n');
      expect(errors, contains('ملف مفقود'));
      expect(errors, contains('غير مذكور'));
    });

    test('unsafe paths (zip slip)', () async {
      final bad = await rewrite(good, (files) => files['../evil.txt'] = [1]);
      expect((await reader.inspect(bad)).errors.single, contains('غير آمن'));
      expect(CasePackageReader.isSafePath('attachments/x/a.jpg'), isTrue);
      expect(CasePackageReader.isSafePath('/etc/passwd'), isFalse);
      expect(CasePackageReader.isSafePath(r'a\b'), isFalse);
      expect(CasePackageReader.isSafePath('C:/x'), isFalse);
    });

    test('newer format version', () async {
      final bad = await rewrite(good, (files) {
        final json = jsonDecode(
          utf8.decode(files['manifest.json']!),
        ) as Map<String, dynamic>;
        json['package_format_version'] = 99;
        files['manifest.json'] = utf8.encode(jsonEncode(json));
      });
      expect((await reader.inspect(bad)).errors.single, contains('أحدث'));
    });

    test('not a package / encrypted envelope', () async {
      final text = File(p.join(temp.path, 'x.casepkg'))
        ..writeAsStringSync('hello');
      expect((await reader.inspect(text)).errors.single, contains('ليس حزمة'));
      final env = File(p.join(temp.path, 'y.casepkg'))
        ..writeAsBytesSync([...ascii.encode('CASEPKG'), 0, 1, 2]);
      expect((await reader.inspect(env)).errors.single, contains('مشفرة'));
    });
  });
}

import 'dart:io';

import 'package:drift/native.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/db/audit_logger.dart';
import 'package:field_cases/core/db/seed_data.dart';
import 'package:field_cases/core/files/attachment_storage.dart';
import 'package:field_cases/core/ids/case_id_generator.dart';
import 'package:field_cases/features/cases/data/cases_repository.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_form_data.dart';
import 'package:field_cases/features/export/data/case_export_service.dart';
import 'package:field_cases/features/import/data/import_service.dart';
import 'package:field_cases/features/import/data/version_resolution_service.dart';
import 'package:field_cases/features/settings/data/settings_repository.dart';
import 'package:field_cases/features/supervisor/data/inbox_repository.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// جهاز كامل (قاعدة + ملفات) لمحاكاة جوال الموظف وجوال المشرف.
class TestDevice {
  TestDevice(this.root, this.org) : db = AppDatabase(NativeDatabase.memory()) {
    storage = AttachmentStorage(Directory(p.join(root.path, 'app')));
    settings = SettingsRepository(db);
    audit = AuditLogger(db);
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
      outputDirectory: Directory(p.join(root.path, 'exports')),
      clock: () => now,
    );
    importer = ImportService(
      db,
      storage: storage,
      settings: settings,
      audit: audit,
      workDirectory: Directory(p.join(root.path, 'imports')),
      clock: () => now,
    );
    versions = VersionResolutionService(
      db,
      storage: storage,
      settings: settings,
      audit: audit,
      workDirectory: Directory(p.join(root.path, 'imports')),
      clock: () => now,
    );
    inbox = InboxRepository(
      db,
      audit: audit,
      settings: settings,
      clock: () => now,
    );
  }

  static final now = DateTime(2026, 9, 25, 19, 30);
  final Directory root;
  final AppDatabase db;
  late final AttachmentStorage storage;
  late final SettingsRepository settings;
  late final AuditLogger audit;
  late final CasesRepository cases;
  late final CaseExportService exporter;
  late final ImportService importer;
  late final InboxRepository inbox;
  late final VersionResolutionService versions;
  final String org;

  Future<void> init() => settings.set(SettingKeys.orgName, org);

  Future<String> addCase({int photos = 0, String? governorate = 'YNB'}) async {
    final form = CaseFormData(
      caseTypeId: lookupId(LookupKeys.caseType, 'SOLID_OBJECT'),
      occurredAt: now,
      governorateId: governorate == null
          ? null
          : lookupId(LookupKeys.governorate, governorate),
      reportSourceId: lookupId(LookupKeys.reportSource, '911'),
      locationText: 'جنوب مركز الرايس',
      partyIds: {lookupId(LookupKeys.party, 'EOD')},
      finalText: 'نص',
    );
    for (var i = 0; i < photos; i++) {
      final file = File(
        p.join(
          root.path,
          'cam',
          '${DateTime.now().microsecondsSinceEpoch}_$i.jpg',
        ),
      );
      await file.create(recursive: true);
      await file.writeAsBytes(
        img.encodeJpg(
          img.Image(width: 40, height: 30)
            ..clear(img.ColorRgb8(i * 40, 50, 60)),
        ),
      );
      form.attachments.add(await storage.stageImage(file.path));
    }
    return cases.createCase(form, status: CaseStatus.completed);
  }
}

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
import 'package:field_cases/features/cases/domain/case_query.dart';
import 'package:field_cases/features/export/data/case_export_service.dart';
import 'package:field_cases/features/import/data/import_service.dart';
import 'package:field_cases/features/import/domain/duplicate_detector.dart';
import 'package:field_cases/features/settings/data/lookup_repository.dart';
import 'package:field_cases/features/settings/data/settings_repository.dart';
import 'package:field_cases/features/supervisor/data/inbox_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// جهاز كامل (قاعدة + ملفات) لمحاكاة جوال الموظف وجوال المشرف.
class _Device {
  _Device(this.root, this.org) : db = AppDatabase(NativeDatabase.memory()) {
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

void main() {
  late Directory temp;
  late _Device employee;
  late _Device supervisor;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('import_test');
    employee = _Device(Directory(p.join(temp.path, 'employee')), 'شرطة ينبع');
    supervisor = _Device(
      Directory(p.join(temp.path, 'supervisor')),
      'إدارة المنطقة',
    );
    await employee.init();
    await supervisor.init();
  });
  tearDown(() async {
    await employee.db.close();
    await supervisor.db.close();
    await temp.delete(recursive: true);
  });

  test('classification rules', () {
    ImportClassification c(int rev, String hash, ExistingCaseSnapshot? e) =>
        DuplicateDetector.classify(
          incomingRevision: rev,
          incomingHash: hash,
          existing: e,
        );
    const e = ExistingCaseSnapshot(revision: 2, contentHash: 'h2');
    expect(c(1, 'x', null), ImportClassification.newCase);
    expect(c(2, 'h2', e), ImportClassification.duplicate);
    expect(c(5, 'h2', e), ImportClassification.duplicate);
    expect(c(3, 'h3', e), ImportClassification.newer);
    expect(c(1, 'h1', e), ImportClassification.older);
    expect(c(2, 'hX', e), ImportClassification.conflict);
    expect(
      DuplicateDetector.defaultDecision(ImportClassification.newer),
      ImportDecision.pending,
    );
    expect(
      DuplicateDetector.defaultDecision(ImportClassification.duplicate),
      ImportDecision.skip,
    );
  });

  test('employee package is imported into the supervisor inbox', () async {
    final a = await employee.addCase(photos: 2);
    final b = await employee.addCase();
    final package = await employee.exporter.export(
      const ExportRequest.unexported(),
    );

    final report = await supervisor.importer.prepare(package.file.path);
    expect(report.errors, isEmpty);
    expect(report.canImport, isTrue);
    expect(report.manifest!.source.orgName, 'شرطة ينبع');
    expect(report.count(ImportClassification.newCase), 2);
    expect(report.imageCount, 2);

    final outcome = await supervisor.importer.commit(report);
    expect(outcome.importedCases, 2);
    expect(outcome.importedAttachments, 2);

    // نفس المعرفات والرقم الظاهر والمراجعة والبصمة.
    final empRow = (await employee.cases.byId(a))!;
    final supRow = (await supervisor.cases.byId(a))!;
    expect(supRow.displayCode, empRow.displayCode);
    expect(supRow.revision, empRow.revision);
    expect(supRow.contentHash, empRow.contentHash);
    expect(supRow.reviewState, ReviewState.incoming);
    expect(supRow.sourceBatchId, package.manifest.packageId);

    final details = (await supervisor.cases.watchDetails(a).first)!;
    expect(details.displayStatus, DisplayStatus.imported);
    expect(details.isEditable, isFalse);
    expect(details.caseTypeLabel, 'جسم صلب');
    expect(details.partyLabels, ['إدارة الأسلحة والمتفجرات']);
    expect(details.attachments, hasLength(2));
    for (final att in details.attachments) {
      expect(File(att.filePath).existsSync(), isTrue);
      expect(File(att.thumbPath!).existsSync(), isTrue);
    }

    // البحث لدى المشرف يجد الحالة المستوردة.
    final found = await supervisor.cases.searchCases(
      const CaseQuery(text: 'الرايس'),
    );
    expect(found.items.map((i) => i.id), containsAll([a, b]));

    final batches = await supervisor.inbox.watchBatches().first;
    expect(batches.single.title, 'شرطة ينبع');
    expect(batches.single.pendingCount, 2);
    expect(batches.single.imageCount, 2);

    // الحزمة لا تبقى إذا لم تكن هناك قرارات معلقة.
    expect(report.packageFile.existsSync(), isFalse);
  });

  test(
    're-importing the same package is blocked; re-export is deduplicated',
    () async {
      await employee.addCase();
      final first = await employee.exporter.export(
        const ExportRequest.unexported(),
      );
      await supervisor.importer.commit(
        await supervisor.importer.prepare(first.file.path),
      );

      final again = await supervisor.importer.prepare(first.file.path);
      expect(again.alreadyImportedAt, isNotNull);
      expect(again.canImport, isFalse);

      // حزمة جديدة لنفس الحالة دون تعديل: مكررة ولا تُنشأ نسخة ثانية.
      final ids = (await employee.cases.searchCases(const CaseQuery())).items
          .map((i) => i.id)
          .toList();
      final second = await employee.exporter.export(
        ExportRequest.selected(ids),
      );
      final report = await supervisor.importer.prepare(second.file.path);
      expect(report.count(ImportClassification.duplicate), 1);
      expect(report.canImport, isFalse);
      expect(
        await supervisor.db.select(supervisor.db.cases).get(),
        hasLength(1),
      );
    },
  );

  test(
    'an edited case arrives as a newer version awaiting a decision',
    () async {
      final a = await employee.addCase();
      final first = await employee.exporter.export(
        const ExportRequest.unexported(),
      );
      await supervisor.importer.commit(
        await supervisor.importer.prepare(first.file.path),
      );

      final form = await employee.cases.loadForm(a)
        ..notes = 'معلومة إضافية';
      await employee.cases.updateCase(a, form, status: CaseStatus.completed);
      final second = await employee.exporter.export(
        const ExportRequest.unexported(),
      );

      final report = await supervisor.importer.prepare(second.file.path);
      expect(report.count(ImportClassification.newer), 1);
      expect(report.pendingDecision, 1);
      expect(report.canImport, isTrue);

      final outcome = await supervisor.importer.commit(report);
      expect(outcome.importedCases, 0);
      expect(outcome.pendingDecisions, 1);
      // النسخة المحلية لم تتغير بعد، والحزمة محفوظة لقرار المشرف.
      expect((await supervisor.cases.byId(a))!.revision, 1);
      expect(
        File(
          p.join(
            supervisor.root.path,
            'imports',
            '${second.manifest.packageId}.casepkg',
          ),
        ).existsSync(),
        isTrue,
      );
      final items = await supervisor.db
          .select(supervisor.db.importBatchItems)
          .get();
      expect(
        items
            .where((i) => i.batchId == second.manifest.packageId)
            .single
            .decision,
        ImportDecision.pending,
      );
    },
  );

  test('unknown list items from another device are added, not lost', () async {
    final customType = await LookupRepository(employee.db)
        .add(listKey: LookupKeys.caseType, label: 'بلاغ اشتباه');
    final form = CaseFormData(caseTypeId: customType, occurredAt: _Device.now);
    final id = await employee.cases.createCase(
      form,
      status: CaseStatus.completed,
    );
    final pkg = await employee.exporter.export(ExportRequest.single(id));

    await supervisor.importer.commit(
      await supervisor.importer.prepare(pkg.file.path),
    );
    final details = (await supervisor.cases.watchDetails(id).first)!;
    expect(details.caseTypeLabel, 'بلاغ اشتباه');
  });

  test('a failure mid-import rolls back everything', () async {
    await employee.addCase(photos: 1);
    final pkg = await employee.exporter.export(
      const ExportRequest.unexported(),
    );
    final report = await supervisor.importer.prepare(pkg.file.path);

    // تعارض مصطنع: مرفق محلي بنفس معرف المرفق الوارد يجعل الإدراج يفشل.
    final local = await supervisor.addCase();
    final incomingAttachment =
        report.items.single.packagedCase.attachments.single;
    await supervisor.db
        .into(supervisor.db.attachments)
        .insert(
          AttachmentsCompanion.insert(
            id: incomingAttachment.attachmentUuid,
            caseId: local,
            seq: 99,
            kind: AttachmentKind.image,
            fileName: 'x.jpg',
            relativePath: 'attachments/x.jpg',
            mimeType: 'image/jpeg',
            sizeBytes: 1,
            sha256: 'x',
            createdAt: DateTime.now(),
          ),
        );

    await expectLater(supervisor.importer.commit(report), throwsA(anything));

    expect(
      await supervisor.db.select(supervisor.db.importBatches).get(),
      isEmpty,
    );
    expect(
      await supervisor.db.select(supervisor.db.importBatchItems).get(),
      isEmpty,
    );
    final incomingId = report.items.single.packagedCase.caseUuid;
    expect(await supervisor.cases.byId(incomingId), isNull);
    expect(
      Directory(p.join(supervisor.root.path, 'app', 'attachments', incomingId))
              .existsSync()
          ? Directory(
              p.join(supervisor.root.path, 'app', 'attachments', incomingId),
            ).listSync(recursive: true).whereType<File>()
          : const <File>[],
      isEmpty,
    );
  });

  test('inbox approve / reject / under review and batch completion', () async {
    final a = await employee.addCase();
    final b = await employee.addCase();
    final c = await employee.addCase();
    final pkg = await employee.exporter.export(
      const ExportRequest.unexported(),
    );
    await supervisor.importer.commit(
      await supervisor.importer.prepare(pkg.file.path),
    );

    await supervisor.inbox.markUnderReview(a);
    expect(
      (await supervisor.cases.byId(a))!.reviewState,
      ReviewState.underReview,
    );
    expect(await supervisor.inbox.watchPendingCount().first, 3);

    expect(await supervisor.inbox.approve([a, b]), 2);
    expect(await supervisor.inbox.reject([c]), 1);
    // قرار مكرر لا يغير شيئًا.
    expect(await supervisor.inbox.approve([c]), 0);

    expect((await supervisor.cases.byId(a))!.reviewState, ReviewState.approved);
    expect((await supervisor.cases.byId(c))!.reviewState, ReviewState.rejected);
    expect(await supervisor.inbox.watchPendingCount().first, 0);

    final batch = await supervisor.db
        .select(supervisor.db.importBatches)
        .getSingle();
    expect(batch.status, ImportBatchStatus.completed);
    final batches = await supervisor.inbox.watchBatches().first;
    expect(batches.single.approvedCount, 2);
    expect(batches.single.rejectedCount, 1);

    final actions = (await supervisor.audit.recent())
        .map((e) => e.action)
        .toList();
    expect(actions.where((x) => x == AuditActions.caseApproved), hasLength(2));
    expect(actions, contains(AuditActions.caseRejected));
    expect(actions, contains(AuditActions.batchImported));

    final pendingOnly = await supervisor.cases.searchCases(
      CaseQuery(sourceBatchId: pkg.manifest.packageId, pendingReviewOnly: true),
    );
    expect(pendingOnly.items, isEmpty);
  });

  test('today stats group by organisation and type', () async {
    await employee.addCase();
    await employee.addCase();
    final pkg = await employee.exporter.export(
      const ExportRequest.unexported(),
    );
    await supervisor.importer.commit(
      await supervisor.importer.prepare(pkg.file.path),
    );
    await supervisor.addCase();

    final stats = await supervisor.inbox.todayStats();
    expect(stats.total, 3);
    expect(stats.byOrg, {'شرطة ينبع': 2, 'إدارة المنطقة': 1});
    expect(stats.byType, {'جسم صلب': 3});
    expect(stats.pendingReview, 2);
  });

  test('invalid package reports errors and imports nothing', () async {
    final bad = File(p.join(temp.path, 'bad.casepkg'))
      ..writeAsStringSync('not a zip');
    final report = await supervisor.importer.prepare(bad.path);
    expect(report.canImport, isFalse);
    expect(report.errors.single, contains('ليس حزمة'));
    await supervisor.importer.discard(report);
    expect(report.packageFile.existsSync(), isFalse);
  });

  test('pending-review filter in the case search', () async {
    await employee.addCase();
    final pkg = await employee.exporter.export(
      const ExportRequest.unexported(),
    );
    await supervisor.importer.commit(
      await supervisor.importer.prepare(pkg.file.path),
    );
    await supervisor.addCase();
    final pending = await supervisor.cases.searchCases(
      const CaseQuery(pendingReviewOnly: true),
    );
    expect(pending.items, hasLength(1));
    // حالات المشرف الخاصة لا تُعد "غير مصدرة" من الحالات الواردة.
    expect(
      (await supervisor.exporter.preview(const ExportRequest.unexported()))
          .caseCount,
      1,
    );
  });
}

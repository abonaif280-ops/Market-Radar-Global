import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/audit_logger.dart';
import '../../../core/db/seed_data.dart';
import '../../../core/files/attachment_storage.dart';
import '../../cases/data/case_search_index.dart';
import '../../cases/domain/case_enums.dart';
import '../../packages/data/case_package_reader.dart';
import '../../packages/domain/package_models.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/duplicate_detector.dart';

/// حالة واردة مع تصنيفها والقرار المبدئي بشأنها.
class ImportItem {
  const ImportItem({
    required this.packagedCase,
    required this.classification,
    required this.decision,
  });

  final PackagedCase packagedCase;
  final ImportClassification classification;
  final ImportDecision decision;
}

/// تقرير فحص الحزمة قبل الاستيراد (لا شيء أُدخل بعد).
class ImportReport {
  const ImportReport({
    required this.packageFile,
    required this.inspection,
    required this.items,
    this.alreadyImportedAt,
  });

  /// نسخة الحزمة داخل مجلد التطبيق.
  final File packageFile;
  final PackageInspection inspection;
  final List<ImportItem> items;

  /// إذا سبق استيراد نفس الحزمة (نفس package_id).
  final DateTime? alreadyImportedAt;

  PackageManifest? get manifest => inspection.manifest;

  List<String> get errors => [
    ...inspection.errors,
    if (alreadyImportedAt != null) 'سبق استيراد هذه الحزمة',
  ];

  bool get canImport => errors.isEmpty && (toImport > 0 || pendingDecision > 0);

  int count(ImportClassification c) =>
      items.where((i) => i.classification == c).length;

  int get toImport =>
      items.where((i) => i.decision == ImportDecision.import).length;

  int get pendingDecision =>
      items.where((i) => i.decision == ImportDecision.pending).length;

  int get imageCount => items
      .where((i) => i.decision == ImportDecision.import)
      .fold(0, (sum, i) => sum + i.packagedCase.attachments.length);
}

class ImportOutcome {
  const ImportOutcome({
    required this.batchId,
    required this.importedCases,
    required this.importedAttachments,
    required this.pendingDecisions,
  });

  final String batchId;
  final int importedCases;
  final int importedAttachments;
  final int pendingDecisions;
}

class ImportException implements Exception {
  const ImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// استيراد حزم `.casepkg` لدى المشرف (docs/DESIGN.md البند 11):
///
/// 1. [prepare]: نسخ الملف لمجلد التطبيق، فحصه، وتصنيف كل حالة — دون إدخال شيء.
/// 2. [commit]: نقل الصور ثم إدخال كل شيء في Transaction واحدة؛ عند أي خطأ
///    يُتراجع عن قاعدة البيانات وتُحذف الصور المنقولة، فلا تدخل نصف الدفعة.
///
/// الحالات المستوردة تدخل "صندوق الوارد" (review_state = incoming) ولا تصبح
/// معتمدة إلا بقرار المشرف.
class ImportService {
  ImportService(
    this._db, {
    required this._storage,
    required this._settings,
    required this._audit,
    required this.workDirectory,
    this._reader = const CasePackageReader(),
    DateTime Function()? clock,
    Uuid? uuid,
  }) : _clock = clock ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final AttachmentStorage _storage;
  final SettingsRepository _settings;
  final AuditLogger _audit;
  final CasePackageReader _reader;

  /// مجلد خاص بالتطبيق تُحفظ فيه الحزم الواردة (لحين البت في النسخ الأحدث).
  final Directory workDirectory;
  final DateTime Function() _clock;
  final Uuid _uuid;

  Future<ImportReport> prepare(String pickedPath) async {
    final source = File(pickedPath);
    if (!await source.exists()) {
      throw const ImportException('تعذر الوصول إلى الملف المختار');
    }
    await workDirectory.create(recursive: true);
    final copy = File(
      p.join(workDirectory.path, '${_uuid.v4()}.${PackageFormat.extension}'),
    );
    await source.copy(copy.path);

    final inspection = await _reader.inspect(copy);
    if (!inspection.isValid) {
      return ImportReport(
        packageFile: copy,
        inspection: inspection,
        items: const [],
      );
    }

    final previous =
        await (_db.select(_db.importBatches)
              ..where((b) => b.id.equals(inspection.manifest!.packageId)))
            .getSingleOrNull();

    final ids = inspection.cases.map((c) => c.caseUuid).toList();
    final existing = {
      for (final row in await (_db.select(
        _db.cases,
      )..where((c) => c.id.isIn(ids))).get())
        row.id: ExistingCaseSnapshot(
          revision: row.revision,
          contentHash: row.contentHash,
        ),
    };

    final items = [
      for (final c in inspection.cases)
        () {
          final classification = DuplicateDetector.classify(
            incomingRevision: c.revision,
            incomingHash: c.contentHash,
            existing: existing[c.caseUuid],
          );
          return ImportItem(
            packagedCase: c,
            classification: classification,
            decision: DuplicateDetector.defaultDecision(classification),
          );
        }(),
    ];

    return ImportReport(
      packageFile: copy,
      inspection: inspection,
      items: items,
      alreadyImportedAt: previous?.importedAt.toLocal(),
    );
  }

  Future<ImportOutcome> commit(ImportReport report) async {
    if (report.errors.isNotEmpty) throw ImportException(report.errors.first);
    final manifest = report.manifest!;
    final toImport = report.items
        .where((i) => i.decision == ImportDecision.import)
        .toList();

    final extractDir = Directory(
      p.join(workDirectory.path, '${manifest.packageId}_extract'),
    );
    final moved = <String>[];
    try {
      await _reader.extractAttachments(report.packageFile, extractDir);

      // الصور أولًا (خارج Transaction)، مع تسجيلها للتراجع عند الفشل.
      final attachmentPaths = <String, (String, String?)>{};
      for (final item in toImport) {
        final c = item.packagedCase;
        for (final a in c.attachments) {
          final extracted = File(p.join(extractDir.path, a.path));
          final (relative, thumb) = await _storage.adoptImported(
            extracted,
            caseId: c.caseUuid,
            fileName: a.fileName,
          );
          moved.add(relative);
          if (thumb != null) moved.add(thumb);
          attachmentPaths[a.attachmentUuid] = (relative, thumb);
        }
      }

      final attachmentCount = attachmentPaths.length;
      await _db.transaction(() async {
        final now = _clock().toUtc();
        await _db
            .into(_db.importBatches)
            .insert(
              ImportBatchesCompanion.insert(
                id: manifest.packageId,
                orgName: Value(manifest.source.orgName),
                orgCode: Value(manifest.source.orgCode),
                sourceDeviceId: Value(manifest.source.deviceId),
                enteredBy: Value(manifest.source.enteredBy),
                packageCreatedAt: manifest.createdAt,
                importedAt: now,
                formatVersion: manifest.packageFormatVersion,
                caseCount: toImport.length,
                imageCount: attachmentCount,
                attachmentCount: attachmentCount,
                status: toImport.isEmpty && report.pendingDecision == 0
                    ? ImportBatchStatus.completed
                    : ImportBatchStatus.reviewing,
              ),
            );

        final searchIndex = CaseSearchIndex(_db);
        for (final item in toImport) {
          await _insertCase(
            item.packagedCase,
            batchId: manifest.packageId,
            attachmentPaths: attachmentPaths,
            now: now,
          );
          await searchIndex.reindexCase(item.packagedCase.caseUuid);
        }
        for (final item in report.items) {
          await _db
              .into(_db.importBatchItems)
              .insert(
                ImportBatchItemsCompanion.insert(
                  batchId: manifest.packageId,
                  caseId: item.packagedCase.caseUuid,
                  incomingRevision: item.packagedCase.revision,
                  classification: item.classification,
                  decision: item.decision,
                ),
              );
        }
        await _audit.log(
          action: AuditActions.batchImported,
          entityType: 'import_batch',
          entityId: manifest.packageId,
          details: {
            'org_name': manifest.source.orgName,
            'source_device_id': manifest.source.deviceId,
            'imported_cases': toImport.length,
            'attachments': attachmentCount,
            'duplicates': report.count(ImportClassification.duplicate),
            'pending': report.pendingDecision,
          },
          actor: await _settings.get(SettingKeys.userCode),
        );
      });

      // تُحفظ الحزمة باسم package_id إن بقيت نسخ أحدث تنتظر قرارًا (المرحلة 12).
      if (report.pendingDecision > 0) {
        await report.packageFile.rename(
          p.join(
            workDirectory.path,
            '${manifest.packageId}.${PackageFormat.extension}',
          ),
        );
      } else {
        await report.packageFile.delete();
      }

      return ImportOutcome(
        batchId: manifest.packageId,
        importedCases: toImport.length,
        importedAttachments: attachmentCount,
        pendingDecisions: report.pendingDecision,
      );
    } catch (_) {
      await _storage.deleteRelative(moved);
      rethrow;
    } finally {
      if (await extractDir.exists()) await extractDir.delete(recursive: true);
    }
  }

  /// إلغاء الاستيراد بعد الفحص: حذف نسخة الحزمة.
  Future<void> discard(ImportReport report) async {
    if (await report.packageFile.exists()) await report.packageFile.delete();
  }

  // ------------------------------------------------------------ داخلي

  Future<void> _insertCase(
    PackagedCase c, {
    required String batchId,
    required Map<String, (String, String?)> attachmentPaths,
    required DateTime now,
  }) async {
    final caseTypeId = await _lookupFor(LookupKeys.caseType, c.caseType);
    final governorateId = await _lookupFor(
      LookupKeys.governorate,
      c.governorate,
    );
    final centerId = await _lookupFor(LookupKeys.center, c.center);
    final sourceId = await _lookupFor(LookupKeys.reportSource, c.reportSource);

    await _db
        .into(_db.cases)
        .insert(
          CasesCompanion.insert(
            id: c.caseUuid,
            displayCode: c.displayCode,
            serialNo: c.serialNo,
            caseTypeId: caseTypeId!,
            occurredAt: c.occurredAt.toUtc(),
            governorateId: Value(governorateId),
            centerId: Value(centerId),
            locationText: Value(c.locationText),
            reportSourceId: Value(sourceId),
            locationDescription: Value(c.locationDescription),
            latitude: Value(c.latitude),
            longitude: Value(c.longitude),
            caseInfo: Value(c.caseInfo),
            actionTaken: Value(c.actionTaken),
            hasInjuries: Value(c.hasInjuries),
            injuriesCount: Value(c.injuriesCount),
            hasDeaths: Value(c.hasDeaths),
            deathsCount: Value(c.deathsCount),
            hasDamage: Value(c.hasDamage),
            damageDescription: Value(c.damageDescription),
            notes: Value(c.notes),
            extraFieldsJson: Value(jsonEncode(c.extraFields)),
            finalText: Value(c.finalText),
            isTextEdited: Value(c.isTextEdited),
            enteredBy: Value(c.enteredBy),
            orgCode: Value(c.orgCode),
            originDeviceId: c.originDeviceId,
            revision: Value(c.revision),
            contentHash: Value(c.contentHash),
            status: CaseStatus.values.firstWhere(
              (s) => s.name == c.status,
              orElse: () => CaseStatus.completed,
            ),
            reviewState: const Value(ReviewState.incoming),
            sourceBatchId: Value(batchId),
            createdAt: c.createdAt.toUtc(),
            updatedAt: c.updatedAt.toUtc(),
          ),
        );

    for (final party in c.parties) {
      final partyId = await _lookupFor(LookupKeys.party, party);
      await _db
          .into(_db.caseParties)
          .insert(
            CasePartiesCompanion.insert(caseId: c.caseUuid, partyId: partyId!),
            mode: InsertMode.insertOrIgnore,
          );
    }

    for (final a in c.attachments) {
      final (relative, thumb) = attachmentPaths[a.attachmentUuid]!;
      await _db
          .into(_db.attachments)
          .insert(
            AttachmentsCompanion.insert(
              id: a.attachmentUuid,
              caseId: c.caseUuid,
              seq: a.seq,
              kind: AttachmentKind.values.firstWhere(
                (k) => k.name == a.kind,
                orElse: () => AttachmentKind.file,
              ),
              fileName: a.fileName,
              relativePath: relative,
              thumbRelativePath: Value(thumb),
              mimeType: a.mimeType,
              sizeBytes: a.size,
              sha256: a.sha256,
              width: Value(a.width),
              height: Value(a.height),
              createdAt: now,
            ),
          );
    }
  }

  /// يربط عنصر القائمة الوارد بالمحلي بالرمز؛ وإن لم يوجد يُضاف باسمه
  /// (قوائم الأجهزة قد تختلف) حتى لا تضيع المعلومة.
  Future<String?> _lookupFor(String listKey, PackagedLookup? item) async {
    if (item == null) return null;
    final existing =
        await (_db.select(_db.lookupItems)..where(
              (l) => l.listKey.equals(listKey) & l.code.equals(item.code),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;

    final id = lookupId(listKey, item.code);
    final maxOrder = _db.lookupItems.sortOrder.max();
    final order =
        await (_db.selectOnly(_db.lookupItems)
              ..addColumns([maxOrder])
              ..where(_db.lookupItems.listKey.equals(listKey)))
            .map((r) => r.read(maxOrder))
            .getSingle();
    await _db
        .into(_db.lookupItems)
        .insert(
          LookupItemsCompanion.insert(
            id: id,
            listKey: listKey,
            code: item.code,
            label: item.label,
            sortOrder: Value((order ?? -1) + 1),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return id;
  }
}

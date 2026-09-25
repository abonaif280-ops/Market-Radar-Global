import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/app_info.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/audit_logger.dart';
import '../../../core/files/attachment_storage.dart';
import '../../cases/domain/case_enums.dart';
import '../../cases/domain/case_query.dart';
import '../../packages/data/case_package_writer.dart';
import '../../packages/data/case_snapshot_builder.dart';
import '../../packages/domain/package_models.dart';
import '../../settings/data/settings_repository.dart';

/// ما المطلوب تصديره.
class ExportRequest {
  const ExportRequest.single(String caseId)
    : scope = ExportScope.single,
      caseIds = const [],
      _single = caseId,
      range = null,
      includeDrafts = true;

  const ExportRequest.selected(this.caseIds)
    : scope = ExportScope.selected,
      _single = null,
      range = null,
      includeDrafts = true;

  /// كل ما لم يُصدَّر بعد + ما عُدّل بعد آخر تصدير.
  const ExportRequest.unexported({this.includeDrafts = false})
    : scope = ExportScope.unexported,
      caseIds = const [],
      _single = null,
      range = null;

  const ExportRequest.dateRange(
    DateRange this.range, {
    this.includeDrafts = false,
  }) : scope = ExportScope.dateRange,
       caseIds = const [],
       _single = null;

  final ExportScope scope;
  final List<String> caseIds;
  final String? _single;
  final DateRange? range;
  final bool includeDrafts;

  List<String> get explicitIds => _single == null ? caseIds : [_single];
}

/// ملخص قبل التصدير.
class ExportPreview {
  const ExportPreview({
    required this.caseIds,
    required this.imageCount,
    required this.totalBytes,
  });

  final List<String> caseIds;
  final int imageCount;
  final int totalBytes;

  int get caseCount => caseIds.length;
}

class ExportResult {
  const ExportResult({
    required this.file,
    required this.manifest,
    required this.sizeBytes,
  });

  final File file;
  final PackageManifest manifest;
  final int sizeBytes;

  String get fileName => p.basename(file.path);
}

class ExportException implements Exception {
  const ExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// تصدير الحالات في حزمة `.casepkg` وتعليمها "تم التصدير".
class CaseExportService {
  CaseExportService(
    this._db, {
    required this._storage,
    required this._settings,
    required this._audit,
    required this.outputDirectory,
    this._writer = const CasePackageWriter(),
    DateTime Function()? clock,
    Uuid? uuid,
  }) : _clock = clock ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final AttachmentStorage _storage;
  final SettingsRepository _settings;
  final AuditLogger _audit;
  final CasePackageWriter _writer;
  late final CaseSnapshotBuilder _snapshots = CaseSnapshotBuilder(
    _db,
    storage: _storage,
  );

  /// مجلد مؤقت خاص بالتطبيق؛ الملف يُشارك منه ثم يُحذف عند التشغيل التالي.
  final Directory outputDirectory;
  final DateTime Function() _clock;
  final Uuid _uuid;

  Future<ExportPreview> preview(ExportRequest request) async {
    final ids = await _resolveCaseIds(request);
    if (ids.isEmpty) {
      return const ExportPreview(caseIds: [], imageCount: 0, totalBytes: 0);
    }
    final count = _db.attachments.id.count();
    final size = _db.attachments.sizeBytes.sum();
    final row =
        await (_db.selectOnly(_db.attachments)
              ..addColumns([count, size])
              ..where(
                _db.attachments.caseId.isIn(ids) &
                    _db.attachments.deletedAt.isNull(),
              ))
            .getSingle();
    return ExportPreview(
      caseIds: ids,
      imageCount: row.read(count) ?? 0,
      totalBytes: row.read(size) ?? 0,
    );
  }

  Future<ExportResult> export(ExportRequest request) async {
    final ids = await _resolveCaseIds(request);
    if (ids.isEmpty) {
      throw const ExportException('لا توجد حالات للتصدير');
    }

    final now = _clock();
    final packageId = _uuid.v4();
    final orgName = await _settings.get(SettingKeys.orgName);
    final orgCode = await _settings.get(SettingKeys.orgCode);
    final source = PackageSource(
      deviceId: await _settings.deviceId(),
      orgName: _nullIfEmpty(orgName),
      orgCode: _nullIfEmpty(orgCode),
      enteredBy: _nullIfEmpty(await _settings.get(SettingKeys.userCode)),
    );

    final cases = <PackagedCase>[];
    final files = <String, String>{};
    for (final id in ids) {
      final (packaged, caseFiles) = await _snapshots.build(id);
      cases.add(packaged);
      files.addAll(caseFiles);
    }

    await outputDirectory.create(recursive: true);
    final output = File(
      p.join(
        outputDirectory.path,
        fileNameFor(orgName: orgName, orgCode: orgCode, time: now),
      ),
    );
    final manifest = await _writer.write(
      output: output,
      packageId: packageId,
      createdAt: now,
      appVersion: AppInfo.version,
      source: source,
      scope: request.scope.name,
      cases: cases,
      attachmentFiles: files,
    );

    await _markExported(
      packageId: packageId,
      request: request,
      fileName: p.basename(output.path),
      cases: cases,
      manifest: manifest,
      at: now.toUtc(),
    );

    return ExportResult(
      file: output,
      manifest: manifest,
      sizeBytes: await output.length(),
    );
  }

  /// يحذف ملفات التصدير السابقة (نُسخها المشاركة موجودة لدى المستلم).
  Future<void> clearOutput() async {
    if (await outputDirectory.exists()) {
      await outputDirectory.delete(recursive: true);
    }
  }

  /// `ينبع_20260925_1930.casepkg` — أحرف غير صالحة في أسماء الملفات تُستبدل.
  static String fileNameFor({
    String? orgName,
    String? orgCode,
    required DateTime time,
  }) {
    final base = [
      orgName,
      orgCode,
      'حالات',
    ].whereType<String>().map((s) => s.trim()).firstWhere((s) => s.isNotEmpty);
    final safe = base
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final t = time.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}';
    return '${safe.isEmpty ? 'حالات' : safe}_$stamp.${PackageFormat.extension}';
  }

  // ------------------------------------------------------------ داخلي

  Future<List<String>> _resolveCaseIds(ExportRequest request) async {
    final c = _db.cases;
    Expression<bool> where = c.deletedAt.isNull();
    switch (request.scope) {
      case ExportScope.single || ExportScope.selected:
        if (request.explicitIds.isEmpty) return const [];
        where = where & c.id.isIn(request.explicitIds);
      case ExportScope.unexported:
        // الحالات المستوردة لدى المشرف تُصدَّر بالتصدير الشامل (المرحلة 10).
        where =
            where &
            c.reviewState.isNull() &
            (c.lastExportedRevision.isNull() |
                c.lastExportedRevision.isSmallerThan(c.revision));
      case ExportScope.dateRange:
        final range = request.range!;
        where =
            where &
            c.occurredAt.isBiggerOrEqualValue(range.from.toUtc()) &
            c.occurredAt.isSmallerThanValue(range.to.toUtc());
    }
    if (!request.includeDrafts) {
      where = where & c.status.equalsValue(CaseStatus.draft).not();
    }
    return (_db.selectOnly(c)
          ..addColumns([c.id])
          ..where(where)
          ..orderBy([OrderingTerm.asc(c.occurredAt)]))
        .map((r) => r.read(c.id)!)
        .get();
  }

  /// يعلّم كل حالة بالمراجعة التي صُدّرت فعلًا؛ إن عُدّلت أثناء التصدير
  /// تبقى "معدلة بعد التصدير".
  Future<void> _markExported({
    required String packageId,
    required ExportRequest request,
    required String fileName,
    required List<PackagedCase> cases,
    required PackageManifest manifest,
    required DateTime at,
  }) {
    return _db.transaction(() async {
      await _db
          .into(_db.exportBatches)
          .insert(
            ExportBatchesCompanion.insert(
              id: packageId,
              createdAt: at,
              scope: request.scope,
              fileName: fileName,
              caseCount: cases.length,
              attachmentCount: manifest.attachmentCount,
              packageSha256: Value(manifest.contentSha256),
            ),
          );
      for (final c in cases) {
        await _db
            .into(_db.exportBatchItems)
            .insert(
              ExportBatchItemsCompanion.insert(
                batchId: packageId,
                caseId: c.caseUuid,
                revision: c.revision,
              ),
            );
        await (_db.update(_db.cases)..where(
              (row) =>
                  row.id.equals(c.caseUuid) &
                  (row.lastExportedRevision.isNull() |
                      row.lastExportedRevision.isSmallerThanValue(c.revision)),
            ))
            .write(
              CasesCompanion(
                lastExportedRevision: Value(c.revision),
                lastExportedAt: Value(at),
              ),
            );
      }
      await _audit.log(
        action: AuditActions.packageExported,
        entityType: 'package',
        entityId: packageId,
        details: {
          'file_name': fileName,
          'scope': request.scope.name,
          'cases': cases.length,
          'attachments': manifest.attachmentCount,
        },
        actor: await _settings.get(SettingKeys.userCode),
      );
    });
  }

  static String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

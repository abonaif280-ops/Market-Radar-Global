import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/app_database.dart';
import '../../../core/db/audit_logger.dart';
import '../../../core/files/attachment_storage.dart';
import '../../cases/data/case_search_index.dart';
import '../../settings/data/settings_repository.dart';

/// حالة في "المحذوفات".
class DeletedCase {
  const DeletedCase({
    required this.id,
    required this.displayCode,
    required this.caseTypeLabel,
    required this.occurredAt,
    required this.deletedAt,
    required this.photoCount,
  });

  final String id;
  final String displayCode;
  final String caseTypeLabel;
  final DateTime occurredAt;
  final DateTime deletedAt;
  final int photoCount;
}

class PurgeResult {
  const PurgeResult({required this.cases, required this.files});

  final int cases;
  final int files;
}

/// الحذف على مرحلتين (docs/REQUIREMENTS.md البند 32):
///
/// 1. **حذف مرن**: يضبط `deleted_at` للحالة فتختفي من القوائم والبحث والتصدير.
///    صورها تبقى كما هي فتعود كاملة عند الاستعادة (والصور المحذوفة سابقًا
///    من الحالة تبقى محذوفة).
/// 2. **حذف نهائي** من "المحذوفات": يحذف السجلات والملفات ولا يمكن التراجع.
///
/// كل عملية في Transaction وتُسجَّل في Audit Log.
class TrashRepository {
  TrashRepository(
    this._db, {
    required this._settings,
    required this._audit,
    required this._storage,
    DateTime Function()? clock,
  }) : _index = CaseSearchIndex(_db),
       _clock = clock ?? DateTime.now;

  static const String auditEntity = 'case';

  final AppDatabase _db;
  final SettingsRepository _settings;
  final AuditLogger _audit;
  final AttachmentStorage _storage;
  final CaseSearchIndex _index;
  final DateTime Function() _clock;

  Future<void> softDelete(String caseId) {
    return _db.transaction(() async {
      final row = await _find(caseId);
      if (row == null || row.deletedAt != null) return;
      await (_db.update(_db.cases)..where((c) => c.id.equals(caseId))).write(
        CasesCompanion(deletedAt: Value(_clock().toUtc())),
      );
      await _index.removeCase(caseId);
      await _log(AuditActions.caseDeleted, row);
    });
  }

  Future<void> restore(String caseId) {
    return _db.transaction(() async {
      final row = await _find(caseId);
      if (row == null || row.deletedAt == null) return;
      await (_db.update(_db.cases)..where((c) => c.id.equals(caseId))).write(
        const CasesCompanion(deletedAt: Value(null)),
      );
      await _index.reindexCase(caseId);
      await _log(AuditActions.caseRestored, row);
    });
  }

  /// حذف نهائي لحالة موجودة في المحذوفات فقط.
  Future<PurgeResult> purge(String caseId) async {
    final paths = <String>[];
    final purged = await _db.transaction(() async {
      final row = await _find(caseId);
      if (row == null || row.deletedAt == null) return false;
      paths.addAll(await _purgeRows(row));
      await _log(AuditActions.casePurged, row);
      return true;
    });
    if (!purged) return const PurgeResult(cases: 0, files: 0);
    final files = await _deleteFiles(paths, caseDirs: {caseId});
    return PurgeResult(cases: 1, files: files);
  }

  /// "إفراغ المحذوفات": كل الحالات المحذوفة، وملفات الصور المحذوفة من
  /// حالات قائمة (تبقى سجلاتها حتى لا يتكرر رقم صورة).
  Future<PurgeResult> purgeAll() async {
    final paths = <String>[];
    final caseIds = <String>{};
    await _db.transaction(() async {
      final rows = await (_db.select(
        _db.cases,
      )..where((c) => c.deletedAt.isNotNull())).get();
      for (final row in rows) {
        paths.addAll(await _purgeRows(row));
        caseIds.add(row.id);
        await _log(AuditActions.casePurged, row);
      }
      final removedPhotos = await (_db.select(
        _db.attachments,
      )..where((a) => a.deletedAt.isNotNull())).get();
      for (final a in removedPhotos) {
        paths.add(a.relativePath);
        if (a.thumbRelativePath != null) paths.add(a.thumbRelativePath!);
      }
    });
    final files = await _deleteFiles(paths, caseDirs: caseIds);
    return PurgeResult(cases: caseIds.length, files: files);
  }

  Stream<List<DeletedCase>> watchDeleted() {
    final type = _db.alias(_db.lookupItems, 'type');
    final photos = _db.attachments.id.count(
      filter: _db.attachments.deletedAt.isNull(),
    );
    final query =
        _db.select(_db.cases).join([
            innerJoin(type, type.id.equalsExp(_db.cases.caseTypeId)),
            leftOuterJoin(
              _db.attachments,
              _db.attachments.caseId.equalsExp(_db.cases.id),
            ),
          ])
          ..where(_db.cases.deletedAt.isNotNull())
          ..addColumns([photos])
          ..groupBy([_db.cases.id])
          ..orderBy([OrderingTerm.desc(_db.cases.deletedAt)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          DeletedCase(
            id: r.readTable(_db.cases).id,
            displayCode: r.readTable(_db.cases).displayCode,
            caseTypeLabel: r.readTable(type).label,
            occurredAt: r.readTable(_db.cases).occurredAt.toLocal(),
            deletedAt: r.readTable(_db.cases).deletedAt!.toLocal(),
            photoCount: r.read(photos) ?? 0,
          ),
      ],
    );
  }

  Stream<int> watchCount() {
    final count = _db.cases.id.count();
    return (_db.selectOnly(_db.cases)
          ..addColumns([count])
          ..where(_db.cases.deletedAt.isNotNull()))
        .map((r) => r.read(count) ?? 0)
        .watchSingle();
  }

  // ------------------------------------------------------------ داخلي

  Future<CaseRecord?> _find(String id) =>
      (_db.select(_db.cases)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// يحذف السجلات المرتبطة ثم الحالة، ويعيد مسارات الملفات لحذفها بعد الـ Commit.
  Future<List<String>> _purgeRows(CaseRecord row) async {
    final attachments = await (_db.select(
      _db.attachments,
    )..where((a) => a.caseId.equals(row.id))).get();
    await (_db.delete(
      _db.attachments,
    )..where((a) => a.caseId.equals(row.id))).go();
    await (_db.delete(
      _db.caseParties,
    )..where((x) => x.caseId.equals(row.id))).go();
    await (_db.delete(
      _db.caseVersions,
    )..where((x) => x.caseId.equals(row.id))).go();
    // سجل الدفعة يبقى (عدد الحالات فيه)، ويُزال ربطها بالحالة المحذوفة نهائيًا.
    await (_db.delete(
      _db.exportBatchItems,
    )..where((x) => x.caseId.equals(row.id))).go();
    await (_db.delete(_db.cases)..where((c) => c.id.equals(row.id))).go();
    await _index.removeCase(row.id);
    return [
      for (final a in attachments) ...[
        a.relativePath,
        if (a.thumbRelativePath != null) a.thumbRelativePath!,
      ],
    ];
  }

  Future<int> _deleteFiles(
    List<String> relativePaths, {
    required Set<String> caseDirs,
  }) async {
    var deleted = 0;
    for (final path in relativePaths) {
      final file = File(_storage.absolute(path));
      if (!p.isWithin(_storage.root.path, file.path)) continue;
      try {
        if (await file.exists()) {
          await file.delete();
          deleted++;
        }
      } on FileSystemException {
        // ملف متبقٍ لا يؤثر على البيانات؛ يُحاول مرة أخرى عند الإفراغ التالي.
      }
    }
    for (final id in caseDirs) {
      final dir = Directory(p.join(_storage.root.path, 'attachments', id));
      try {
        if (await dir.exists()) await dir.delete(recursive: true);
      } on FileSystemException {
        // كما سبق.
      }
    }
    return deleted;
  }

  Future<void> _log(String action, CaseRecord row) async => _audit.log(
    action: action,
    entityType: auditEntity,
    entityId: row.id,
    details: {'display_code': row.displayCode},
    actor: await _settings.get(SettingKeys.userCode),
  );
}

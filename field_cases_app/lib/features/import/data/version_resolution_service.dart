import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/audit_logger.dart';
import '../../../core/files/attachment_storage.dart';
import '../../cases/data/case_search_index.dart';
import '../../cases/domain/case_enums.dart';
import '../../packages/data/case_package_reader.dart';
import '../../packages/data/case_snapshot_builder.dart';
import '../../packages/domain/case_diff.dart';
import '../../packages/domain/package_models.dart';
import '../../settings/data/settings_repository.dart';
import 'imported_case_writer.dart';

/// قرار المشرف في نسخة أحدث/مختلفة من حالة موجودة (docs/DESIGN.md البند 12).
enum VersionChoice {
  /// تبقى الحالية كما هي وتُتجاهل الواردة.
  keepCurrent,

  /// الواردة تحل محل الحالية، وتُحفظ الحالية في سجل الإصدارات.
  replace,

  /// تبقى الحالية، وتُحفظ الواردة في سجل الإصدارات للرجوع إليها.
  keepBoth,
}

/// حالة لها نسخة واردة تنتظر القرار.
class PendingVersion {
  const PendingVersion({
    required this.batchId,
    required this.caseId,
    required this.displayCode,
    required this.caseTypeLabel,
    required this.currentRevision,
    required this.incomingRevision,
    required this.classification,
    required this.batchTitle,
  });

  final String batchId;
  final String caseId;
  final String displayCode;
  final String caseTypeLabel;
  final int currentRevision;
  final int incomingRevision;
  final ImportClassification classification;
  final String batchTitle;
}

class VersionComparison {
  const VersionComparison({
    required this.current,
    required this.incoming,
    required this.fields,
    required this.attachments,
  });

  final PackagedCase current;
  final PackagedCase incoming;
  final List<FieldDiff> fields;
  final AttachmentDiff attachments;

  List<FieldDiff> get changedFields => fields.where((f) => f.changed).toList();
}

/// إصدار محفوظ في سجل الإصدارات.
class CaseVersionEntry {
  const CaseVersionEntry({
    required this.id,
    required this.revision,
    required this.source,
    required this.createdAt,
    required this.snapshot,
  });

  final String id;
  final int revision;
  final VersionSource source;
  final DateTime createdAt;
  final PackagedCase snapshot;

  String get sourceLabel => switch (source) {
    VersionSource.local => 'نسخة سابقة (قبل الاستبدال)',
    VersionSource.import => 'نسخة واردة محفوظة',
    VersionSource.supervisor => 'تعديل المشرف',
  };
}

class VersionResolutionException implements Exception {
  const VersionResolutionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VersionResolutionService {
  VersionResolutionService(
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

  static const String versionKept = 'version_kept_current';
  static const String versionReplaced = 'version_replaced';
  static const String versionArchived = 'version_kept_both';

  final AppDatabase _db;
  final AttachmentStorage _storage;
  final SettingsRepository _settings;
  final AuditLogger _audit;
  final CasePackageReader _reader;

  /// نفس مجلد [ImportService.workDirectory] حيث تُحفظ حزم الدفعات المعلقة.
  final Directory workDirectory;
  final DateTime Function() _clock;
  final Uuid _uuid;

  late final CaseSnapshotBuilder _snapshots = CaseSnapshotBuilder(
    _db,
    storage: _storage,
  );

  File packageFileFor(String batchId) =>
      File(p.join(workDirectory.path, '$batchId.${PackageFormat.extension}'));

  Stream<List<PendingVersion>> watchPending({String? batchId}) {
    final item = _db.importBatchItems;
    final type = _db.alias(_db.lookupItems, 'type');
    final query =
        _db.select(item).join([
            innerJoin(_db.cases, _db.cases.id.equalsExp(item.caseId)),
            innerJoin(type, type.id.equalsExp(_db.cases.caseTypeId)),
            innerJoin(
              _db.importBatches,
              _db.importBatches.id.equalsExp(item.batchId),
            ),
          ])
          ..where(
            item.decision.equalsValue(ImportDecision.pending) &
                (batchId == null
                    ? const Constant(true)
                    : item.batchId.equals(batchId)),
          )
          ..orderBy([OrderingTerm.desc(_db.importBatches.importedAt)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          () {
            final i = row.readTable(item);
            final c = row.readTable(_db.cases);
            final b = row.readTable(_db.importBatches);
            return PendingVersion(
              batchId: i.batchId,
              caseId: i.caseId,
              displayCode: c.displayCode,
              caseTypeLabel: row.readTable(type).label,
              currentRevision: c.revision,
              incomingRevision: i.incomingRevision,
              classification: i.classification,
              batchTitle: b.orgName ?? b.enteredBy ?? 'جهة غير محددة',
            );
          }(),
      ],
    );
  }

  Future<VersionComparison> compare(String batchId, String caseId) async {
    final incoming = await _incomingCase(batchId, caseId);
    final (current, _) = await _snapshots.build(caseId);
    final row = await (_db.select(
      _db.cases,
    )..where((c) => c.id.equals(caseId))).getSingle();
    final labels = {
      for (final f in await (_db.select(
        _db.caseTypeFields,
      )..where((f) => f.caseTypeId.equals(row.caseTypeId))).get())
        f.fieldKey: f.label,
    };
    return VersionComparison(
      current: current,
      incoming: incoming,
      fields: CaseDiff.fields(current, incoming, fieldLabels: labels),
      attachments: CaseDiff.attachments(current, incoming),
    );
  }

  Future<void> resolve(
    String batchId,
    String caseId,
    VersionChoice choice,
  ) async {
    final item =
        await (_db.select(_db.importBatchItems)..where(
              (i) => i.batchId.equals(batchId) & i.caseId.equals(caseId),
            ))
            .getSingleOrNull();
    if (item == null || item.decision != ImportDecision.pending) {
      throw const VersionResolutionException('لا يوجد قرار معلق لهذه الحالة');
    }
    final actor = await _settings.get(SettingKeys.userCode);

    switch (choice) {
      case VersionChoice.keepCurrent:
        await _db.transaction(() async {
          await _setDecision(batchId, caseId, ImportDecision.skip);
          await _audit.log(
            action: versionKept,
            entityType: 'case',
            entityId: caseId,
            details: {
              'batch_id': batchId,
              'incoming_revision': item.incomingRevision,
            },
            actor: actor,
          );
        });

      case VersionChoice.keepBoth:
        final incoming = await _incomingCase(batchId, caseId);
        await _db.transaction(() async {
          await _saveVersion(caseId, incoming, VersionSource.import);
          await _setDecision(batchId, caseId, ImportDecision.keepBoth);
          await _audit.log(
            action: versionArchived,
            entityType: 'case',
            entityId: caseId,
            details: {
              'batch_id': batchId,
              'incoming_revision': incoming.revision,
            },
            actor: actor,
          );
        });

      case VersionChoice.replace:
        await _replace(batchId, caseId, actor);
    }
    await _finishBatchIfDone(batchId);
  }

  Stream<List<CaseVersionEntry>> watchVersions(String caseId) {
    return (_db.select(_db.caseVersions)
          ..where((v) => v.caseId.equals(caseId))
          ..orderBy([(v) => OrderingTerm.desc(v.createdAt)]))
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              CaseVersionEntry(
                id: r.id,
                revision: r.revision,
                source: r.source,
                createdAt: r.createdAt.toLocal(),
                snapshot: PackagedCase.fromJson(
                  jsonDecode(r.snapshotJson) as Map<String, dynamic>,
                ),
              ),
          ],
        );
  }

  // ------------------------------------------------------------ داخلي

  Future<void> _replace(String batchId, String caseId, String? actor) async {
    final file = packageFileFor(batchId);
    final incoming = await _incomingCase(batchId, caseId);
    final (current, _) = await _snapshots.build(caseId);

    final existingIds = current.attachments
        .map((a) => a.attachmentUuid)
        .toSet();
    final deletedIds =
        (await (_db.select(_db.attachments)..where(
                  (a) => a.caseId.equals(caseId) & a.deletedAt.isNotNull(),
                ))
                .get())
            .map((a) => a.id)
            .toSet();
    final newAttachments = incoming.attachments
        .where(
          (a) =>
              !existingIds.contains(a.attachmentUuid) &&
              !deletedIds.contains(a.attachmentUuid),
        )
        .toList();

    final extractDir = Directory(
      p.join(workDirectory.path, '${batchId}_${_uuid.v4()}_extract'),
    );
    final moved = <String>[];
    try {
      final paths = <String, (String, String?)>{};
      if (newAttachments.isNotEmpty) {
        await _reader.extractAttachments(file, extractDir);
        for (final a in newAttachments) {
          final (relative, thumb) = await _storage.adoptImported(
            File(p.join(extractDir.path, a.path)),
            caseId: caseId,
            fileName: a.fileName,
          );
          moved.add(relative);
          if (thumb != null) moved.add(thumb);
          paths[a.attachmentUuid] = (relative, thumb);
        }
      }

      await _db.transaction(() async {
        final now = _clock().toUtc();
        await _saveVersion(caseId, current, VersionSource.local);
        await ImportedCaseWriter(_db).replaceCase(
          incoming,
          batchId: batchId,
          attachmentPaths: paths,
          now: now,
        );
        await CaseSearchIndex(_db).reindexCase(caseId);
        await _setDecision(batchId, caseId, ImportDecision.replace);
        await _audit.log(
          action: versionReplaced,
          entityType: 'case',
          entityId: caseId,
          details: {
            'batch_id': batchId,
            'from_revision': current.revision,
            'to_revision': incoming.revision,
            'added_attachments': newAttachments.length,
          },
          actor: actor,
        );
      });
    } catch (_) {
      await _storage.deleteRelative(moved);
      rethrow;
    } finally {
      if (await extractDir.exists()) await extractDir.delete(recursive: true);
    }
  }

  Future<PackagedCase> _incomingCase(String batchId, String caseId) async {
    final file = packageFileFor(batchId);
    if (!await file.exists()) {
      throw const VersionResolutionException(
        'حزمة الدفعة غير متوفرة على الجهاز؛ يمكن فقط الاحتفاظ بالنسخة الحالية',
      );
    }
    final inspection = await _reader.inspect(file);
    if (!inspection.isValid) {
      throw VersionResolutionException(inspection.errors.first);
    }
    final match = inspection.cases.where((c) => c.caseUuid == caseId);
    if (match.isEmpty) {
      throw const VersionResolutionException('الحالة غير موجودة في الحزمة');
    }
    return match.single;
  }

  Future<void> _saveVersion(
    String caseId,
    PackagedCase snapshot,
    VersionSource source,
  ) {
    return _db
        .into(_db.caseVersions)
        .insert(
          CaseVersionsCompanion.insert(
            id: _uuid.v4(),
            caseId: caseId,
            revision: snapshot.revision,
            contentHash: snapshot.contentHash,
            snapshotJson: jsonEncode(snapshot.toJson()),
            source: source,
            createdAt: _clock().toUtc(),
          ),
        );
  }

  Future<void> _setDecision(
    String batchId,
    String caseId,
    ImportDecision decision,
  ) {
    return (_db.update(_db.importBatchItems)
          ..where((i) => i.batchId.equals(batchId) & i.caseId.equals(caseId)))
        .write(ImportBatchItemsCompanion(decision: Value(decision)));
  }

  /// بعد آخر قرار: تُحذف الحزمة المحفوظة، وتكتمل الدفعة إن لم تبق حالات للمراجعة.
  Future<void> _finishBatchIfDone(String batchId) async {
    final pending =
        await (_db.select(_db.importBatchItems)..where(
              (i) =>
                  i.batchId.equals(batchId) &
                  i.decision.equalsValue(ImportDecision.pending),
            ))
            .get();
    if (pending.isNotEmpty) return;

    final file = packageFileFor(batchId);
    if (await file.exists()) await file.delete();

    final reviewing =
        await (_db.select(_db.cases)..where(
              (c) =>
                  c.sourceBatchId.equals(batchId) &
                  c.reviewState.isInValues([
                    ReviewState.incoming,
                    ReviewState.underReview,
                  ]),
            ))
            .get();
    if (reviewing.isEmpty) {
      await (_db.update(
        _db.importBatches,
      )..where((b) => b.id.equals(batchId))).write(
        const ImportBatchesCompanion(
          status: Value(ImportBatchStatus.completed),
        ),
      );
    }
  }
}

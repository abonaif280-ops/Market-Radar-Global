import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/audit_logger.dart';
import '../../cases/domain/case_enums.dart';
import '../../settings/data/settings_repository.dart';

/// دفعة واردة كما تظهر في "الدفعات الواردة".
class InboxBatch {
  const InboxBatch({
    required this.id,
    required this.orgName,
    required this.enteredBy,
    required this.packageCreatedAt,
    required this.importedAt,
    required this.caseCount,
    required this.imageCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  final String id;
  final String? orgName;
  final String? enteredBy;
  final DateTime packageCreatedAt;
  final DateTime importedAt;
  final int caseCount;
  final int imageCount;

  /// واردة أو تحت المراجعة.
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  String get title => orgName ?? enteredBy ?? 'جهة غير محددة';
}

/// إحصاء اليوم للوحة المشرف.
class TodayStats {
  const TodayStats({
    required this.total,
    required this.byOrg,
    required this.byType,
    required this.pendingReview,
  });

  final int total;
  final Map<String, int> byOrg;
  final Map<String, int> byType;
  final int pendingReview;
}

/// صندوق الوارد: المسار واردة ← تحت المراجعة ← معتمدة (أو مرفوضة).
class InboxRepository {
  InboxRepository(
    this._db, {
    required this._audit,
    required this._settings,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final AuditLogger _audit;
  final SettingsRepository _settings;
  final DateTime Function() _clock;

  static const _pending = [ReviewState.incoming, ReviewState.underReview];

  Stream<List<InboxBatch>> watchBatches() {
    final b = _db.importBatches;
    final c = _db.cases;
    Expression<int> countWhere(Expression<bool> condition) =>
        subqueryExpression<int>(
          _db.selectOnly(c)
            ..addColumns([c.id.count()])
            ..where(
              c.sourceBatchId.equalsExp(b.id) &
                  c.deletedAt.isNull() &
                  condition,
            ),
        );
    final pending = countWhere(c.reviewState.isInValues(_pending));
    final approved = countWhere(
      c.reviewState.equalsValue(ReviewState.approved),
    );
    final rejected = countWhere(
      c.reviewState.equalsValue(ReviewState.rejected),
    );

    final query = _db.select(b).addColumns([pending, approved, rejected])
      ..orderBy([OrderingTerm.desc(b.importedAt)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          () {
            final batch = row.readTable(b);
            return InboxBatch(
              id: batch.id,
              orgName: batch.orgName,
              enteredBy: batch.enteredBy,
              packageCreatedAt: batch.packageCreatedAt.toLocal(),
              importedAt: batch.importedAt.toLocal(),
              caseCount: batch.caseCount,
              imageCount: batch.imageCount,
              pendingCount: row.read(pending) ?? 0,
              approvedCount: row.read(approved) ?? 0,
              rejectedCount: row.read(rejected) ?? 0,
            );
          }(),
      ],
    );
  }

  Stream<int> watchPendingCount() {
    final count = _db.cases.id.count();
    return (_db.selectOnly(_db.cases)
          ..addColumns([count])
          ..where(
            _db.cases.deletedAt.isNull() &
                _db.cases.reviewState.isInValues(_pending),
          ))
        .map((r) => r.read(count) ?? 0)
        .watchSingle();
  }

  /// معرفات الحالات التي تنتظر القرار في دفعة ("اعتماد الكل").
  Future<List<String>> pendingCaseIds(String batchId) {
    return (_db.selectOnly(_db.cases)
          ..addColumns([_db.cases.id])
          ..where(
            _db.cases.sourceBatchId.equals(batchId) &
                _db.cases.deletedAt.isNull() &
                _db.cases.reviewState.isInValues(_pending),
          ))
        .map((r) => r.read(_db.cases.id)!)
        .get();
  }

  /// فتح الحالة للمراجعة ينقلها من "واردة" إلى "تحت المراجعة".
  Future<void> markUnderReview(String caseId) {
    return (_db.update(_db.cases)..where(
          (c) =>
              c.id.equals(caseId) &
              c.reviewState.equalsValue(ReviewState.incoming),
        ))
        .write(
          const CasesCompanion(reviewState: Value(ReviewState.underReview)),
        );
  }

  Future<int> approve(Iterable<String> caseIds) =>
      _decide(caseIds, ReviewState.approved, AuditActions.caseApproved);

  Future<int> reject(Iterable<String> caseIds) =>
      _decide(caseIds, ReviewState.rejected, AuditActions.caseRejected);

  Future<int> _decide(
    Iterable<String> caseIds,
    ReviewState state,
    String action,
  ) {
    final ids = caseIds.toList();
    if (ids.isEmpty) return Future.value(0);
    return _db.transaction(() async {
      final pendingRows =
          await (_db.select(_db.cases)..where(
                (c) => c.id.isIn(ids) & c.reviewState.isInValues(_pending),
              ))
              .get();
      if (pendingRows.isEmpty) return 0;
      final actor = await _settings.get(SettingKeys.userCode);
      await (_db.update(_db.cases)
            ..where((c) => c.id.isIn(pendingRows.map((r) => r.id))))
          .write(CasesCompanion(reviewState: Value(state)));
      for (final row in pendingRows) {
        await _audit.log(
          action: action,
          entityType: 'case',
          entityId: row.id,
          details: {
            'display_code': row.displayCode,
            'batch_id': row.sourceBatchId,
          },
          actor: actor,
        );
      }
      await _completeFinishedBatches(
        pendingRows.map((r) => r.sourceBatchId).whereType<String>().toSet(),
      );
      return pendingRows.length;
    });
  }

  Future<void> _completeFinishedBatches(Set<String> batchIds) async {
    for (final batchId in batchIds) {
      final remainingCases =
          await (_db.select(_db.cases)..where(
                (c) =>
                    c.sourceBatchId.equals(batchId) &
                    c.reviewState.isInValues(_pending),
              ))
              .get();
      final pendingDecisions =
          await (_db.select(_db.importBatchItems)..where(
                (i) =>
                    i.batchId.equals(batchId) &
                    i.decision.equalsValue(ImportDecision.pending),
              ))
              .get();
      if (remainingCases.isEmpty && pendingDecisions.isEmpty) {
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

  /// إجمالي حالات اليوم حسب الجهة ونوع الحالة (الحالات المحلية + المعتمدة والواردة).
  Future<TodayStats> todayStats() async {
    final now = _clock();
    final start = DateTime(now.year, now.month, now.day).toUtc();
    final end = DateTime(now.year, now.month, now.day + 1).toUtc();
    final c = _db.cases;
    final type = _db.alias(_db.lookupItems, 'type');
    final rows =
        await (_db.select(c).join([
              innerJoin(type, type.id.equalsExp(c.caseTypeId)),
              leftOuterJoin(
                _db.importBatches,
                _db.importBatches.id.equalsExp(c.sourceBatchId),
              ),
            ])..where(
              c.deletedAt.isNull() &
                  c.occurredAt.isBiggerOrEqualValue(start) &
                  c.occurredAt.isSmallerThanValue(end) &
                  (c.reviewState.isNull() |
                      c.reviewState.equalsValue(ReviewState.rejected).not()),
            ))
            .get();

    final ownOrg = await _settings.get(SettingKeys.orgName);
    final byOrg = <String, int>{};
    final byType = <String, int>{};
    var pending = 0;
    for (final row in rows) {
      final caseRow = row.readTable(c);
      final batch = row.readTableOrNull(_db.importBatches);
      final org = batch == null
          ? ((ownOrg?.trim().isNotEmpty ?? false) ? ownOrg!.trim() : 'حالاتي')
          : (batch.orgName ?? batch.enteredBy ?? 'جهة غير محددة');
      byOrg[org] = (byOrg[org] ?? 0) + 1;
      final label = row.readTable(type).label;
      byType[label] = (byType[label] ?? 0) + 1;
      if (_pending.contains(caseRow.reviewState)) pending++;
    }
    return TodayStats(
      total: rows.length,
      byOrg: byOrg,
      byType: byType,
      pendingReview: pending,
    );
  }
}

import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';

/// العمليات المسجلة في سجل العمليات (Audit Log).
abstract final class AuditActions {
  static const caseCreated = 'case_created';
  static const caseUpdated = 'case_updated';
  static const caseDeleted = 'case_deleted';
  static const caseRestored = 'case_restored';
  static const casePurged = 'case_purged';
  static const attachmentAdded = 'attachment_added';
  static const attachmentDeleted = 'attachment_deleted';
  static const packageExported = 'package_exported';
  static const batchImported = 'batch_imported';
  static const caseApproved = 'case_approved';
  static const caseRejected = 'case_rejected';
  static const roleChanged = 'role_changed';
  static const backupCreated = 'backup_created';
  static const backupRestored = 'backup_restored';
}

class AuditLogger {
  AuditLogger(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// يُستدعى داخل نفس Transaction الخاصة بالعملية حتى لا يُسجَّل ما لم يحدث.
  Future<void> log({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, Object?>? details,
    String? actor,
  }) {
    return _db
        .into(_db.auditLog)
        .insert(
          AuditLogCompanion.insert(
            at: _clock().toUtc(),
            action: action,
            entityType: entityType,
            entityId: Value(entityId),
            detailsJson: Value(details == null ? null : jsonEncode(details)),
            actor: Value(actor),
          ),
        );
  }

  Future<List<AuditLogData>> recent({int limit = 100, int offset = 0}) {
    return (_db.select(_db.auditLog)
          ..orderBy([(a) => OrderingTerm.desc(a.id)])
          ..limit(limit, offset: offset))
        .get();
  }
}

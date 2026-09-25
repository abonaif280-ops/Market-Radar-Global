import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/audit_logger.dart';
import '../../../core/files/attachment_storage.dart';
import '../../../core/ids/case_id_generator.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/case_content_hasher.dart';
import '../domain/case_enums.dart';
import '../domain/case_form_data.dart';
import '../domain/case_status_rules.dart';
import '../domain/case_views.dart';
import '../domain/form_attachment.dart';

/// محاولة تعديل حالة غير قابلة للتعديل أو غير موجودة.
class CaseNotEditableException implements Exception {
  const CaseNotEditableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CasesRepository {
  CasesRepository(
    this._db, {
    required this._settings,
    required this._audit,
    required this._storage,
    CaseIdGenerator? idGenerator,
    DateTime Function()? clock,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid(),
       _ids = idGenerator ?? CaseIdGenerator(clock: clock),
       _clock = clock ?? DateTime.now;

  static const String auditEntity = 'case';

  final AppDatabase _db;
  final SettingsRepository _settings;
  final AuditLogger _audit;
  final AttachmentStorage _storage;
  final CaseIdGenerator _ids;
  final Uuid _uuid;
  final DateTime Function() _clock;

  // ---------------------------------------------------------------- الكتابة

  /// ينشئ حالة جديدة ويعيد معرفها (UUID).
  ///
  /// الصور الجديدة تُنقل من منطقة الانتظار إلى مجلد الحالة؛ وإذا فشل الحفظ
  /// تُعاد إليها حتى لا تبقى ملفات بلا سجل ولا سجل بلا ملفات.
  Future<String> createCase(CaseFormData data, {required CaseStatus status}) {
    final caseTypeId = data.caseTypeId;
    if (caseTypeId == null) {
      throw ArgumentError('caseTypeId is required');
    }
    return _withFileRollback(
      (committed) => _db.transaction(() async {
        final identity = _ids.next();
        final serialNo = await _settings.nextSerialNo();
        final deviceId = await _settings.deviceId();
        final enteredBy = await _settings.get(SettingKeys.userCode);
        final orgCode = await _settings.get(SettingKeys.orgCode);
        final now = _clock().toUtc();

        await _db
            .into(_db.cases)
            .insert(
              _contentCompanion(data).copyWith(
                id: Value(identity.uuid),
                displayCode: Value(identity.displayCode),
                serialNo: Value(serialNo),
                caseTypeId: Value(caseTypeId),
                originDeviceId: Value(deviceId),
                enteredBy: Value(_nullIfEmpty(enteredBy)),
                orgCode: Value(_nullIfEmpty(orgCode)),
                revision: const Value(1),
                contentHash: Value(CaseContentHasher.hash(data)),
                status: Value(status),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
        await _replaceParties(identity.uuid, data.partyIds);
        await _syncAttachments(
          caseId: identity.uuid,
          displayCode: identity.displayCode,
          attachments: data.attachments,
          committed: committed,
          actor: enteredBy,
        );
        await _audit.log(
          action: AuditActions.caseCreated,
          entityType: auditEntity,
          entityId: identity.uuid,
          details: {
            'display_code': identity.displayCode,
            'status': status.name,
            'attachments': data.attachments.length,
          },
          actor: enteredBy,
        );
        return identity.uuid;
      }),
    );
  }

  /// يحفظ التعديلات. يرفع revision فقط إذا تغيّر المحتوى فعلًا، وبذلك تتحول
  /// الحالة المصدّرة تلقائيًا إلى "تم التعديل بعد التصدير".
  ///
  /// يعيد true إذا تغيّر المحتوى.
  Future<bool> updateCase(
    String id,
    CaseFormData data, {
    required CaseStatus status,
  }) {
    final caseTypeId = data.caseTypeId;
    if (caseTypeId == null) {
      throw ArgumentError('caseTypeId is required');
    }
    return _withFileRollback(
      (committed) => _db.transaction(() async {
        final existing = await _activeCase(id);
        if (existing.reviewState != null) {
          throw const CaseNotEditableException(
            'الحالة المستوردة لا تُعدَّل، يمكن اعتمادها أو رفضها فقط',
          );
        }
        final newHash = CaseContentHasher.hash(data);
        final contentChanged = newHash != existing.contentHash;
        final attachmentsChanged =
            data.attachments.any((a) => a.isNew) ||
            await _hasRemovedAttachments(id, data.attachments);
        if (!contentChanged &&
            !attachmentsChanged &&
            status == existing.status) {
          return false;
        }

        final newRevision = contentChanged
            ? existing.revision + 1
            : existing.revision;
        await (_db.update(_db.cases)..where((c) => c.id.equals(id))).write(
          _contentCompanion(data).copyWith(
            caseTypeId: Value(caseTypeId),
            revision: Value(newRevision),
            contentHash: Value(newHash),
            status: Value(status),
            updatedAt: Value(_clock().toUtc()),
          ),
        );
        final actor = await _settings.get(SettingKeys.userCode);
        await _replaceParties(id, data.partyIds);
        await _syncAttachments(
          caseId: id,
          displayCode: existing.displayCode,
          attachments: data.attachments,
          committed: committed,
          actor: actor,
        );
        await _audit.log(
          action: AuditActions.caseUpdated,
          entityType: auditEntity,
          entityId: id,
          details: {
            'revision': newRevision,
            'content_changed': contentChanged,
            'status': status.name,
          },
          actor: actor,
        );
        return contentChanged;
      }),
    );
  }

  /// تغيير مرحلة الحالة فقط (مثل: جاهزة للإرسال) دون رفع revision.
  Future<void> setStatus(String id, CaseStatus status) async {
    final data = await loadForm(id);
    await updateCase(id, data, status: status);
  }

  // ---------------------------------------------------------------- القراءة

  /// يحمّل الحالة في نموذج قابل للتعديل.
  Future<CaseFormData> loadForm(String id) async {
    final row = await _activeCase(id);
    final parties = await (_db.select(
      _db.caseParties,
    )..where((p) => p.caseId.equals(id))).get();
    return CaseFormData(
      caseTypeId: row.caseTypeId,
      occurredAt: row.occurredAt.toLocal(),
      governorateId: row.governorateId,
      centerId: row.centerId,
      locationText: row.locationText ?? '',
      reportSourceId: row.reportSourceId,
      locationDescription: row.locationDescription ?? '',
      latitude: row.latitude,
      longitude: row.longitude,
      caseInfo: row.caseInfo ?? '',
      actionTaken: row.actionTaken ?? '',
      hasInjuries: row.hasInjuries,
      injuriesCount: row.injuriesCount,
      hasDeaths: row.hasDeaths,
      deathsCount: row.deathsCount,
      hasDamage: row.hasDamage,
      damageDescription: row.damageDescription ?? '',
      notes: row.notes ?? '',
      extraFields: Map<String, Object?>.from(
        jsonDecode(row.extraFieldsJson) as Map,
      ),
      partyIds: parties.map((p) => p.partyId).toSet(),
      attachments: await _activeAttachments(id),
      generatedText: row.generatedText,
      finalText: row.finalText,
      isTextEdited: row.isTextEdited,
    );
  }

  Future<CaseRecord?> byId(String id) {
    return (_db.select(
      _db.cases,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// أحدث الحالات غير المحذوفة (القائمة الكاملة بالتصفية والتحميل التدريجي في المرحلة 6).
  Stream<List<CaseListItem>> watchRecent({int limit = 100}) {
    final type = _db.alias(_db.lookupItems, 'type');
    final gov = _db.alias(_db.lookupItems, 'gov');
    final countAlias = _db.alias(_db.attachments, 'att');
    final imageCount = subqueryExpression<int>(
      _db.selectOnly(countAlias)
        ..addColumns([countAlias.id.count()])
        ..where(
          countAlias.caseId.equalsExp(_db.cases.id) &
              countAlias.deletedAt.isNull(),
        ),
    );
    final query =
        _db.select(_db.cases).join([
            innerJoin(type, type.id.equalsExp(_db.cases.caseTypeId)),
            leftOuterJoin(gov, gov.id.equalsExp(_db.cases.governorateId)),
          ])
          ..addColumns([imageCount])
          ..where(_db.cases.deletedAt.isNull())
          ..orderBy([OrderingTerm.desc(_db.cases.occurredAt)])
          ..limit(limit);

    return query.watch().map(
      (rows) => rows.map((row) {
        final c = row.readTable(_db.cases);
        final governorate = row.readTableOrNull(gov);
        return CaseListItem(
          id: c.id,
          displayCode: c.displayCode,
          serialNo: c.serialNo,
          occurredAt: c.occurredAt.toLocal(),
          caseTypeLabel: row.readTable(type).label,
          placeLabel: governorate?.label ?? _nullIfEmpty(c.locationText),
          imageCount: row.read(imageCount) ?? 0,
          displayStatus: CaseStatusRules.displayStatus(
            status: c.status,
            revision: c.revision,
            lastExportedRevision: c.lastExportedRevision,
            reviewState: c.reviewState,
          ),
        );
      }).toList(),
    );
  }

  /// تفاصيل حالة واحدة، تتحدث تلقائيًا عند أي تعديل.
  Stream<CaseDetails?> watchDetails(String id) {
    final caseQuery = _db.select(_db.cases)..where((c) => c.id.equals(id));
    return caseQuery.watchSingleOrNull().asyncMap((row) async {
      if (row == null || row.deletedAt != null) return null;
      return _toDetails(row);
    });
  }

  /// عدد الحالات غير المحذوفة التي وقعت اليوم (بالتوقيت المحلي).
  Stream<int> watchTodayCount() {
    final now = _clock();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
    final endOfDay = DateTime(now.year, now.month, now.day + 1).toUtc();
    final count = _db.cases.id.count();
    final query = _db.selectOnly(_db.cases)
      ..addColumns([count])
      ..where(
        _db.cases.deletedAt.isNull() &
            _db.cases.occurredAt.isBiggerOrEqualValue(startOfDay) &
            _db.cases.occurredAt.isSmallerThanValue(endOfDay),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  // ---------------------------------------------------------------- داخلي

  Future<T> _withFileRollback<T>(
    Future<T> Function(List<CommittedAttachment> committed) action,
  ) async {
    final committed = <CommittedAttachment>[];
    try {
      return await action(committed);
    } catch (_) {
      await _storage.rollback(committed);
      rethrow;
    }
  }

  /// يطابق صور النموذج مع المحفوظ: المحذوفة تُحذف حذفًا مرنًا (Soft Delete)،
  /// والجديدة تُنقل لمجلد الحالة بأسماء متسلسلة لا يُعاد استخدامها.
  Future<void> _syncAttachments({
    required String caseId,
    required String displayCode,
    required List<FormAttachment> attachments,
    required List<CommittedAttachment> committed,
    required String? actor,
  }) async {
    final now = _clock().toUtc();
    final keptIds = attachments
        .where((a) => !a.isNew)
        .map((a) => a.id!)
        .toSet();
    final existing = await (_db.select(
      _db.attachments,
    )..where((a) => a.caseId.equals(caseId) & a.deletedAt.isNull())).get();
    for (final row in existing.where((r) => !keptIds.contains(r.id))) {
      await (_db.update(_db.attachments)..where((a) => a.id.equals(row.id)))
          .write(AttachmentsCompanion(deletedAt: Value(now)));
      await _audit.log(
        action: AuditActions.attachmentDeleted,
        entityType: 'attachment',
        entityId: row.id,
        details: {'case_id': caseId, 'file_name': row.fileName},
        actor: actor,
      );
    }

    // الترقيم يشمل المحذوف حتى لا يتكرر اسم ملف سبق استخدامه.
    final maxSeq = _db.attachments.seq.max();
    final lastSeq =
        await (_db.selectOnly(_db.attachments)
              ..addColumns([maxSeq])
              ..where(_db.attachments.caseId.equals(caseId)))
            .map((r) => r.read(maxSeq))
            .getSingle();
    var nextSeq = (lastSeq ?? 0) + 1;

    for (final attachment in attachments.where((a) => a.isNew)) {
      final extension = attachment.filePath.split('.').last;
      final fileName = CaseIdGenerator.attachmentFileName(
        displayCode,
        nextSeq,
        extension,
      );
      final result = await _storage.commit(
        attachment,
        caseId: caseId,
        fileName: fileName,
      );
      committed.add(result);
      final attachmentId = _uuid.v4();
      await _db
          .into(_db.attachments)
          .insert(
            AttachmentsCompanion.insert(
              id: attachmentId,
              caseId: caseId,
              seq: nextSeq,
              kind: AttachmentKind.image,
              fileName: fileName,
              relativePath: result.relativePath,
              thumbRelativePath: Value(result.thumbRelativePath),
              mimeType: attachment.mimeType,
              sizeBytes: attachment.sizeBytes,
              sha256: attachment.sha256,
              width: Value(attachment.width),
              height: Value(attachment.height),
              createdAt: now,
            ),
          );
      await _audit.log(
        action: AuditActions.attachmentAdded,
        entityType: 'attachment',
        entityId: attachmentId,
        details: {'case_id': caseId, 'file_name': fileName},
        actor: actor,
      );
      nextSeq++;
    }
  }

  Future<bool> _hasRemovedAttachments(
    String caseId,
    List<FormAttachment> attachments,
  ) async {
    final keptIds = attachments
        .where((a) => !a.isNew)
        .map((a) => a.id!)
        .toSet();
    final existing = await _activeAttachments(caseId);
    return existing.any((a) => !keptIds.contains(a.id));
  }

  Future<List<FormAttachment>> _activeAttachments(String caseId) async {
    final rows =
        await (_db.select(_db.attachments)
              ..where((a) => a.caseId.equals(caseId) & a.deletedAt.isNull())
              ..orderBy([(a) => OrderingTerm.asc(a.seq)]))
            .get();
    return [
      for (final r in rows)
        FormAttachment(
          id: r.id,
          filePath: _storage.absolute(r.relativePath),
          thumbPath: r.thumbRelativePath == null
              ? null
              : _storage.absolute(r.thumbRelativePath!),
          sha256: r.sha256,
          sizeBytes: r.sizeBytes,
          mimeType: r.mimeType,
          width: r.width,
          height: r.height,
          fileName: r.fileName,
        ),
    ];
  }

  Future<CaseRecord> _activeCase(String id) async {
    final row = await byId(id);
    if (row == null || row.deletedAt != null) {
      throw CaseNotEditableException('الحالة غير موجودة: $id');
    }
    return row;
  }

  CasesCompanion _contentCompanion(CaseFormData d) {
    return CasesCompanion(
      occurredAt: Value(d.occurredAt.toUtc()),
      governorateId: Value(d.governorateId),
      centerId: Value(d.centerId),
      locationText: Value(_nullIfEmpty(d.locationText)),
      reportSourceId: Value(d.reportSourceId),
      locationDescription: Value(_nullIfEmpty(d.locationDescription)),
      latitude: Value(d.latitude),
      longitude: Value(d.longitude),
      caseInfo: Value(_nullIfEmpty(d.caseInfo)),
      actionTaken: Value(_nullIfEmpty(d.actionTaken)),
      hasInjuries: Value(d.hasInjuries),
      injuriesCount: Value(d.hasInjuries ? d.injuriesCount : 0),
      hasDeaths: Value(d.hasDeaths),
      deathsCount: Value(d.hasDeaths ? d.deathsCount : 0),
      hasDamage: Value(d.hasDamage),
      damageDescription: Value(
        d.hasDamage ? _nullIfEmpty(d.damageDescription) : null,
      ),
      notes: Value(_nullIfEmpty(d.notes)),
      extraFieldsJson: Value(jsonEncode(d.extraFields)),
      generatedText: Value(d.generatedText),
      finalText: Value(_nullIfEmpty(d.finalText)),
      isTextEdited: Value(d.isTextEdited),
    );
  }

  Future<void> _replaceParties(String caseId, Set<String> partyIds) async {
    await (_db.delete(
      _db.caseParties,
    )..where((p) => p.caseId.equals(caseId))).go();
    for (final partyId in partyIds) {
      await _db
          .into(_db.caseParties)
          .insert(
            CasePartiesCompanion.insert(caseId: caseId, partyId: partyId),
          );
    }
  }

  Future<CaseDetails> _toDetails(CaseRecord row) async {
    final ids = {
      row.caseTypeId,
      ?row.governorateId,
      ?row.centerId,
      ?row.reportSourceId,
    };
    final lookups = await (_db.select(
      _db.lookupItems,
    )..where((l) => l.id.isIn(ids))).get();
    String? label(String? id) =>
        id == null ? null : lookups.where((l) => l.id == id).firstOrNull?.label;

    final partyRows =
        await (_db.select(_db.caseParties).join([
                innerJoin(
                  _db.lookupItems,
                  _db.lookupItems.id.equalsExp(_db.caseParties.partyId),
                ),
              ])
              ..where(_db.caseParties.caseId.equals(row.id))
              ..orderBy([OrderingTerm.asc(_db.lookupItems.sortOrder)]))
            .get();

    final fieldDefs =
        await (_db.select(_db.caseTypeFields)
              ..where((f) => f.caseTypeId.equals(row.caseTypeId))
              ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]))
            .get();
    final rawExtra = jsonDecode(row.extraFieldsJson) as Map<String, dynamic>;
    final extra = <String, Object?>{
      for (final def in fieldDefs)
        if (rawExtra.containsKey(def.fieldKey))
          def.label: rawExtra[def.fieldKey],
    };

    return CaseDetails(
      id: row.id,
      displayCode: row.displayCode,
      serialNo: row.serialNo,
      status: row.status,
      revision: row.revision,
      lastExportedRevision: row.lastExportedRevision,
      reviewState: row.reviewState,
      caseTypeLabel: label(row.caseTypeId) ?? '—',
      occurredAt: row.occurredAt.toLocal(),
      governorateLabel: label(row.governorateId),
      centerLabel: label(row.centerId),
      locationText: row.locationText,
      reportSourceLabel: label(row.reportSourceId),
      locationDescription: row.locationDescription,
      latitude: row.latitude,
      longitude: row.longitude,
      caseInfo: row.caseInfo,
      actionTaken: row.actionTaken,
      hasInjuries: row.hasInjuries,
      injuriesCount: row.injuriesCount,
      hasDeaths: row.hasDeaths,
      deathsCount: row.deathsCount,
      hasDamage: row.hasDamage,
      damageDescription: row.damageDescription,
      notes: row.notes,
      extraFields: extra,
      partyLabels: partyRows
          .map((r) => r.readTable(_db.lookupItems).label)
          .toList(),
      finalText: row.finalText,
      attachments: await _activeAttachments(row.id),
      enteredBy: row.enteredBy,
      createdAt: row.createdAt.toLocal(),
      updatedAt: row.updatedAt.toLocal(),
    );
  }

  static String? _nullIfEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

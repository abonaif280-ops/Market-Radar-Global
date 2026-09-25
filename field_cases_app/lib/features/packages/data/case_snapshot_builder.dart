import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/files/attachment_storage.dart';
import '../domain/package_models.dart';

/// يحوّل حالة محلية إلى صيغتها المنقولة ([PackagedCase]).
///
/// تستخدمه: حزمة التصدير، ولقطات سجل الإصدارات، ومقارنة النسخ عند الاستيراد.
class CaseSnapshotBuilder {
  CaseSnapshotBuilder(this._db, {required this._storage});

  final AppDatabase _db;
  final AttachmentStorage _storage;

  /// الحالة كما تُكتب في cases.json، مع خريطة (مسار داخل الحزمة ← مسار الملف).
  Future<(PackagedCase, Map<String, String>)> build(String id) async {
    final row = await (_db.select(
      _db.cases,
    )..where((c) => c.id.equals(id))).getSingle();

    final lookupIds = {
      row.caseTypeId,
      ?row.governorateId,
      ?row.centerId,
      ?row.reportSourceId,
    };
    final lookups = {
      for (final l in await (_db.select(
        _db.lookupItems,
      )..where((l) => l.id.isIn(lookupIds))).get())
        l.id: l,
    };
    PackagedLookup? lookup(String? lookupId) {
      final item = lookupId == null ? null : lookups[lookupId];
      return item == null
          ? null
          : PackagedLookup(code: item.code, label: item.label);
    }

    final parties =
        await (_db.select(_db.caseParties).join([
                innerJoin(
                  _db.lookupItems,
                  _db.lookupItems.id.equalsExp(_db.caseParties.partyId),
                ),
              ])
              ..where(_db.caseParties.caseId.equals(id))
              ..orderBy([OrderingTerm.asc(_db.lookupItems.sortOrder)]))
            .map((r) => r.readTable(_db.lookupItems))
            .get();

    final attachmentRows =
        await (_db.select(_db.attachments)
              ..where((a) => a.caseId.equals(id) & a.deletedAt.isNull())
              ..orderBy([(a) => OrderingTerm.asc(a.seq)]))
            .get();
    final files = <String, String>{};
    final attachments = [
      for (final a in attachmentRows)
        PackagedAttachment(
          attachmentUuid: a.id,
          seq: a.seq,
          kind: a.kind.name,
          fileName: a.fileName,
          path: '${PackageFormat.attachmentsDir}/$id/${a.fileName}',
          mimeType: a.mimeType,
          size: a.sizeBytes,
          sha256: a.sha256,
          width: a.width,
          height: a.height,
        ),
    ];
    for (var i = 0; i < attachmentRows.length; i++) {
      files[attachments[i].path] = _storage.absolute(
        attachmentRows[i].relativePath,
      );
    }

    final packaged = PackagedCase(
      caseUuid: row.id,
      displayCode: row.displayCode,
      serialNo: row.serialNo,
      revision: row.revision,
      contentHash: row.contentHash ?? '',
      status: row.status.name,
      caseType:
          lookup(row.caseTypeId) ??
          PackagedLookup(code: row.caseTypeId, label: row.caseTypeId),
      occurredAt: row.occurredAt,
      governorate: lookup(row.governorateId),
      center: lookup(row.centerId),
      locationText: row.locationText,
      reportSource: lookup(row.reportSourceId),
      locationDescription: row.locationDescription,
      latitude: row.latitude,
      longitude: row.longitude,
      caseInfo: row.caseInfo,
      actionTaken: row.actionTaken,
      parties: [
        for (final party in parties)
          PackagedLookup(code: party.code, label: party.label),
      ],
      hasInjuries: row.hasInjuries,
      injuriesCount: row.injuriesCount,
      hasDeaths: row.hasDeaths,
      deathsCount: row.deathsCount,
      hasDamage: row.hasDamage,
      damageDescription: row.damageDescription,
      extraFields: Map<String, Object?>.from(
        jsonDecode(row.extraFieldsJson) as Map,
      ),
      notes: row.notes,
      finalText: row.finalText,
      isTextEdited: row.isTextEdited,
      enteredBy: row.enteredBy,
      orgCode: row.orgCode,
      originDeviceId: row.originDeviceId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      attachments: attachments,
    );
    return (packaged, files);
  }
}

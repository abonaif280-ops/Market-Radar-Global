import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/seed_data.dart';
import '../../cases/domain/case_enums.dart';
import '../../packages/domain/package_models.dart';

/// يكتب حالة واردة ([PackagedCase]) في قاعدة المشرف: إدراج حالة جديدة، أو
/// استبدال نسخة موجودة بنسخة أحدث. يُستدعى داخل Transaction من المستدعي.
class ImportedCaseWriter {
  ImportedCaseWriter(this._db);

  final AppDatabase _db;

  /// [attachmentPaths]: معرف المرفق ← (المسار النسبي، مسار المصغرة).
  Future<void> insertCase(
    PackagedCase c, {
    required String batchId,
    required Map<String, (String, String?)> attachmentPaths,
    required DateTime now,
  }) async {
    final content = await _contentFor(c, batchId);
    await _db
        .into(_db.cases)
        .insert(
          content.copyWith(
            id: Value(c.caseUuid),
            displayCode: Value(c.displayCode),
            serialNo: Value(c.serialNo),
            originDeviceId: Value(c.originDeviceId),
            createdAt: Value(c.createdAt.toUtc()),
          ),
        );
    await _writeParties(c);
    for (final a in c.attachments) {
      await _insertAttachment(
        c.caseUuid,
        a,
        attachmentPaths[a.attachmentUuid]!,
        now,
      );
    }
  }

  /// يستبدل محتوى الحالة الموجودة بالنسخة الواردة. الصور غير الموجودة في
  /// النسخة الواردة تُحذف حذفًا مرنًا، والجديدة تُضاف من [attachmentPaths].
  Future<void> replaceCase(
    PackagedCase c, {
    required String batchId,
    required Map<String, (String, String?)> attachmentPaths,
    required DateTime now,
  }) async {
    final content = await _contentFor(c, batchId);
    await (_db.update(
      _db.cases,
    )..where((row) => row.id.equals(c.caseUuid))).write(content);

    await (_db.delete(
      _db.caseParties,
    )..where((p) => p.caseId.equals(c.caseUuid))).go();
    await _writeParties(c);

    final incomingIds = c.attachments.map((a) => a.attachmentUuid).toSet();
    final local = await (_db.select(
      _db.attachments,
    )..where((a) => a.caseId.equals(c.caseUuid))).get();
    for (final row in local) {
      if (!incomingIds.contains(row.id) && row.deletedAt == null) {
        await (_db.update(_db.attachments)..where((a) => a.id.equals(row.id)))
            .write(AttachmentsCompanion(deletedAt: Value(now)));
      }
    }
    final localIds = local.map((r) => r.id).toSet();
    final usedSeqs = local.map((r) => r.seq).toSet();
    var nextSeq = usedSeqs.isEmpty
        ? 1
        : usedSeqs.reduce((a, b) => a > b ? a : b) + 1;
    for (final a in c.attachments) {
      if (localIds.contains(a.attachmentUuid)) {
        // مرفق كان محذوفًا مرنًا وأعادته النسخة الواردة.
        await (_db.update(_db.attachments)
              ..where((x) => x.id.equals(a.attachmentUuid)))
            .write(const AttachmentsCompanion(deletedAt: Value(null)));
        continue;
      }
      // الرقم الوارد قد يكون مستخدمًا محليًا (قيد فريد على case_id + seq).
      final seq = usedSeqs.contains(a.seq) ? nextSeq++ : a.seq;
      usedSeqs.add(seq);
      await _insertAttachment(
        c.caseUuid,
        a,
        attachmentPaths[a.attachmentUuid]!,
        now,
        seq: seq,
      );
    }
  }

  /// يربط عنصر القائمة الوارد بالمحلي بالرمز؛ وإن لم يوجد يُضاف باسمه
  /// (قوائم الأجهزة قد تختلف) حتى لا تضيع المعلومة.
  Future<String?> lookupFor(String listKey, PackagedLookup? item) async {
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

  // ------------------------------------------------------------ داخلي

  /// الحقول المشتركة بين الإدراج والاستبدال. الحالة تدخل (أو تعود) إلى
  /// "واردة" لأن محتواها تغيّر ويحتاج مراجعة المشرف.
  Future<CasesCompanion> _contentFor(PackagedCase c, String batchId) async {
    return CasesCompanion(
      caseTypeId: Value((await lookupFor(LookupKeys.caseType, c.caseType))!),
      occurredAt: Value(c.occurredAt.toUtc()),
      governorateId: Value(
        await lookupFor(LookupKeys.governorate, c.governorate),
      ),
      centerId: Value(await lookupFor(LookupKeys.center, c.center)),
      locationText: Value(c.locationText),
      reportSourceId: Value(
        await lookupFor(LookupKeys.reportSource, c.reportSource),
      ),
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
      revision: Value(c.revision),
      contentHash: Value(c.contentHash),
      status: Value(
        CaseStatus.values.firstWhere(
          (s) => s.name == c.status,
          orElse: () => CaseStatus.completed,
        ),
      ),
      reviewState: const Value(ReviewState.incoming),
      sourceBatchId: Value(batchId),
      updatedAt: Value(c.updatedAt.toUtc()),
    );
  }

  Future<void> _writeParties(PackagedCase c) async {
    for (final party in c.parties) {
      final partyId = await lookupFor(LookupKeys.party, party);
      await _db
          .into(_db.caseParties)
          .insert(
            CasePartiesCompanion.insert(caseId: c.caseUuid, partyId: partyId!),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  Future<void> _insertAttachment(
    String caseId,
    PackagedAttachment a,
    (String, String?) paths,
    DateTime now, {
    int? seq,
  }) {
    final (relative, thumb) = paths;
    return _db
        .into(_db.attachments)
        .insert(
          AttachmentsCompanion.insert(
            id: a.attachmentUuid,
            caseId: caseId,
            seq: seq ?? a.seq,
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

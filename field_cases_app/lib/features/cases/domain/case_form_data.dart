import 'form_attachment.dart';

/// بيانات نموذج الحالة أثناء الإدخال أو التعديل (قبل الحفظ في القاعدة).
///
/// التاريخ هنا بالتوقيت المحلي؛ يُحوَّل إلى UTC عند الحفظ فقط.
class CaseFormData {
  CaseFormData({
    this.caseTypeId,
    DateTime? occurredAt,
    this.governorateId,
    this.centerId,
    this.locationText = '',
    this.reportSourceId,
    this.locationDescription = '',
    this.latitude,
    this.longitude,
    this.caseInfo = '',
    this.actionTaken = '',
    this.hasInjuries = false,
    this.injuriesCount = 0,
    this.hasDeaths = false,
    this.deathsCount = 0,
    this.hasDamage = false,
    this.damageDescription = '',
    this.notes = '',
    Map<String, Object?>? extraFields,
    Set<String>? partyIds,
    List<FormAttachment>? attachments,
    this.generatedText,
    this.finalText,
    this.isTextEdited = false,
  }) : occurredAt = occurredAt ?? DateTime.now(),
       extraFields = extraFields ?? <String, Object?>{},
       partyIds = partyIds ?? <String>{},
       attachments = attachments ?? <FormAttachment>[];

  String? caseTypeId;
  DateTime occurredAt;
  String? governorateId;
  String? centerId;
  String locationText;
  String? reportSourceId;
  String locationDescription;
  double? latitude;
  double? longitude;
  String caseInfo;
  String actionTaken;
  bool hasInjuries;
  int injuriesCount;
  bool hasDeaths;
  int deathsCount;
  bool hasDamage;
  String damageDescription;
  String notes;

  /// قيم الحقول الخاصة بنوع الحالة: `field_key -> قيمة`.
  final Map<String, Object?> extraFields;

  /// معرفات الجهات التي تمت مباشرتها.
  final Set<String> partyIds;

  /// الصور بترتيب العرض: المحفوظة مسبقًا + الجديدة في منطقة الانتظار.
  final List<FormAttachment> attachments;

  String? generatedText;
  String? finalText;
  bool isTextEdited;

  /// عند تغيير نوع الحالة تُحذف قيم الحقول الخاصة بالنوع السابق.
  void changeCaseType(String caseTypeId) {
    if (this.caseTypeId == caseTypeId) return;
    this.caseTypeId = caseTypeId;
    extraFields.clear();
  }

  /// عند تغيير المحافظة يُلغى المركز إن لم يكن تابعًا لها (يتحقق منه المستدعي).
  void changeGovernorate(String? governorateId) {
    if (this.governorateId == governorateId) return;
    this.governorateId = governorateId;
    centerId = null;
  }

  CaseFormData copy() => CaseFormData(
    caseTypeId: caseTypeId,
    occurredAt: occurredAt,
    governorateId: governorateId,
    centerId: centerId,
    locationText: locationText,
    reportSourceId: reportSourceId,
    locationDescription: locationDescription,
    latitude: latitude,
    longitude: longitude,
    caseInfo: caseInfo,
    actionTaken: actionTaken,
    hasInjuries: hasInjuries,
    injuriesCount: injuriesCount,
    hasDeaths: hasDeaths,
    deathsCount: deathsCount,
    hasDamage: hasDamage,
    damageDescription: damageDescription,
    notes: notes,
    extraFields: Map.of(extraFields),
    partyIds: Set.of(partyIds),
    attachments: List.of(attachments),
    generatedText: generatedText,
    finalText: finalText,
    isTextEdited: isTextEdited,
  );
}

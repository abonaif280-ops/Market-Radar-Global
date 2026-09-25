import 'case_enums.dart';
import 'case_status_rules.dart';
import 'form_attachment.dart';

/// سطر في قائمة الحالات (بيانات خفيفة للعرض السريع).
class CaseListItem {
  const CaseListItem({
    required this.id,
    required this.displayCode,
    required this.serialNo,
    required this.occurredAt,
    required this.caseTypeLabel,
    required this.placeLabel,
    required this.displayStatus,
    this.imageCount = 0,
  });

  final String id;
  final String displayCode;
  final int serialNo;
  final DateTime occurredAt;
  final String caseTypeLabel;

  /// المحافظة، أو الموقع المكتوب إن لم تُحدد.
  final String? placeLabel;
  final DisplayStatus displayStatus;
  final int imageCount;
}

/// تفاصيل الحالة للعرض مع أسماء عناصر القوائم.
class CaseDetails {
  const CaseDetails({
    required this.id,
    required this.displayCode,
    required this.serialNo,
    required this.status,
    required this.revision,
    required this.lastExportedRevision,
    required this.reviewState,
    required this.caseTypeLabel,
    required this.occurredAt,
    required this.governorateLabel,
    required this.centerLabel,
    required this.locationText,
    required this.reportSourceLabel,
    required this.locationDescription,
    required this.latitude,
    required this.longitude,
    required this.caseInfo,
    required this.actionTaken,
    required this.hasInjuries,
    required this.injuriesCount,
    required this.hasDeaths,
    required this.deathsCount,
    required this.hasDamage,
    required this.damageDescription,
    required this.notes,
    required this.extraFields,
    required this.partyLabels,
    required this.finalText,
    this.attachments = const [],
    required this.enteredBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayCode;
  final int serialNo;
  final CaseStatus status;
  final int revision;
  final int? lastExportedRevision;
  final ReviewState? reviewState;
  final String caseTypeLabel;
  final DateTime occurredAt;
  final String? governorateLabel;
  final String? centerLabel;
  final String? locationText;
  final String? reportSourceLabel;
  final String? locationDescription;
  final double? latitude;
  final double? longitude;
  final String? caseInfo;
  final String? actionTaken;
  final bool hasInjuries;
  final int injuriesCount;
  final bool hasDeaths;
  final int deathsCount;
  final bool hasDamage;
  final String? damageDescription;
  final String? notes;

  /// قيم الحقول الخاصة بالنوع مع عناوينها: `عنوان الحقل -> القيمة`.
  final Map<String, Object?> extraFields;
  final List<String> partyLabels;
  final String? finalText;

  /// الصور المحفوظة بترتيبها.
  final List<FormAttachment> attachments;
  final String? enteredBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DisplayStatus get displayStatus => CaseStatusRules.displayStatus(
    status: status,
    revision: revision,
    lastExportedRevision: lastExportedRevision,
    reviewState: reviewState,
  );

  /// الحالات المستوردة لدى المشرف لا تُعدَّل من النموذج (تُعتمد أو تُرفض).
  bool get isEditable => reviewState == null;
}

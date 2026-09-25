import 'case_enums.dart';
import 'case_form_data.dart';
import 'case_type_field.dart';

/// خطأ تحقق مرتبط بخطوة في النموذج المتدرج حتى يُعاد المستخدم إليها.
class CaseValidationError {
  const CaseValidationError(this.step, this.message);

  final CaseFormStep step;
  final String message;

  @override
  String toString() => message;
}

enum CaseFormStep { type, basics, details, media, review }

/// قواعد التحقق: المسودة تحتاج نوع الحالة فقط، والحالة المكتملة تحتاج الأساسيات.
class CaseFormValidator {
  const CaseFormValidator._();

  static const int maxCount = 9999;

  static List<CaseValidationError> validate(
    CaseFormData data, {
    required CaseStatus targetStatus,
    List<CaseTypeFieldDef> fields = const [],
    DateTime? now,
  }) {
    final errors = <CaseValidationError>[];

    if (data.caseTypeId == null) {
      errors.add(
        const CaseValidationError(CaseFormStep.type, 'اختر نوع الحالة'),
      );
    }

    final latest = (now ?? DateTime.now()).add(const Duration(minutes: 5));
    if (data.occurredAt.isAfter(latest)) {
      errors.add(
        const CaseValidationError(
          CaseFormStep.basics,
          'وقت البلاغ لا يمكن أن يكون في المستقبل',
        ),
      );
    }

    if (_badCount(data.hasInjuries, data.injuriesCount)) {
      errors.add(
        const CaseValidationError(
          CaseFormStep.details,
          'عدد الإصابات غير صحيح',
        ),
      );
    }
    if (_badCount(data.hasDeaths, data.deathsCount)) {
      errors.add(
        const CaseValidationError(CaseFormStep.details, 'عدد الوفيات غير صحيح'),
      );
    }

    if (targetStatus == CaseStatus.draft) return errors;

    if (data.governorateId == null) {
      errors.add(
        const CaseValidationError(CaseFormStep.basics, 'اختر المحافظة'),
      );
    }
    if (data.centerId == null && data.locationText.trim().isEmpty) {
      errors.add(
        const CaseValidationError(
          CaseFormStep.basics,
          'حدد المركز أو اكتب الموقع',
        ),
      );
    }
    if (data.reportSourceId == null) {
      errors.add(
        const CaseValidationError(CaseFormStep.basics, 'اختر مصدر البلاغ'),
      );
    }
    for (final field in fields.where((f) => f.isRequired)) {
      if (field.isEmptyValue(data.extraFields[field.fieldKey])) {
        errors.add(
          CaseValidationError(
            CaseFormStep.details,
            'أكمل حقل "${field.label}"',
          ),
        );
      }
    }
    if (data.hasDamage && data.damageDescription.trim().isEmpty) {
      errors.add(
        const CaseValidationError(CaseFormStep.details, 'اكتب وصف الأضرار'),
      );
    }
    return errors;
  }

  static bool _badCount(bool has, int count) {
    if (!has) return false;
    return count < 1 || count > maxCount;
  }
}

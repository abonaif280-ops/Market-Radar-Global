import '../../../core/location/coordinates.dart';
import '../../../core/utils/arabic_format.dart';
import '../../cases/domain/case_form_data.dart';
import '../../cases/domain/case_type_field.dart';

/// وصف متغير متاح في القوالب (يُعرض في محرر القوالب).
class TemplateVariable {
  const TemplateVariable(this.key, this.description);

  final String key;
  final String description;

  String get tag => '{{$key}}';
}

/// أسماء عناصر القوائم المرتبطة بالحالة (تُحل من القاعدة قبل الصياغة).
class CaseLabels {
  const CaseLabels({
    this.caseType,
    this.reportSource,
    this.governorate,
    this.center,
    this.parties = const [],
  });

  final String? caseType;
  final String? reportSource;
  final String? governorate;
  final String? center;
  final List<String> parties;
}

/// يبني متغيرات القالب من بيانات الحالة.
class CaseTemplateVariables {
  const CaseTemplateVariables._();

  static const List<TemplateVariable> catalog = [
    TemplateVariable('الوقت', 'وقت البلاغ مثل 7:30 مساءً'),
    TemplateVariable('التاريخ', 'تاريخ البلاغ مثل 25/09/2026'),
    TemplateVariable('اليوم', 'اسم اليوم مثل الجمعة'),
    TemplateVariable('نوع_الحالة', 'نوع الحالة'),
    TemplateVariable('مصدر_البلاغ', 'مصدر البلاغ'),
    TemplateVariable('المحافظة', 'المحافظة'),
    TemplateVariable('المركز', 'المركز'),
    TemplateVariable('الموقع', 'الموقع كما كُتب'),
    TemplateVariable(
      'عبارة_الموقع',
      'الموقع كما كُتب، أو "في المركز" أو "بمحافظة ..." إن لم يُكتب',
    ),
    TemplateVariable('وصف_الموقع', 'وصف الموقع'),
    TemplateVariable('الإحداثيات', 'خط العرض، خط الطول'),
    TemplateVariable('معلومات_الحالة', 'معلومات الحالة'),
    TemplateVariable('الإجراء_المتخذ', 'الإجراء المتخذ'),
    TemplateVariable(
      'الجهات',
      'الجهات المباشرة مثل: الدفاع المدني والهلال الأحمر',
    ),
    TemplateVariable('وجود_إصابات', 'نعم/لا'),
    TemplateVariable('عدد_الإصابات', 'عدد الإصابات'),
    TemplateVariable('وجود_وفيات', 'نعم/لا'),
    TemplateVariable('عدد_الوفيات', 'عدد الوفيات'),
    TemplateVariable(
      'عبارة_الإصابات_والوفيات',
      'مثل: دون تسجيل إصابات أو وفيات / ونتج عن ذلك إصابتان',
    ),
    TemplateVariable('وجود_أضرار', 'نعم/لا'),
    TemplateVariable('وصف_الأضرار', 'وصف الأضرار'),
    TemplateVariable('ملاحظات', 'الملاحظات'),
    TemplateVariable('عدد_الصور', 'عدد الصور المرفقة'),
  ];

  /// مفتاح الحقل الخاص بالنوع في القالب: عنوانه مع استبدال المسافات بـ _.
  static String fieldVariableKey(CaseTypeFieldDef field) =>
      field.label.trim().replaceAll(RegExp(r'\s+'), '_');

  static Set<String> knownKeys(List<CaseTypeFieldDef> fields) => {
    for (final v in catalog) v.key,
    for (final f in fields) fieldVariableKey(f),
  };

  static Map<String, Object?> build(
    CaseFormData data, {
    required CaseLabels labels,
    List<CaseTypeFieldDef> fields = const [],
  }) {
    final locationText = data.locationText.trim();
    final coordinates = data.latitude == null || data.longitude == null
        ? null
        : Coordinates(data.latitude!, data.longitude!);

    return {
      'الوقت': ArabicFormat.time(data.occurredAt),
      'التاريخ': ArabicFormat.date(data.occurredAt),
      'اليوم': ArabicFormat.weekdayDate(data.occurredAt).split(' ').first,
      'نوع_الحالة': labels.caseType,
      'مصدر_البلاغ': labels.reportSource,
      'المحافظة': labels.governorate,
      'المركز': labels.center,
      'الموقع': locationText,
      'عبارة_الموقع': locationPhrase(
        locationText: locationText,
        center: labels.center,
        governorate: labels.governorate,
      ),
      'وصف_الموقع': data.locationDescription.trim(),
      'الإحداثيات': coordinates?.format(),
      'معلومات_الحالة': data.caseInfo.trim(),
      'الإجراء_المتخذ': data.actionTaken.trim(),
      'الجهات': joinArabic(labels.parties),
      'وجود_إصابات': data.hasInjuries,
      'عدد_الإصابات': data.hasInjuries ? data.injuriesCount : 0,
      'وجود_وفيات': data.hasDeaths,
      'عدد_الوفيات': data.hasDeaths ? data.deathsCount : 0,
      'عبارة_الإصابات_والوفيات': casualtiesPhrase(
        injuries: data.hasInjuries ? data.injuriesCount : 0,
        deaths: data.hasDeaths ? data.deathsCount : 0,
      ),
      'وجود_أضرار': data.hasDamage,
      'وصف_الأضرار': data.hasDamage ? data.damageDescription.trim() : '',
      'ملاحظات': data.notes.trim(),
      'عدد_الصور': data.attachments.length,
      for (final field in fields)
        fieldVariableKey(field): data.extraFields[field.fieldKey],
    };
  }

  /// "الدفاع المدني وإدارة الأسلحة والمتفجرات والهلال الأحمر"
  static String joinArabic(List<String> items) => items.join(' و');

  static String locationPhrase({
    required String locationText,
    String? center,
    String? governorate,
  }) {
    if (locationText.isNotEmpty) return locationText;
    if (center != null && center.isNotEmpty) return 'في $center';
    if (governorate != null && governorate.isNotEmpty) {
      return 'بمحافظة $governorate';
    }
    return '';
  }

  static String casualtiesPhrase({required int injuries, required int deaths}) {
    if (injuries <= 0 && deaths <= 0) return 'دون تسجيل إصابات أو وفيات';
    final parts = [
      if (injuries > 0) countPhrase(injuries, _injuryForms),
      if (deaths > 0) countPhrase(deaths, _deathForms),
    ];
    return 'ونتج عن ذلك ${parts.join(' و')}';
  }

  static const _injuryForms = (
    one: 'إصابة واحدة',
    two: 'إصابتان',
    few: 'إصابات',
    many: 'إصابة',
  );
  static const _deathForms = (
    one: 'حالة وفاة واحدة',
    two: 'حالتا وفاة',
    few: 'حالات وفاة',
    many: 'حالة وفاة',
  );

  /// قواعد العدد في العربية مبسطة: 1، 2، 3–10 (جمع)، 11+ (مفرد).
  static String countPhrase(
    int n,
    ({String one, String two, String few, String many}) forms,
  ) {
    if (n == 1) return forms.one;
    if (n == 2) return forms.two;
    if (n <= 10) return '($n) ${forms.few}';
    return '($n) ${forms.many}';
  }
}

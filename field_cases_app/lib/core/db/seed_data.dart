import '../../features/cases/domain/case_enums.dart';

/// مفاتيح القوائم في جدول lookup_items.
abstract final class LookupKeys {
  static const caseType = 'case_type';
  static const governorate = 'governorate';
  static const center = 'center';
  static const reportSource = 'report_source';
  static const party = 'party';
}

class SeedLookup {
  const SeedLookup(this.listKey, this.code, this.label, {this.parentCode});

  final String listKey;
  final String code;
  final String label;
  final String? parentCode;

  /// معرف ثابت للعناصر الأولية حتى تتطابق بين الأجهزة.
  String get id => lookupId(listKey, code);
}

class SeedField {
  const SeedField(
    this.caseTypeCode,
    this.fieldKey,
    this.label,
    this.inputType, {
    this.options,
    this.isRequired = false,
  });

  final String caseTypeCode;
  final String fieldKey;
  final String label;
  final FieldInputType inputType;
  final List<String>? options;
  final bool isRequired;

  String get caseTypeId => lookupId(LookupKeys.caseType, caseTypeCode);
  String get id => 'field:$caseTypeCode:$fieldKey';
}

String lookupId(String listKey, String code) => '$listKey:$code';

/// البيانات الأولية — قابلة للتعديل لاحقًا من شاشة الإعدادات.
abstract final class SeedData {
  static const List<SeedLookup> lookups = [
    // أنواع الحالات
    SeedLookup(LookupKeys.caseType, 'SOLID_OBJECT', 'جسم صلب'),
    SeedLookup(LookupKeys.caseType, 'SHRAPNEL', 'شظايا'),
    SeedLookup(LookupKeys.caseType, 'DRONE', 'طائرة مسيرة'),
    SeedLookup(LookupKeys.caseType, 'FIRE', 'حريق'),
    SeedLookup(LookupKeys.caseType, 'SECURITY_CASE', 'حالة أمنية'),
    SeedLookup(LookupKeys.caseType, 'SECURITY_INCIDENT', 'حادث أمني'),
    SeedLookup(LookupKeys.caseType, 'OTHER', 'أخرى'),

    // المحافظات
    SeedLookup(LookupKeys.governorate, 'MED', 'المدينة المنورة'),
    SeedLookup(LookupKeys.governorate, 'YNB', 'ينبع'),
    SeedLookup(LookupKeys.governorate, 'ULA', 'العلا'),
    SeedLookup(LookupKeys.governorate, 'MAHD', 'المهد'),
    SeedLookup(LookupKeys.governorate, 'HNK', 'الحناكية'),
    SeedLookup(LookupKeys.governorate, 'BADR', 'بدر'),
    SeedLookup(LookupKeys.governorate, 'KHAYBAR', 'خيبر'),
    SeedLookup(LookupKeys.governorate, 'AIS', 'العيص'),
    SeedLookup(LookupKeys.governorate, 'WFR', 'وادي الفرع'),

    // المراكز (أمثلة، تُستكمل من الإعدادات)
    SeedLookup(LookupKeys.center, 'RAYES', 'مركز الرايس', parentCode: 'BADR'),

    // مصادر البلاغ
    SeedLookup(LookupKeys.reportSource, '911', 'العمليات الموحدة (911)'),
    SeedLookup(LookupKeys.reportSource, 'PATROL', 'دورية ميدانية'),
    SeedLookup(LookupKeys.reportSource, 'DIRECT', 'بلاغ مباشر'),
    SeedLookup(LookupKeys.reportSource, 'CITIZEN', 'مواطن / مقيم'),
    SeedLookup(LookupKeys.reportSource, 'GOV', 'جهة حكومية'),

    // الجهات المباشرة
    SeedLookup(LookupKeys.party, 'CIVIL_DEF', 'الدفاع المدني'),
    SeedLookup(LookupKeys.party, 'EOD', 'إدارة الأسلحة والمتفجرات'),
    SeedLookup(LookupKeys.party, 'RED_CRESCENT', 'الهلال الأحمر'),
    SeedLookup(LookupKeys.party, 'FORENSICS', 'الأدلة الجنائية'),
    SeedLookup(LookupKeys.party, 'CID', 'البحث والتحري'),
    SeedLookup(LookupKeys.party, 'PATROLS', 'الدوريات الأمنية'),
    SeedLookup(LookupKeys.party, 'TRAFFIC', 'المرور'),
  ];

  static const List<SeedField> fields = [
    SeedField(
      'SOLID_OBJECT',
      'object_state',
      'حالة الجسم',
      FieldInputType.select,
      options: ['جسم سليم', 'أجزاء من جسم', 'بقايا متناثرة'],
    ),
    SeedField('SOLID_OBJECT', 'has_fire', 'وجود حريق', FieldInputType.boolean),
    SeedField(
      'SHRAPNEL',
      'pieces_count',
      'عدد الشظايا التقريبي',
      FieldInputType.number,
    ),
    SeedField('SHRAPNEL', 'spread_area', 'نطاق الانتشار', FieldInputType.text),
    SeedField(
      'DRONE',
      'drone_state',
      'حالة الطائرة',
      FieldInputType.select,
      options: ['سليمة', 'محطمة', 'أجزاء'],
    ),
    SeedField('DRONE', 'has_fire', 'وجود حريق', FieldInputType.boolean),
    SeedField(
      'FIRE',
      'fire_size',
      'حجم الحريق',
      FieldInputType.select,
      options: ['محدود', 'متوسط', 'كبير'],
    ),
    SeedField('FIRE', 'fire_controlled', 'تمت السيطرة', FieldInputType.boolean),
    SeedField(
      'SECURITY_INCIDENT',
      'incident_kind',
      'نوع الحادث',
      FieldInputType.text,
    ),
  ];
}

import 'package:drift/drift.dart';

import '../../features/cases/domain/case_enums.dart';

// تصميم الجداول موثق في docs/DESIGN.md (البند 7).
// كل تغيير هنا يتطلب رفع schemaVersion وكتابة Migration وتحديث الوثيقة.

/// القوائم القابلة للتعديل: أنواع الحالات، المحافظات، المراكز، مصادر البلاغ، الجهات.
@TableIndex(name: 'idx_lookup_list', columns: {#listKey, #isActive, #sortOrder})
class LookupItems extends Table {
  TextColumn get id => text()();
  TextColumn get listKey => text()();
  TextColumn get code => text()();
  TextColumn get label => text()();
  TextColumn get parentId => text().nullable().references(LookupItems, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {listKey, code},
  ];
}

@DataClassName('CaseRecord')
@TableIndex(
  name: 'idx_cases_active_occurred',
  columns: {
    #deletedAt,
    IndexedColumn(#occurredAt, orderBy: OrderingMode.desc),
  },
)
@TableIndex(name: 'idx_cases_display_code', columns: {#displayCode})
@TableIndex(name: 'idx_cases_status', columns: {#status})
@TableIndex(name: 'idx_cases_type', columns: {#caseTypeId})
@TableIndex(name: 'idx_cases_governorate', columns: {#governorateId})
@TableIndex(name: 'idx_cases_review', columns: {#reviewState})
@TableIndex(name: 'idx_cases_batch', columns: {#sourceBatchId})
class Cases extends Table {
  TextColumn get id => text()();
  TextColumn get displayCode => text()();
  IntColumn get serialNo => integer()();
  TextColumn get caseTypeId => text().references(LookupItems, #id)();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get governorateId =>
      text().nullable().references(LookupItems, #id)();
  TextColumn get centerId => text().nullable().references(LookupItems, #id)();
  TextColumn get locationText => text().nullable()();
  TextColumn get reportSourceId =>
      text().nullable().references(LookupItems, #id)();
  TextColumn get locationDescription => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get caseInfo => text().nullable()();
  TextColumn get actionTaken => text().nullable()();
  BoolColumn get hasInjuries => boolean().withDefault(const Constant(false))();
  IntColumn get injuriesCount => integer().withDefault(const Constant(0))();
  BoolColumn get hasDeaths => boolean().withDefault(const Constant(false))();
  IntColumn get deathsCount => integer().withDefault(const Constant(0))();
  BoolColumn get hasDamage => boolean().withDefault(const Constant(false))();
  TextColumn get damageDescription => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// قيم الحقول الخاصة بنوع الحالة (JSON) — إضافة حقل لا تحتاج Migration.
  TextColumn get extraFieldsJson => text().withDefault(const Constant('{}'))();
  TextColumn get generatedText => text().nullable()();
  TextColumn get finalText => text().nullable()();
  BoolColumn get isTextEdited => boolean().withDefault(const Constant(false))();
  TextColumn get enteredBy => text().nullable()();
  TextColumn get orgCode => text().nullable()();
  TextColumn get originDeviceId => text()();

  /// يزيد بمقدار 1 مع كل تعديل محفوظ.
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get contentHash => text().nullable()();
  TextColumn get status => textEnum<CaseStatus>()();
  IntColumn get lastExportedRevision => integer().nullable()();
  DateTimeColumn get lastExportedAt => dateTime().nullable()();
  TextColumn get reviewState => textEnum<ReviewState>().nullable()();
  TextColumn get sourceBatchId =>
      text().nullable().references(ImportBatches, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_attachments_case', columns: {#caseId, #seq})
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get caseId => text().references(Cases, #id)();
  IntColumn get seq => integer()();
  TextColumn get kind => textEnum<AttachmentKind>()();
  TextColumn get fileName => text()();

  /// مسار نسبي داخل مجلد التطبيق الخاص — لا يُخزَّن مسار مطلق.
  TextColumn get relativePath => text()();
  TextColumn get thumbRelativePath => text().nullable()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get sha256 => text()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {caseId, seq},
  ];
}

/// الجهات التي تمت مباشرتها في الحالة.
class CaseParties extends Table {
  TextColumn get caseId => text().references(Cases, #id)();
  TextColumn get partyId => text().references(LookupItems, #id)();
  DateTimeColumn get notifiedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {caseId, partyId};
}

/// تعريف الحقول الديناميكية لكل نوع حالة.
@TableIndex(name: 'idx_type_fields', columns: {#caseTypeId, #sortOrder})
class CaseTypeFields extends Table {
  TextColumn get id => text()();
  TextColumn get caseTypeId => text().references(LookupItems, #id)();
  TextColumn get fieldKey => text()();
  TextColumn get label => text()();
  TextColumn get inputType => textEnum<FieldInputType>()();
  TextColumn get optionsJson => text().nullable()();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {caseTypeId, fieldKey},
  ];
}

/// قوالب الصياغة الآلية. caseTypeId = null يعني قالبًا عامًا.
class TextTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get caseTypeId => text().nullable().references(LookupItems, #id)();
  TextColumn get name => text()();
  TextColumn get body => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// لقطات المراجعات السابقة للحالة (سجل الإصدارات).
@TableIndex(name: 'idx_versions_case', columns: {#caseId, #revision})
class CaseVersions extends Table {
  TextColumn get id => text()();
  TextColumn get caseId => text().references(Cases, #id)();
  IntColumn get revision => integer()();
  TextColumn get contentHash => text()();
  TextColumn get snapshotJson => text()();
  TextColumn get source => textEnum<VersionSource>()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ExportBatches extends Table {
  /// = package_id في manifest.json
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get scope => textEnum<ExportScope>()();
  TextColumn get fileName => text()();
  IntColumn get caseCount => integer()();
  IntColumn get attachmentCount => integer()();
  TextColumn get packageSha256 => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ExportBatchItems extends Table {
  TextColumn get batchId => text().references(ExportBatches, #id)();
  TextColumn get caseId => text().references(Cases, #id)();
  IntColumn get revision => integer()();

  @override
  Set<Column> get primaryKey => {batchId, caseId};
}

class ImportBatches extends Table {
  /// = package_id في manifest.json — يكشف إعادة استيراد نفس الحزمة.
  TextColumn get id => text()();
  TextColumn get orgName => text().nullable()();
  TextColumn get orgCode => text().nullable()();
  TextColumn get sourceDeviceId => text().nullable()();
  TextColumn get enteredBy => text().nullable()();
  DateTimeColumn get packageCreatedAt => dateTime()();
  DateTimeColumn get importedAt => dateTime()();
  IntColumn get formatVersion => integer()();
  IntColumn get caseCount => integer()();
  IntColumn get imageCount => integer()();
  IntColumn get attachmentCount => integer()();
  TextColumn get status => textEnum<ImportBatchStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

class ImportBatchItems extends Table {
  TextColumn get batchId => text().references(ImportBatches, #id)();

  /// لا يوجد FK هنا: الحالة قد تكون مرفوضة/متجاهلة فلا تُدرج في cases.
  TextColumn get caseId => text()();
  IntColumn get incomingRevision => integer()();
  TextColumn get classification => textEnum<ImportClassification>()();
  TextColumn get decision => textEnum<ImportDecision>()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {batchId, caseId};
}

@TableIndex(name: 'idx_audit_at', columns: {#at})
@TableIndex(name: 'idx_audit_entity', columns: {#entityType, #entityId})
class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get detailsJson => text().nullable()();
  TextColumn get actor => text().nullable()();
}

/// إعدادات غير حساسة فقط. الأسرار في Secure Storage (المرحلة 13).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

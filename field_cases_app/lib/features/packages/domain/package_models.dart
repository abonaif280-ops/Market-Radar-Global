// نماذج حزمة `.casepkg` (docs/DESIGN.md البند 10).
// صيغة معتمدة: أي تغيير يجب أن يبقى قابلًا لقراءة الحزم القديمة
// (إضافة حقول اختيارية فقط، أو رفع packageFormatVersion مع دعم القديم).

abstract final class PackageFormat {
  /// إصدار صيغة الحزمة الحالي.
  static const int currentVersion = 1;

  /// الإصدارات التي يستطيع هذا التطبيق قراءتها.
  static const Set<int> supportedVersions = {1};

  static const int casesSchemaVersion = 1;
  static const String extension = 'casepkg';
  static const String manifestFile = 'manifest.json';
  static const String casesFile = 'cases.json';
  static const String attachmentsDir = 'attachments';
}

/// ملف داخل الحزمة مع بصمته للتحقق من السلامة.
class PackageFileEntry {
  const PackageFileEntry({
    required this.path,
    required this.sha256,
    required this.size,
  });

  factory PackageFileEntry.fromJson(Map<String, dynamic> json) =>
      PackageFileEntry(
        path: json['path'] as String,
        sha256: json['sha256'] as String,
        size: (json['size'] as num).toInt(),
      );

  final String path;
  final String sha256;
  final int size;

  Map<String, Object?> toJson() => {
    'path': path,
    'sha256': sha256,
    'size': size,
  };
}

class PackageSource {
  const PackageSource({
    required this.deviceId,
    this.orgName,
    this.orgCode,
    this.enteredBy,
  });

  factory PackageSource.fromJson(Map<String, dynamic> json) => PackageSource(
    deviceId: json['device_id'] as String,
    orgName: json['org_name'] as String?,
    orgCode: json['org_code'] as String?,
    enteredBy: json['entered_by'] as String?,
  );

  /// معرف منطقي عشوائي للجهاز (ليس معرف عتاد).
  final String deviceId;
  final String? orgName;
  final String? orgCode;
  final String? enteredBy;

  Map<String, Object?> toJson() => {
    'device_id': deviceId,
    'org_name': orgName,
    'org_code': orgCode,
    'entered_by': enteredBy,
  };
}

class PackageManifest {
  const PackageManifest({
    required this.packageFormatVersion,
    required this.packageId,
    required this.createdAt,
    required this.createdAtLocal,
    required this.appVersion,
    required this.source,
    required this.scope,
    required this.caseCount,
    required this.imageCount,
    required this.attachmentCount,
    required this.files,
    required this.contentSha256,
  });

  factory PackageManifest.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] as Map<String, dynamic>;
    return PackageManifest(
      packageFormatVersion: (json['package_format_version'] as num).toInt(),
      packageId: json['package_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdAtLocal: json['created_at_local'] as String?,
      appVersion: json['app_version'] as String?,
      source: PackageSource.fromJson(json['source'] as Map<String, dynamic>),
      scope: json['scope'] as String?,
      caseCount: (counts['cases'] as num).toInt(),
      imageCount: (counts['images'] as num).toInt(),
      attachmentCount: (counts['attachments'] as num).toInt(),
      files: [
        for (final f in json['files'] as List)
          PackageFileEntry.fromJson(f as Map<String, dynamic>),
      ],
      contentSha256: json['content_sha256'] as String,
    );
  }

  final int packageFormatVersion;
  final String packageId;
  final DateTime createdAt;
  final String? createdAtLocal;
  final String? appVersion;
  final PackageSource source;
  final String? scope;
  final int caseCount;
  final int imageCount;
  final int attachmentCount;
  final List<PackageFileEntry> files;

  /// بصمة قائمة الملفات (مساراتها وبصماتها) = بصمة الحزمة كاملة.
  final String contentSha256;

  Map<String, Object?> toJson() => {
    'package_format_version': packageFormatVersion,
    'package_id': packageId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'created_at_local': createdAtLocal,
    'app_version': appVersion,
    'source': source.toJson(),
    'scope': scope,
    'counts': {
      'cases': caseCount,
      'images': imageCount,
      'attachments': attachmentCount,
    },
    'files': [for (final f in files) f.toJson()],
    'content_sha256': contentSha256,
  };
}

/// عنصر قائمة (نوع/محافظة/...) منقول بالرمز والاسم معًا، لأن قوائم جهاز
/// المستقبل قد تختلف عن قوائم المرسل.
class PackagedLookup {
  const PackagedLookup({required this.code, required this.label});

  static PackagedLookup? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return PackagedLookup(
      code: json['code'] as String,
      label: json['label'] as String,
    );
  }

  final String code;
  final String label;

  Map<String, Object?> toJson() => {'code': code, 'label': label};
}

class PackagedAttachment {
  const PackagedAttachment({
    required this.attachmentUuid,
    required this.seq,
    required this.kind,
    required this.fileName,
    required this.path,
    required this.mimeType,
    required this.size,
    required this.sha256,
    this.width,
    this.height,
  });

  factory PackagedAttachment.fromJson(Map<String, dynamic> json) =>
      PackagedAttachment(
        attachmentUuid: json['attachment_uuid'] as String,
        seq: (json['seq'] as num).toInt(),
        kind: json['kind'] as String,
        fileName: json['file_name'] as String,
        path: json['path'] as String,
        mimeType: json['mime_type'] as String,
        size: (json['size'] as num).toInt(),
        sha256: json['sha256'] as String,
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
      );

  final String attachmentUuid;
  final int seq;
  final String kind;
  final String fileName;

  /// المسار داخل الحزمة: `attachments/<case_uuid>/<file_name>`.
  final String path;
  final String mimeType;
  final int size;
  final String sha256;
  final int? width;
  final int? height;

  Map<String, Object?> toJson() => {
    'attachment_uuid': attachmentUuid,
    'seq': seq,
    'kind': kind,
    'file_name': fileName,
    'path': path,
    'mime_type': mimeType,
    'size': size,
    'sha256': sha256,
    'width': width,
    'height': height,
  };
}

/// حالة داخل cases.json — المصدر الأساسي للاستيراد.
class PackagedCase {
  const PackagedCase({
    required this.caseUuid,
    required this.displayCode,
    required this.serialNo,
    required this.revision,
    required this.contentHash,
    required this.status,
    required this.caseType,
    required this.occurredAt,
    required this.originDeviceId,
    required this.createdAt,
    required this.updatedAt,
    this.governorate,
    this.center,
    this.locationText,
    this.reportSource,
    this.locationDescription,
    this.latitude,
    this.longitude,
    this.caseInfo,
    this.actionTaken,
    this.parties = const [],
    this.injuriesCount = 0,
    this.hasInjuries = false,
    this.deathsCount = 0,
    this.hasDeaths = false,
    this.hasDamage = false,
    this.damageDescription,
    this.extraFields = const {},
    this.notes,
    this.finalText,
    this.isTextEdited = false,
    this.enteredBy,
    this.orgCode,
    this.attachments = const [],
  });

  factory PackagedCase.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>?;
    final injuries = json['injuries'] as Map<String, dynamic>? ?? const {};
    final deaths = json['deaths'] as Map<String, dynamic>? ?? const {};
    final damage = json['damage'] as Map<String, dynamic>? ?? const {};
    return PackagedCase(
      caseUuid: json['case_uuid'] as String,
      displayCode: json['display_code'] as String,
      serialNo: (json['serial_no'] as num).toInt(),
      revision: (json['revision'] as num).toInt(),
      contentHash: json['content_hash'] as String,
      status: json['status'] as String,
      caseType: PackagedLookup.fromJson(json['case_type'])!,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      governorate: PackagedLookup.fromJson(json['governorate']),
      center: PackagedLookup.fromJson(json['center']),
      locationText: json['location_text'] as String?,
      reportSource: PackagedLookup.fromJson(json['report_source']),
      locationDescription: json['location_description'] as String?,
      latitude: (coords?['lat'] as num?)?.toDouble(),
      longitude: (coords?['lng'] as num?)?.toDouble(),
      caseInfo: json['case_info'] as String?,
      actionTaken: json['action_taken'] as String?,
      parties: [
        for (final p in json['parties'] as List? ?? const [])
          PackagedLookup.fromJson(p)!,
      ],
      hasInjuries: injuries['has'] as bool? ?? false,
      injuriesCount: (injuries['count'] as num?)?.toInt() ?? 0,
      hasDeaths: deaths['has'] as bool? ?? false,
      deathsCount: (deaths['count'] as num?)?.toInt() ?? 0,
      hasDamage: damage['has'] as bool? ?? false,
      damageDescription: damage['description'] as String?,
      extraFields: Map<String, Object?>.from(
        json['extra_fields'] as Map? ?? const {},
      ),
      notes: json['notes'] as String?,
      finalText: json['final_text'] as String?,
      isTextEdited: json['is_text_edited'] as bool? ?? false,
      enteredBy: json['entered_by'] as String?,
      orgCode: json['org_code'] as String?,
      originDeviceId: json['origin_device_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      attachments: [
        for (final a in json['attachments'] as List? ?? const [])
          PackagedAttachment.fromJson(a as Map<String, dynamic>),
      ],
    );
  }

  final String caseUuid;
  final String displayCode;
  final int serialNo;
  final int revision;
  final String contentHash;
  final String status;
  final PackagedLookup caseType;
  final DateTime occurredAt;
  final PackagedLookup? governorate;
  final PackagedLookup? center;
  final String? locationText;
  final PackagedLookup? reportSource;
  final String? locationDescription;
  final double? latitude;
  final double? longitude;
  final String? caseInfo;
  final String? actionTaken;
  final List<PackagedLookup> parties;
  final bool hasInjuries;
  final int injuriesCount;
  final bool hasDeaths;
  final int deathsCount;
  final bool hasDamage;
  final String? damageDescription;
  final Map<String, Object?> extraFields;
  final String? notes;
  final String? finalText;
  final bool isTextEdited;
  final String? enteredBy;
  final String? orgCode;
  final String originDeviceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PackagedAttachment> attachments;

  Map<String, Object?> toJson() => {
    'case_uuid': caseUuid,
    'display_code': displayCode,
    'serial_no': serialNo,
    'revision': revision,
    'content_hash': contentHash,
    'status': status,
    'case_type': caseType.toJson(),
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'governorate': governorate?.toJson(),
    'center': center?.toJson(),
    'location_text': locationText,
    'report_source': reportSource?.toJson(),
    'location_description': locationDescription,
    'coordinates': latitude == null || longitude == null
        ? null
        : {'lat': latitude, 'lng': longitude},
    'case_info': caseInfo,
    'action_taken': actionTaken,
    'parties': [for (final p in parties) p.toJson()],
    'injuries': {'has': hasInjuries, 'count': injuriesCount},
    'deaths': {'has': hasDeaths, 'count': deathsCount},
    'damage': {'has': hasDamage, 'description': damageDescription},
    'extra_fields': extraFields,
    'notes': notes,
    'final_text': finalText,
    'is_text_edited': isTextEdited,
    'entered_by': enteredBy,
    'org_code': orgCode,
    'origin_device_id': originDeviceId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'attachments': [for (final a in attachments) a.toJson()],
  };
}

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';

import '../domain/package_models.dart';

class PackageBuildException implements Exception {
  const PackageBuildException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// ينشئ ملف `.casepkg` (ZIP منظم) من الحالات وصورها:
///
/// ```
/// manifest.json
/// cases.json
/// attachments/<case_uuid>/EVT-..._001.jpg
/// ```
///
/// الصور تُضاف بدون ضغط (JPEG مضغوطة أصلًا) وبالبث من القرص دون تحميلها كاملة
/// في الذاكرة. الملف يُكتب باسم مؤقت ثم يُعاد تسميته، فلا يبقى ملف ناقص.
class CasePackageWriter {
  const CasePackageWriter();

  Future<PackageManifest> write({
    required File output,
    required String packageId,
    required DateTime createdAt,
    required String appVersion,
    required PackageSource source,
    required String scope,
    required List<PackagedCase> cases,

    /// المسار داخل الحزمة ← المسار المطلق للملف على الجهاز.
    required Map<String, String> attachmentFiles,
  }) async {
    final casesBytes = utf8.encode(
      jsonEncode({
        'schema_version': PackageFormat.casesSchemaVersion,
        'cases': [for (final c in cases) c.toJson()],
      }),
    );

    final entries = <PackageFileEntry>[
      PackageFileEntry(
        path: PackageFormat.casesFile,
        sha256: sha256.convert(casesBytes).toString(),
        size: casesBytes.length,
      ),
    ];

    final expected = {
      for (final c in cases)
        for (final a in c.attachments) a.path: a,
    };
    final sortedPaths = expected.keys.toList()..sort();
    for (final path in sortedPaths) {
      final source = attachmentFiles[path];
      final file = source == null ? null : File(source);
      if (file == null || !await file.exists()) {
        throw PackageBuildException('ملف مرفق مفقود: $path');
      }
      final digest = (await sha256.bind(file.openRead()).first).toString();
      if (digest != expected[path]!.sha256) {
        throw PackageBuildException('ملف مرفق تغيّر أو تلف: $path');
      }
      entries.add(
        PackageFileEntry(path: path, sha256: digest, size: await file.length()),
      );
    }

    final allAttachments = expected.values;
    final manifest = PackageManifest(
      packageFormatVersion: PackageFormat.currentVersion,
      packageId: packageId,
      createdAt: createdAt.toUtc(),
      createdAtLocal: _localIso(createdAt),
      appVersion: appVersion,
      source: source,
      scope: scope,
      caseCount: cases.length,
      imageCount: allAttachments.where((a) => a.kind == 'image').length,
      attachmentCount: allAttachments.length,
      files: entries,
      contentSha256: contentHashOf(entries),
    );

    final partial = File('${output.path}.partial');
    if (await partial.exists()) await partial.delete();
    final encoder = ZipFileEncoder()..create(partial.path);
    try {
      encoder.addArchiveFile(
        ArchiveFile.bytes(
          PackageFormat.manifestFile,
          utf8.encode(
            const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
          ),
        ),
      );
      encoder.addArchiveFile(
        ArchiveFile.bytes(PackageFormat.casesFile, casesBytes),
      );
      for (final path in sortedPaths) {
        await encoder.addFile(
          File(attachmentFiles[path]!),
          path,
          ZipFileEncoder.store,
        );
      }
      await encoder.close();
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
    if (await output.exists()) await output.delete();
    await partial.rename(output.path);
    return manifest;
  }

  /// بصمة الحزمة: SHA-256 لقائمة الملفات المرتبة (المسار والبصمة والحجم).
  static String contentHashOf(List<PackageFileEntry> entries) {
    final sorted = [...entries]..sort((a, b) => a.path.compareTo(b.path));
    final canonical = jsonEncode([for (final e in sorted) e.toJson()]);
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  static String _localIso(DateTime time) {
    final local = time.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final base = local.toIso8601String().split('.').first;
    return '$base$sign$hours:$minutes';
  }
}

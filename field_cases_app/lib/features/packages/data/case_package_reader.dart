import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../domain/package_models.dart';
import 'case_package_writer.dart';

/// نتيجة فحص حزمة قبل إدخال أي شيء منها.
class PackageInspection {
  const PackageInspection({
    required this.manifest,
    required this.cases,
    required this.errors,
  });

  final PackageManifest? manifest;
  final List<PackagedCase> cases;

  /// أخطاء تمنع الاستيراد (بالعربية للعرض).
  final List<String> errors;

  bool get isValid => errors.isEmpty && manifest != null;
}

/// يفحص حزمة `.casepkg` ويتحقق من سلامتها:
/// نوع الملف، إصدار الصيغة، المسارات الآمنة (منع Zip Slip)، وجود كل ملف مذكور،
/// مطابقة البصمات والأحجام والأعداد، وعدم تكرار الحالات.
class CasePackageReader {
  const CasePackageReader();

  static const List<int> _zipMagic = [0x50, 0x4B, 0x03, 0x04];

  /// بداية المغلف المشفر (المرحلة 13): "CASEPKG".
  static const List<int> _envelopeMagic = [
    0x43,
    0x41,
    0x53,
    0x45,
    0x50,
    0x4B,
    0x47,
  ];

  Future<PackageInspection> inspect(File file) async {
    PackageInspection fail(String error) =>
        PackageInspection(manifest: null, cases: const [], errors: [error]);

    if (!await file.exists()) return fail('الملف غير موجود');
    final header = await _readHeader(file, 8);
    if (_startsWith(header, _envelopeMagic)) {
      return fail('الحزمة مشفرة ولا يمكن فتحها على هذا الجهاز');
    }
    if (!_startsWith(header, _zipMagic)) {
      return fail('الملف ليس حزمة حالات صالحة');
    }

    final input = InputFileStream(file.path);
    try {
      final Archive archive;
      try {
        archive = ZipDecoder().decodeStream(input);
      } on Object {
        return fail('الحزمة تالفة ولا يمكن قراءتها');
      }
      return _inspectArchive(archive);
    } finally {
      await input.close();
    }
  }

  /// يستخرج ملفات المرفقات (بعد التحقق منها) إلى [destination] بنفس مساراتها.
  Future<void> extractAttachments(File file, Directory destination) async {
    final input = InputFileStream(file.path);
    try {
      final archive = ZipDecoder().decodeStream(input);
      for (final entry in archive.files) {
        if (!entry.isFile ||
            !entry.name.startsWith('${PackageFormat.attachmentsDir}/') ||
            !isSafePath(entry.name)) {
          continue;
        }
        final target = File(p.join(destination.path, entry.name));
        if (!p.isWithin(destination.path, target.path)) continue;
        await target.parent.create(recursive: true);
        final output = OutputFileStream(target.path);
        entry.writeContent(output);
        await output.close();
      }
    } finally {
      await input.close();
    }
  }

  PackageInspection _inspectArchive(Archive archive) {
    final errors = <String>[];
    final entries = <String, ArchiveFile>{};
    for (final entry in archive.files.where((f) => f.isFile)) {
      if (!isSafePath(entry.name)) {
        return PackageInspection(
          manifest: null,
          cases: const [],
          errors: ['الحزمة تحتوي مسارًا غير آمن: ${entry.name}'],
        );
      }
      entries[entry.name] = entry;
    }

    final manifestEntry = entries[PackageFormat.manifestFile];
    if (manifestEntry == null) {
      return const PackageInspection(
        manifest: null,
        cases: [],
        errors: ['الحزمة لا تحتوي manifest.json'],
      );
    }

    final PackageManifest manifest;
    try {
      manifest = PackageManifest.fromJson(
        jsonDecode(utf8.decode(manifestEntry.readBytes()!))
            as Map<String, dynamic>,
      );
    } on Object {
      return const PackageInspection(
        manifest: null,
        cases: [],
        errors: ['ملف manifest.json غير صالح'],
      );
    }

    if (!PackageFormat.supportedVersions.contains(
      manifest.packageFormatVersion,
    )) {
      return PackageInspection(
        manifest: manifest,
        cases: const [],
        errors: [
          'إصدار الحزمة (${manifest.packageFormatVersion}) أحدث من هذا التطبيق. حدّث التطبيق ثم أعد المحاولة.',
        ],
      );
    }

    if (CasePackageWriter.contentHashOf(manifest.files) !=
        manifest.contentSha256) {
      errors.add('بصمة الحزمة لا تطابق قائمة ملفاتها');
    }

    final listed = {for (final f in manifest.files) f.path: f};
    for (final file in manifest.files) {
      final entry = entries[file.path];
      if (entry == null) {
        errors.add('ملف مفقود من الحزمة: ${file.path}');
        continue;
      }
      final bytes = entry.readBytes() ?? Uint8List(0);
      if (bytes.length != file.size ||
          sha256.convert(bytes).toString() != file.sha256) {
        errors.add('ملف تالف أو معدل: ${file.path}');
      }
    }
    for (final name in entries.keys) {
      if (name != PackageFormat.manifestFile && !listed.containsKey(name)) {
        errors.add('ملف غير مذكور في manifest: $name');
      }
    }

    final casesEntry = entries[PackageFormat.casesFile];
    if (casesEntry == null || !listed.containsKey(PackageFormat.casesFile)) {
      errors.add('الحزمة لا تحتوي cases.json');
      return PackageInspection(
        manifest: manifest,
        cases: const [],
        errors: errors,
      );
    }

    final List<PackagedCase> cases;
    try {
      final json = jsonDecode(
        utf8.decode(casesEntry.readBytes()!),
      ) as Map<String, dynamic>;
      cases = [
        for (final c in json['cases'] as List)
          PackagedCase.fromJson(c as Map<String, dynamic>),
      ];
    } on Object {
      errors.add('ملف cases.json غير صالح');
      return PackageInspection(
        manifest: manifest,
        cases: const [],
        errors: errors,
      );
    }

    final seen = <String>{};
    var attachmentCount = 0;
    for (final c in cases) {
      if (!seen.add(c.caseUuid)) {
        errors.add('حالة مكررة داخل الحزمة: ${c.displayCode}');
      }
      for (final a in c.attachments) {
        attachmentCount++;
        final expectedPrefix = '${PackageFormat.attachmentsDir}/${c.caseUuid}/';
        if (!a.path.startsWith(expectedPrefix) || !listed.containsKey(a.path)) {
          errors.add('مرفق غير صحيح للحالة ${c.displayCode}: ${a.fileName}');
        } else if (listed[a.path]!.sha256 != a.sha256) {
          errors.add('بصمة مرفق غير متطابقة: ${a.fileName}');
        }
      }
    }
    if (cases.length != manifest.caseCount) {
      errors.add(
        'عدد الحالات (${cases.length}) لا يطابق المذكور (${manifest.caseCount})',
      );
    }
    if (attachmentCount != manifest.attachmentCount) {
      errors.add('عدد المرفقات لا يطابق المذكور في الحزمة');
    }

    return PackageInspection(manifest: manifest, cases: cases, errors: errors);
  }

  /// مسار نسبي آمن: بدون `..` ولا مسار مطلق ولا شرطة عكسية.
  static bool isSafePath(String name) {
    if (name.isEmpty || name.startsWith('/') || name.contains(r'\')) {
      return false;
    }
    if (RegExp(r'^[A-Za-z]:').hasMatch(name)) return false;
    return !name.split('/').any((segment) => segment == '..');
  }

  static Future<List<int>> _readHeader(File file, int length) async {
    final raf = await file.open();
    try {
      return await raf.read(length);
    } finally {
      await raf.close();
    }
  }

  static bool _startsWith(List<int> bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }
}

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../features/cases/domain/form_attachment.dart';

/// ملف نُقل من منطقة الانتظار إلى مجلد الحالة، مع ما يلزم للتراجع عنه.
class CommittedAttachment {
  const CommittedAttachment({
    required this.source,
    required this.relativePath,
    required this.thumbRelativePath,
    required this.fileName,
  });

  final FormAttachment source;
  final String relativePath;
  final String? thumbRelativePath;
  final String fileName;
}

class AttachmentStorageException implements Exception {
  const AttachmentStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// تخزين الصور داخل مجلد التطبيق الخاص (غير مرئي للمعرض):
///
/// ```
/// <root>/attachments/<case_uuid>/EVT-20260925-A72F91_001.jpg
/// <root>/attachments/<case_uuid>/thumbs/EVT-20260925-A72F91_001.jpg
/// <root>/staging/<uuid>.jpg        ← صور لم تُحفظ حالتها بعد
/// ```
///
/// قاعدة البيانات تحفظ المسارات النسبية فقط.
class AttachmentStorage {
  AttachmentStorage(this.root, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const int thumbnailWidth = 320;

  final Directory root;
  final Uuid _uuid;

  Directory get _staging => Directory(p.join(root.path, 'staging'));

  String absolute(String relativePath) => p.join(root.path, relativePath);

  /// ينسخ صورة (من الكاميرا/المعرض) إلى منطقة الانتظار، ويحسب البصمة وينشئ مصغرة.
  ///
  /// [deleteSource]: حذف الملف المصدر بعد النسخ (نسخ image_picker المؤقتة).
  Future<FormAttachment> stageImage(
    String sourcePath, {
    bool deleteSource = false,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const AttachmentStorageException('ملف الصورة غير موجود');
    }
    await _staging.create(recursive: true);

    final extension = _normalizedExtension(sourcePath);
    final id = _uuid.v4();
    final staged = File(p.join(_staging.path, '$id.$extension'));
    await source.copy(staged.path);
    if (deleteSource) await _deleteQuietly(source);

    final bytes = await staged.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    final thumb = await Isolate.run(() => _makeThumbnail(bytes));

    String? thumbPath;
    if (thumb != null) {
      thumbPath = p.join(_staging.path, '${id}_thumb.jpg');
      await File(thumbPath).writeAsBytes(thumb.jpeg, flush: true);
    }

    return FormAttachment(
      filePath: staged.path,
      thumbPath: thumbPath,
      sha256: digest,
      sizeBytes: bytes.length,
      mimeType: mimeTypeFor(extension),
      width: thumb?.width,
      height: thumb?.height,
    );
  }

  /// ينقل صورة من منطقة الانتظار إلى مجلد الحالة باسمها المنظم.
  Future<CommittedAttachment> commit(
    FormAttachment staged, {
    required String caseId,
    required String fileName,
  }) async {
    if (!staged.isNew || !p.isWithin(_staging.path, staged.filePath)) {
      throw const AttachmentStorageException('المرفق ليس في منطقة الانتظار');
    }
    final caseDir = p.join('attachments', caseId);
    final relativePath = p.join(caseDir, fileName);
    await Directory(absolute(caseDir)).create(recursive: true);
    await File(staged.filePath).rename(absolute(relativePath));

    String? thumbRelative;
    if (staged.thumbPath != null) {
      thumbRelative = p.join(caseDir, 'thumbs', fileName);
      await Directory(p.dirname(absolute(thumbRelative)))
          .create(recursive: true);
      await File(staged.thumbPath!).rename(absolute(thumbRelative));
    }
    return CommittedAttachment(
      source: staged,
      relativePath: relativePath,
      thumbRelativePath: thumbRelative,
      fileName: fileName,
    );
  }

  /// ينقل ملفًا مستخرجًا من حزمة مستوردة إلى مجلد الحالة، وينشئ مصغرته.
  ///
  /// يعيد (المسار النسبي، مسار المصغرة النسبي أو null).
  Future<(String, String?)> adoptImported(
    File source, {
    required String caseId,
    required String fileName,
  }) async {
    final caseDir = p.join('attachments', caseId);
    final relativePath = p.join(caseDir, fileName);
    await Directory(absolute(caseDir)).create(recursive: true);
    await source.rename(absolute(relativePath));

    final bytes = await File(absolute(relativePath)).readAsBytes();
    final thumb = await Isolate.run(() => _makeThumbnail(bytes));
    if (thumb == null) return (relativePath, null);
    final thumbRelative = p.join(caseDir, 'thumbs', fileName);
    await Directory(p.dirname(absolute(thumbRelative))).create(recursive: true);
    await File(absolute(thumbRelative)).writeAsBytes(thumb.jpeg, flush: true);
    return (relativePath, thumbRelative);
  }

  /// حذف ملفات بمساراتها النسبية (تراجع عن استيراد فشل).
  Future<void> deleteRelative(Iterable<String> relativePaths) async {
    for (final path in relativePaths) {
      await _deleteQuietly(File(absolute(path)));
    }
  }

  /// يعيد الملفات لمنطقة الانتظار إذا فشل حفظ الحالة، حتى يمكن إعادة المحاولة.
  Future<void> rollback(Iterable<CommittedAttachment> committed) async {
    for (final c in committed) {
      final file = File(absolute(c.relativePath));
      if (await file.exists()) await file.rename(c.source.filePath);
      if (c.thumbRelativePath != null && c.source.thumbPath != null) {
        final thumb = File(absolute(c.thumbRelativePath!));
        if (await thumb.exists()) await thumb.rename(c.source.thumbPath!);
      }
    }
  }

  /// يحذف صورًا جديدة لم تُحفظ (عند إلغاء النموذج أو حذفها قبل الحفظ).
  Future<void> discardStaged(Iterable<FormAttachment> attachments) async {
    for (final a in attachments.where((a) => a.isNew)) {
      for (final path in [a.filePath, ?a.thumbPath]) {
        if (p.isWithin(_staging.path, path)) await _deleteQuietly(File(path));
      }
    }
  }

  /// يُستدعى عند بدء التطبيق لحذف بقايا نماذج لم تكتمل.
  Future<void> clearStaging() async {
    if (await _staging.exists()) await _staging.delete(recursive: true);
  }

  static String _normalizedExtension(String path) {
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
    return switch (ext) {
      'jpeg' || '' => 'jpg',
      _ => ext,
    };
  }

  static String mimeTypeFor(String extension) => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'heic' => 'image/heic',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => 'application/octet-stream',
  };

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // الحذف هنا تنظيف فقط؛ فشله لا يوقف العملية.
    }
  }
}

class _Thumbnail {
  const _Thumbnail(this.jpeg, this.width, this.height);

  final Uint8List jpeg;
  final int width;
  final int height;
}

/// يعمل في Isolate منفصل حتى لا تتجمد الواجهة. يعيد null للصيغ غير المدعومة (مثل HEIC).
_Thumbnail? _makeThumbnail(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final oriented = img.bakeOrientation(decoded);
  final resized = oriented.width > AttachmentStorage.thumbnailWidth
      ? img.copyResize(oriented, width: AttachmentStorage.thumbnailWidth)
      : oriented;
  return _Thumbnail(
    img.encodeJpg(resized, quality: 75),
    oriented.width,
    oriented.height,
  );
}

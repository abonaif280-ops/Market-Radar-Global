import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../crypto/backup_cipher.dart';
import '../crypto/package_cipher.dart';

/// ملفات يفتحها المستخدم بالتطبيق من تطبيق آخر ("فتح بواسطة" في WhatsApp أو Files).
///
/// الكود الأصلي (MainActivity.kt / AppDelegate.swift) ينسخ الملف إلى مجلد مؤقت
/// داخل التطبيق ويرسل مساره. لا شيء يُقرأ أو يُرسل خارج الجهاز.
abstract interface class IncomingFiles {
  /// ملف فُتح به التطبيق عند تشغيله (مرة واحدة).
  Future<String?> initialFile();

  /// ملفات تصل والتطبيق مفتوح.
  Stream<String> get files;
}

class PlatformIncomingFiles implements IncomingFiles {
  PlatformIncomingFiles() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onFile' && call.arguments is String) {
        _controller.add(call.arguments as String);
      }
    });
  }

  static const _channel = MethodChannel('field_cases/incoming_file');
  final _controller = StreamController<String>.broadcast();

  @override
  Future<String?> initialFile() async {
    try {
      return await _channel.invokeMethod<String>('getInitialFile');
    } on MissingPluginException {
      return null; // منصة بلا دعم (اختبارات/سطح المكتب).
    } on PlatformException catch (e) {
      debugPrint('incoming file failed: ${e.message}');
      return null;
    }
  }

  @override
  Stream<String> get files => _controller.stream;
}

enum IncomingKind { package, backup, unsupported }

/// يحدد نوع الملف من محتواه لا من اسمه (WhatsApp قد يغيّر الاسم).
Future<IncomingKind> classifyIncoming(File file) async {
  if (!await file.exists()) return IncomingKind.unsupported;
  if (await BackupCipher.isBackup(file)) return IncomingKind.backup;
  if (await PackageCipher.isEnvelope(file)) return IncomingKind.package;
  final raf = await file.open();
  try {
    final head = await raf.read(4);
    // ZIP: حزمة غير مشفرة (الفحص الكامل يتم في شاشة الاستيراد).
    if (head.length == 4 &&
        head[0] == 0x50 &&
        head[1] == 0x4B &&
        head[2] == 0x03 &&
        head[3] == 0x04) {
      return IncomingKind.package;
    }
  } finally {
    await raf.close();
  }
  return IncomingKind.unsupported;
}

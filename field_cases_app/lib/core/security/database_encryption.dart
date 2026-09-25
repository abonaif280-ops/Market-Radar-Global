import 'dart:io';
import 'dart:math';

import 'package:sqlite3/sqlite3.dart';

import 'secret_store.dart';

/// تشفير ملف قاعدة البيانات على الجهاز (SQLite3MultipleCiphers، ChaCha20-Poly1305).
///
/// المفتاح 256-bit عشوائي يُولَّد عند أول تشغيل ويُحفظ في Keychain/Keystore فقط،
/// ولا يُكتب في أي ملف. بدون المفتاح لا يمكن قراءة الملف حتى لو نُسخ من الجهاز.
class DatabaseEncryption {
  DatabaseEncryption(this._secrets, {Random? random})
    : _random = random ?? Random.secure();

  static const String keyName = 'database_key';
  static const List<int> _plainHeader = [
    // "SQLite format 3\0"
    0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66,
    0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00,
  ];

  final SecretStore _secrets;
  final Random _random;

  /// مفتاح القاعدة (يُنشأ مرة واحدة).
  Future<String> obtainKey() async {
    final existing = await _secrets.read(keyName);
    if (existing != null) return existing;
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _secrets.write(keyName, key);
    return key;
  }

  /// أمر SQL لفتح القاعدة المشفرة. المفتاح أحرف hex فقط فلا حاجة لتهريب.
  static String keyPragma(String key) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(key)) {
      throw ArgumentError('Invalid database key format');
    }
    return "PRAGMA key = '$key'";
  }

  /// قاعدة أُنشئت قبل تفعيل التشفير تُشفَّر في مكانها مرة واحدة (PRAGMA rekey).
  ///
  /// يعيد true إذا شُفّر ملف كان غير مشفر.
  static Future<bool> encryptIfPlain(File file, String key) async {
    if (!await file.exists() || await file.length() < _plainHeader.length) {
      return false;
    }
    final raf = await file.open();
    final List<int> header;
    try {
      header = await raf.read(_plainHeader.length);
    } finally {
      await raf.close();
    }
    for (var i = 0; i < _plainHeader.length; i++) {
      if (header[i] != _plainHeader[i]) return false;
    }
    final db = sqlite3.open(file.path);
    try {
      keyPragma(key); // تحقق من الصيغة قبل التنفيذ.
      db.execute("PRAGMA rekey = '$key'");
    } finally {
      db.close();
    }
    return true;
  }
}

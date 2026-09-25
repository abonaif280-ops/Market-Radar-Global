import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'chunked_aead.dart';

class BackupCipherException implements Exception {
  const BackupCipherException(this.message, {this.wrongPassword = false});

  final String message;

  /// فشل التحقق من أول قطعة: كلمة مرور خاطئة (أو ملف تالف).
  final bool wrongPassword;

  @override
  String toString() => message;
}

/// معاملات Argon2id المستخدمة لاشتقاق المفتاح (تُحفظ في رأس الملف).
class Argon2Params {
  const Argon2Params({
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
  });

  /// 32MiB × 3: أقوى من إعدادات رمز PIN لأن الملف قد يُنسخ ويُهاجم دون حد
  /// للمحاولات، مع زمن مقبول على الجوال (ثوانٍ قليلة).
  static const standard = Argon2Params(
    memoryKiB: 32768,
    iterations: 3,
    parallelism: 1,
  );

  /// للاختبارات فقط.
  static const fast = Argon2Params(
    memoryKiB: 64,
    iterations: 1,
    parallelism: 1,
  );

  final int memoryKiB;
  final int iterations;
  final int parallelism;

  Map<String, Object?> toJson() => {
    'm': memoryKiB,
    't': iterations,
    'p': parallelism,
  };

  static Argon2Params fromJson(Map<String, dynamic> json) => Argon2Params(
    memoryKiB: (json['m'] as num).toInt(),
    iterations: (json['t'] as num).toInt(),
    parallelism: (json['p'] as num).toInt(),
  );
}

/// تشفير النسخة الاحتياطية بكلمة مرور يختارها المستخدم (docs/DESIGN.md البند 13):
///
/// ```
/// [8]  "FCBACKUP"
/// [2]  إصدار المغلف (1)
/// [4]  طول الرأس
/// [N]  header.json  {scheme, kdf{m,t,p}, salt, nonce_prefix, chunk_size}
/// [..] قطع AES-256-GCM (ChunkedAead)
/// ```
///
/// المفتاح = Argon2id(كلمة المرور، ملح عشوائي 16 بايت). كلمة المرور لا تُخزَّن
/// في أي مكان، ولا يوجد أي مفتاح داخل الملف؛ نسيانها يعني تعذّر الاستعادة.
class BackupCipher {
  BackupCipher({this.params = Argon2Params.standard, Random? random})
    : _random = random ?? Random.secure();

  static const List<int> magic = [
    0x46, 0x43, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50, // FCBACKUP
  ];
  static const int envelopeVersion = 1;
  static const String scheme = 'argon2id-aes256gcm-chunked';
  static const int defaultChunkSize = 1024 * 1024;
  static const int minPasswordLength = 8;

  final Argon2Params params;
  final Random _random;
  final ChunkedAead _aead = ChunkedAead();

  static Future<bool> isBackup(File file) =>
      ChunkedAead.startsWith(file, magic);

  Future<void> encryptFile({
    required File input,
    required File output,
    required String password,
    int chunkSize = defaultChunkSize,
  }) async {
    if (password.length < minPasswordLength) {
      throw ArgumentError('Password too short');
    }
    final salt = _randomBytes(16);
    final noncePrefix = _randomBytes(8);
    final headerBytes = utf8.encode(
      jsonEncode({
        'scheme': scheme,
        'kdf': params.toJson(),
        'salt': base64.encode(salt),
        'nonce_prefix': base64.encode(noncePrefix),
        'chunk_size': chunkSize,
      }),
    );
    final key = await _deriveKey(password, salt, params);

    final partial = File('${output.path}.partial');
    final sink = partial.openWrite();
    try {
      sink
        ..add(magic)
        ..add(ChunkedAead.uint16(envelopeVersion))
        ..add(ChunkedAead.uint32(headerBytes.length))
        ..add(headerBytes);
      await _aead.encrypt(
        input: input,
        sink: sink,
        key: key,
        noncePrefix: noncePrefix,
        headerBytes: headerBytes,
        chunkSize: chunkSize,
      );
      await sink.flush();
    } finally {
      await sink.close();
    }
    if (await output.exists()) await output.delete();
    await partial.rename(output.path);
  }

  Future<void> decryptFile({
    required File input,
    required File output,
    required String password,
  }) async {
    final raf = await input.open();
    final sink = output.openWrite();
    var ok = false;
    try {
      final (int, List<int>)? start;
      try {
        start = await ChunkedAead.readEnvelopeStart(raf, magic);
      } on ChunkedAeadException catch (e) {
        throw BackupCipherException(e.message);
      }
      if (start == null) {
        throw const BackupCipherException(
          'الملف ليس نسخة احتياطية لهذا التطبيق',
        );
      }
      final (version, headerBytes) = start;
      if (version != envelopeVersion) {
        throw BackupCipherException(
          'إصدار النسخة الاحتياطية ($version) أحدث من هذا التطبيق. حدّث التطبيق.',
        );
      }
      final (kdf, salt, noncePrefix, chunkSize) = _parseHeader(headerBytes);
      final key = await _deriveKey(password, salt, kdf);
      try {
        await _aead.decrypt(
          raf: raf,
          sink: sink,
          key: key,
          noncePrefix: noncePrefix,
          headerBytes: headerBytes,
          chunkSize: chunkSize,
          authFailure: _authFailure,
        );
      } on ChunkedAeadException catch (e) {
        throw BackupCipherException(
          e.message,
          wrongPassword: e.message == _authFailure,
        );
      }
      ok = true;
    } finally {
      await sink.close();
      await raf.close();
      if (!ok && await output.exists()) await output.delete();
    }
  }

  static const _authFailure =
      'كلمة المرور غير صحيحة، أو الملف معدل أو غير مكتمل';

  (Argon2Params, List<int>, List<int>, int) _parseHeader(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final kdf = Argon2Params.fromJson(json['kdf'] as Map<String, dynamic>);
      final salt = base64.decode(json['salt'] as String);
      final prefix = base64.decode(json['nonce_prefix'] as String);
      final chunkSize = (json['chunk_size'] as num).toInt();
      // حدود معقولة حتى لا يفرض ملف مزيف ذاكرة أو زمنًا غير محدود.
      if (json['scheme'] != scheme ||
          prefix.length != 8 ||
          salt.length < 16 ||
          chunkSize <= 0 ||
          chunkSize > 16 * 1024 * 1024 ||
          kdf.memoryKiB < 8 ||
          kdf.memoryKiB > 1024 * 1024 ||
          kdf.iterations < 1 ||
          kdf.iterations > 20 ||
          kdf.parallelism < 1 ||
          kdf.parallelism > 8) {
        throw const FormatException();
      }
      return (kdf, salt, prefix, chunkSize);
    } on FormatException {
      throw const BackupCipherException('رأس النسخة الاحتياطية غير صالح');
    } on TypeError {
      throw const BackupCipherException('رأس النسخة الاحتياطية غير صالح');
    }
  }

  /// في Isolate منفصل: Argon2id مكلف عمدًا ولا يجب أن يجمد الواجهة.
  static Future<SecretKey> _deriveKey(
    String password,
    List<int> salt,
    Argon2Params p,
  ) async {
    final m = p.memoryKiB, t = p.iterations, par = p.parallelism;
    final bytes = await Isolate.run(() async {
      final key = await Argon2id(
        parallelism: par,
        memory: m,
        iterations: t,
        hashLength: 32,
      ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
      return key.extractBytes();
    });
    return SecretKey(bytes);
  }

  List<int> _randomBytes(int n) =>
      List<int>.generate(n, (_) => _random.nextInt(256));
}

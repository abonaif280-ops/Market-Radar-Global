import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'chunked_aead.dart';
import 'key_manager.dart';

class PackageCipherException implements Exception {
  const PackageCipherException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// رأس المغلف المشفر (غير سري): يكفي لاشتقاق المفتاح لدى صاحب المفتاح الخاص فقط.
class EnvelopeHeader {
  const EnvelopeHeader({
    required this.scheme,
    required this.recipientKeyId,
    required this.ephemeralPublicKey,
    required this.salt,
    required this.noncePrefix,
    required this.chunkSize,
  });

  factory EnvelopeHeader.fromJson(Map<String, dynamic> json) => EnvelopeHeader(
    scheme: json['scheme'] as String,
    recipientKeyId: json['recipient_key_id'] as String,
    ephemeralPublicKey: base64.decode(json['ephemeral_public_key'] as String),
    salt: base64.decode(json['salt'] as String),
    noncePrefix: base64.decode(json['nonce_prefix'] as String),
    chunkSize: (json['chunk_size'] as num).toInt(),
  );

  final String scheme;

  /// بصمة مفتاح المستلم (المشرف) لمعرفة المفتاح المطلوب.
  final String recipientKeyId;
  final List<int> ephemeralPublicKey;
  final List<int> salt;
  final List<int> noncePrefix;
  final int chunkSize;

  Map<String, Object?> toJson() => {
    'scheme': scheme,
    'recipient_key_id': recipientKeyId,
    'ephemeral_public_key': base64.encode(ephemeralPublicKey),
    'salt': base64.encode(salt),
    'nonce_prefix': base64.encode(noncePrefix),
    'chunk_size': chunkSize,
  };
}

/// تشفير حزمة `.casepkg` بالمفتاح العام للمشرف (docs/DESIGN.md البند 13):
///
/// ```
/// [8]  "CASEPKG\0"
/// [2]  إصدار المغلف (1)
/// [4]  طول الرأس
/// [N]  header.json
/// [..] قطع مشفرة AES-256-GCM (كل قطعة: نص مشفر + وسم 16 بايت)
/// ```
///
/// - مفتاح مؤقت X25519 لكل حزمة ← سر مشترك مع مفتاح المشرف العام ← HKDF-SHA256.
/// - لا يُكتب أي مفتاح يفتح الحزمة داخلها ولا يُرسل معها.
/// - AAD لكل قطعة = الرأس + رقم القطعة + علامة "آخر قطعة" ← أي تعديل أو حذف
///   أو إعادة ترتيب أو اقتطاع يُكتشف.
class PackageCipher {
  PackageCipher({Random? random}) : _random = random ?? Random.secure();

  static const List<int> magic = [
    0x43,
    0x41,
    0x53,
    0x45,
    0x50,
    0x4B,
    0x47,
    0x00,
  ];
  static const int envelopeVersion = 1;
  static const String scheme = 'x25519-hkdf-sha256-aes256gcm-chunked';
  static const int defaultChunkSize = 1024 * 1024;
  static final List<int> _hkdfInfo = utf8.encode('casepkg-v1');

  final Random _random;
  final X25519 _x25519 = X25519();
  final ChunkedAead _aead = ChunkedAead();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  static Future<bool> isEnvelope(File file) =>
      ChunkedAead.startsWith(file, magic);

  Future<void> encryptFile({
    required File input,
    required File output,
    required List<int> recipientPublicKey,
    int chunkSize = defaultChunkSize,
  }) async {
    final ephemeral = await _x25519.newKeyPair();
    final ephemeralPublic = await ephemeral.extractPublicKey();
    final header = EnvelopeHeader(
      scheme: scheme,
      recipientKeyId: SupervisorPublicKey.fingerprintOf(recipientPublicKey),
      ephemeralPublicKey: ephemeralPublic.bytes,
      salt: _randomBytes(32),
      noncePrefix: _randomBytes(8),
      chunkSize: chunkSize,
    );
    final key = await _deriveKey(
      await _x25519.sharedSecretKey(
        keyPair: ephemeral,
        remotePublicKey: SimplePublicKey(
          recipientPublicKey,
          type: KeyPairType.x25519,
        ),
      ),
      header.salt,
    );
    final headerBytes = utf8.encode(jsonEncode(header.toJson()));

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
        noncePrefix: header.noncePrefix,
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

  /// يقرأ الرأس فقط (لمعرفة المفتاح المطلوب قبل محاولة فك التشفير).
  Future<EnvelopeHeader> readHeader(File file) async {
    final raf = await file.open();
    try {
      return (await _readHeader(raf)).$1;
    } finally {
      await raf.close();
    }
  }

  Future<void> decryptFile({
    required File input,
    required File output,
    required SimpleKeyPair recipientKeyPair,
  }) async {
    final raf = await input.open();
    final sink = output.openWrite();
    var ok = false;
    try {
      final (header, headerBytes) = await _readHeader(raf);
      final ownPublic = await recipientKeyPair.extractPublicKey();
      if (header.recipientKeyId !=
          SupervisorPublicKey.fingerprintOf(ownPublic.bytes)) {
        throw const PackageCipherException(
          'الحزمة مشفرة لمشرف آخر ولا يمكن فتحها على هذا الجهاز',
        );
      }
      final key = await _deriveKey(
        await _x25519.sharedSecretKey(
          keyPair: recipientKeyPair,
          remotePublicKey: SimplePublicKey(
            header.ephemeralPublicKey,
            type: KeyPairType.x25519,
          ),
        ),
        header.salt,
      );
      try {
        await _aead.decrypt(
          raf: raf,
          sink: sink,
          key: key,
          noncePrefix: header.noncePrefix,
          headerBytes: headerBytes,
          chunkSize: header.chunkSize,
          authFailure:
              'فشل التحقق من الحزمة المشفرة: الملف معدل أو تالف أو غير مكتمل',
        );
      } on ChunkedAeadException catch (e) {
        throw PackageCipherException(e.message);
      }
      ok = true;
    } finally {
      await sink.close();
      await raf.close();
      if (!ok && await output.exists()) await output.delete();
    }
  }

  // ------------------------------------------------------------ داخلي

  Future<(EnvelopeHeader, List<int>)> _readHeader(RandomAccessFile raf) async {
    final (int, List<int>)? start;
    try {
      start = await ChunkedAead.readEnvelopeStart(raf, magic);
    } on ChunkedAeadException {
      throw const PackageCipherException('رأس الحزمة المشفرة غير صالح');
    }
    if (start == null) {
      throw const PackageCipherException('ليست حزمة مشفرة صالحة');
    }
    final (version, headerBytes) = start;
    if (version != envelopeVersion) {
      throw PackageCipherException(
        'إصدار التشفير ($version) أحدث من هذا التطبيق. حدّث التطبيق.',
      );
    }
    try {
      final header = EnvelopeHeader.fromJson(
        jsonDecode(utf8.decode(headerBytes)) as Map<String, dynamic>,
      );
      if (header.scheme != scheme ||
          header.noncePrefix.length != 8 ||
          header.chunkSize <= 0) {
        throw const FormatException();
      }
      return (header, headerBytes);
    } on FormatException {
      throw const PackageCipherException('رأس الحزمة المشفرة غير صالح');
    } on TypeError {
      throw const PackageCipherException('رأس الحزمة المشفرة غير صالح');
    }
  }

  Future<SecretKey> _deriveKey(SecretKey shared, List<int> salt) =>
      _hkdf.deriveKey(secretKey: shared, nonce: salt, info: _hkdfInfo);

  List<int> _randomBytes(int n) =>
      List<int>.generate(n, (_) => _random.nextInt(256));
}

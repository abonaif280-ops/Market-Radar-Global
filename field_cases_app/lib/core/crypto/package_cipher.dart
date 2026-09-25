import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

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
  static const int _tagLength = 16;
  static final List<int> _hkdfInfo = utf8.encode('casepkg-v1');

  final Random _random;
  final X25519 _x25519 = X25519();
  final AesGcm _aes = AesGcm.with256bits();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  static Future<bool> isEnvelope(File file) async {
    final raf = await file.open();
    try {
      final head = await raf.read(magic.length);
      if (head.length < magic.length) return false;
      for (var i = 0; i < magic.length; i++) {
        if (head[i] != magic[i]) return false;
      }
      return true;
    } finally {
      await raf.close();
    }
  }

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
    final source = await input.open();
    try {
      sink
        ..add(magic)
        ..add(_uint16(envelopeVersion))
        ..add(_uint32(headerBytes.length))
        ..add(headerBytes);

      final total = await input.length();
      var index = 0;
      var offset = 0;
      // حتى الملف الفارغ يُكتب كقطعة أخيرة واحدة ليُتحقق من سلامته.
      do {
        final length = min(chunkSize, total - offset);
        final plain = await source.read(length);
        offset += length;
        final isLast = offset >= total;
        final box = await _aes.encrypt(
          plain,
          secretKey: key,
          nonce: _nonce(header.noncePrefix, index),
          aad: _aad(headerBytes, index, isLast),
        );
        sink
          ..add(box.cipherText)
          ..add(box.mac.bytes);
        index++;
      } while (offset < total);
      await sink.flush();
    } finally {
      await sink.close();
      await source.close();
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

      final total = await raf.length();
      var position = await raf.position();
      var index = 0;
      final sealedChunk = header.chunkSize + _tagLength;
      var sawLast = false;
      while (position < total) {
        final length = min(sealedChunk, total - position);
        if (length < _tagLength) {
          throw const PackageCipherException('الحزمة المشفرة مقتطعة');
        }
        final sealed = await raf.read(length);
        position += length;
        final isLast = position >= total;
        try {
          final plain = await _aes.decrypt(
            SecretBox(
              sealed.sublist(0, length - _tagLength),
              nonce: _nonce(header.noncePrefix, index),
              mac: Mac(sealed.sublist(length - _tagLength)),
            ),
            secretKey: key,
            aad: _aad(headerBytes, index, isLast),
          );
          sink.add(plain);
        } on SecretBoxAuthenticationError {
          throw const PackageCipherException(
            'فشل التحقق من الحزمة المشفرة: الملف معدل أو تالف أو غير مكتمل',
          );
        }
        sawLast = isLast;
        index++;
      }
      if (!sawLast) {
        throw const PackageCipherException('الحزمة المشفرة لا تحتوي بيانات');
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
    final head = await raf.read(magic.length + 2 + 4);
    if (head.length < magic.length + 6) {
      throw const PackageCipherException('ليست حزمة مشفرة صالحة');
    }
    for (var i = 0; i < magic.length; i++) {
      if (head[i] != magic[i]) {
        throw const PackageCipherException('ليست حزمة مشفرة صالحة');
      }
    }
    final data = ByteData.sublistView(Uint8List.fromList(head));
    final version = data.getUint16(magic.length);
    if (version != envelopeVersion) {
      throw PackageCipherException(
        'إصدار التشفير ($version) أحدث من هذا التطبيق. حدّث التطبيق.',
      );
    }
    final headerLength = data.getUint32(magic.length + 2);
    if (headerLength <= 0 || headerLength > 64 * 1024) {
      throw const PackageCipherException('رأس الحزمة المشفرة غير صالح');
    }
    final headerBytes = await raf.read(headerLength);
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

  List<int> _nonce(List<int> prefix, int index) => [
    ...prefix,
    ..._uint32(index),
  ];

  List<int> _aad(List<int> headerBytes, int index, bool isLast) => [
    ...headerBytes,
    ..._uint32(index),
    isLast ? 1 : 0,
  ];

  List<int> _randomBytes(int n) =>
      List<int>.generate(n, (_) => _random.nextInt(256));

  static List<int> _uint16(int v) => [(v >> 8) & 0xFF, v & 0xFF];

  static List<int> _uint32(int v) => [
    (v >> 24) & 0xFF,
    (v >> 16) & 0xFF,
    (v >> 8) & 0xFF,
    v & 0xFF,
  ];
}

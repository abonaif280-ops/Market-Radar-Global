import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class ChunkedAeadException implements Exception {
  const ChunkedAeadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// تشفير ملفات كبيرة بالبث: AES-256-GCM على قطع ثابتة الحجم.
///
/// مشترك بين حزم `.casepkg` المشفرة والنسخ الاحتياطية:
/// - nonce لكل قطعة = بادئة عشوائية 8 بايت + رقم القطعة (4 بايت).
/// - AAD لكل قطعة = الرأس + رقم القطعة + علامة "آخر قطعة"؛ فأي تعديل أو حذف
///   أو إعادة ترتيب أو اقتطاع يُكتشف.
/// - كل قطعة: نص مشفر + وسم 16 بايت.
class ChunkedAead {
  ChunkedAead();

  static const int tagLength = 16;

  final AesGcm _aes = AesGcm.with256bits();

  /// يكتب القطع المشفرة لـ [input] في [sink] (بعد أن يكتب المستدعي الرأس).
  Future<void> encrypt({
    required File input,
    required IOSink sink,
    required SecretKey key,
    required List<int> noncePrefix,
    required List<int> headerBytes,
    required int chunkSize,
  }) async {
    final source = await input.open();
    try {
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
          nonce: nonce(noncePrefix, index),
          aad: aad(headerBytes, index, isLast),
        );
        sink
          ..add(box.cipherText)
          ..add(box.mac.bytes);
        index++;
      } while (offset < total);
    } finally {
      await source.close();
    }
  }

  /// يقرأ القطع من الموضع الحالي في [raf] حتى نهاية الملف ويكتب النص الأصلي.
  ///
  /// [authFailure] رسالة الخطأ عند فشل التحقق (مفتاح خاطئ أو ملف معدل).
  Future<void> decrypt({
    required RandomAccessFile raf,
    required IOSink sink,
    required SecretKey key,
    required List<int> noncePrefix,
    required List<int> headerBytes,
    required int chunkSize,
    required String authFailure,
  }) async {
    final total = await raf.length();
    var position = await raf.position();
    var index = 0;
    final sealedChunk = chunkSize + tagLength;
    var sawLast = false;
    while (position < total) {
      final length = min(sealedChunk, total - position);
      if (length < tagLength) {
        throw const ChunkedAeadException('الملف المشفر مقتطع');
      }
      final sealed = await raf.read(length);
      position += length;
      final isLast = position >= total;
      try {
        final plain = await _aes.decrypt(
          SecretBox(
            sealed.sublist(0, length - tagLength),
            nonce: nonce(noncePrefix, index),
            mac: Mac(sealed.sublist(length - tagLength)),
          ),
          secretKey: key,
          aad: aad(headerBytes, index, isLast),
        );
        sink.add(plain);
      } on SecretBoxAuthenticationError {
        throw ChunkedAeadException(authFailure);
      }
      sawLast = isLast;
      index++;
    }
    if (!sawLast) {
      throw const ChunkedAeadException('الملف المشفر لا يحتوي بيانات');
    }
  }

  static List<int> nonce(List<int> prefix, int index) => [
    ...prefix,
    ...uint32(index),
  ];

  static List<int> aad(List<int> headerBytes, int index, bool isLast) => [
    ...headerBytes,
    ...uint32(index),
    isLast ? 1 : 0,
  ];

  static List<int> uint16(int v) => [(v >> 8) & 0xFF, v & 0xFF];

  static List<int> uint32(int v) => [
    (v >> 24) & 0xFF,
    (v >> 16) & 0xFF,
    (v >> 8) & 0xFF,
    v & 0xFF,
  ];

  /// يقرأ مقدمة المغلف: [magic] ثم إصدار (2 بايت) ثم طول الرأس (4 بايت) ثم الرأس.
  ///
  /// يعيد (الإصدار، بايتات الرأس)، أو null إذا لم تطابق البداية [magic].
  static Future<(int, List<int>)?> readEnvelopeStart(
    RandomAccessFile raf,
    List<int> magic,
  ) async {
    final head = await raf.read(magic.length + 6);
    if (head.length < magic.length + 6) return null;
    for (var i = 0; i < magic.length; i++) {
      if (head[i] != magic[i]) return null;
    }
    final data = ByteData.sublistView(Uint8List.fromList(head));
    final version = data.getUint16(magic.length);
    final headerLength = data.getUint32(magic.length + 2);
    if (headerLength <= 0 || headerLength > 64 * 1024) {
      throw const ChunkedAeadException('رأس الملف المشفر غير صالح');
    }
    final headerBytes = await raf.read(headerLength);
    if (headerBytes.length != headerLength) {
      throw const ChunkedAeadException('الملف المشفر مقتطع');
    }
    return (version, headerBytes);
  }

  static Future<bool> startsWith(File file, List<int> magic) async {
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
}

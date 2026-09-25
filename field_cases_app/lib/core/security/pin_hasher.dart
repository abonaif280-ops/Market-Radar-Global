import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// تجزئة رمز PIN بخوارزمية Argon2id مع ملح عشوائي. لا يُخزَّن الرمز نفسه أبدًا.
///
/// الصيغة المخزنة: `argon2id$m=19456,t=2,p=1$<salt>$<hash>` (Base64).
class PinHasher {
  PinHasher({
    this.memoryKiB = 19456,
    this.iterations = 2,
    this.parallelism = 1,
    Random? random,
  }) : _random = random ?? Random.secure();

  /// قيم أخف للاختبارات فقط.
  factory PinHasher.fast() => PinHasher(memoryKiB: 64, iterations: 1);

  static const int pinLength = 6;
  static const int _hashLength = 32;

  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final Random _random;

  static bool isValidFormat(String pin) =>
      RegExp('^\\d{$pinLength}\$').hasMatch(pin);

  Future<String> hash(String pin) async {
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final digest = await _derive(pin, salt, memoryKiB, iterations, parallelism);
    return 'argon2id\$m=$memoryKiB,t=$iterations,p=$parallelism'
        '\$${base64.encode(salt)}\$${base64.encode(digest)}';
  }

  Future<bool> verify(String pin, String stored) async {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'argon2id') return false;
    final params = {
      for (final kv in parts[1].split(','))
        kv.split('=')[0]: int.parse(kv.split('=')[1]),
    };
    final salt = base64.decode(parts[2]);
    final expected = base64.decode(parts[3]);
    final actual = await _derive(
      pin,
      salt,
      params['m']!,
      params['t']!,
      params['p']!,
    );
    return _constantTimeEquals(actual, expected);
  }

  /// في Isolate منفصل: Argon2id مكلف عمدًا ولا يجب أن يجمد الواجهة.
  static Future<List<int>> _derive(
    String pin,
    List<int> salt,
    int memory,
    int iterations,
    int parallelism,
  ) {
    return Isolate.run(
      () => _deriveSync(pin, salt, memory, iterations, parallelism),
    );
  }

  static Future<List<int>> _deriveSync(
    String pin,
    List<int> salt,
    int memory,
    int iterations,
    int parallelism,
  ) async {
    final algorithm = Argon2id(
      parallelism: parallelism,
      memory: memory,
      iterations: iterations,
      hashLength: _hashLength,
    );
    final key = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

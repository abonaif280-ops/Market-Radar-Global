import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

import '../../features/settings/data/settings_repository.dart';
import '../security/secret_store.dart';

/// المفتاح العام للمشرف مع بصمته القصيرة للتحقق الحضوري.
class SupervisorPublicKey {
  const SupervisorPublicKey(this.bytes);

  final List<int> bytes;

  String get base64Value => base64.encode(bytes);

  /// بصمة من 12 حرفًا (3 مجموعات) يطابقها الموظف مع المشرف عند استلام المفتاح.
  String get fingerprint => fingerprintOf(bytes);

  static String fingerprintOf(List<int> publicKey) {
    final hex = crypto.sha256
        .convert(publicKey)
        .toString()
        .substring(0, 12)
        .toUpperCase();
    return '${hex.substring(0, 4)}-${hex.substring(4, 8)}-${hex.substring(8)}';
  }
}

/// إدارة مفاتيح المشرف (docs/DESIGN.md البندان 13 و14):
/// زوج X25519 يُولَّد على جهاز المشرف؛ المفتاح الخاص في Keychain/Keystore ولا
/// يغادر الجهاز أبدًا، والمفتاح العام يُسلَّم للموظفين حضوريًا (المرحلة 13).
class KeyManager {
  KeyManager({required this._secrets, required this._settings});

  static const String publicKeySetting = 'supervisor_public_key';

  final SecretStore _secrets;
  final SettingsRepository _settings;
  final X25519 _algorithm = X25519();

  Future<bool> hasSupervisorKeys() async =>
      await _secrets.read(SecretKeys.supervisorPrivateKey) != null;

  /// يولد زوج المفاتيح مرة واحدة ويعيد المفتاح العام.
  Future<SupervisorPublicKey> ensureSupervisorKeys() async {
    final existing = await supervisorPublicKey();
    if (existing != null && await hasSupervisorKeys()) return existing;

    final keyPair = await _algorithm.newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    await _secrets.write(
      SecretKeys.supervisorPrivateKey,
      base64.encode(privateBytes),
    );
    await _settings.set(publicKeySetting, base64.encode(publicKey.bytes));
    return SupervisorPublicKey(publicKey.bytes);
  }

  Future<SupervisorPublicKey?> supervisorPublicKey() async {
    final value = await _settings.get(publicKeySetting);
    return value == null ? null : SupervisorPublicKey(base64.decode(value));
  }
}

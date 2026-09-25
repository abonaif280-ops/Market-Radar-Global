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

  /// زوج مفاتيح المشرف لفك تشفير الحزم الواردة (null إن لم يُفعّل وضع المشرف).
  Future<SimpleKeyPair?> supervisorKeyPair() async {
    final stored = await _secrets.read(SecretKeys.supervisorPrivateKey);
    if (stored == null) return null;
    return _algorithm.newKeyPairFromSeed(base64.decode(stored));
  }

  // --------------------------------------------- لدى الموظف: مفتاح المستلم

  static const String recipientKeySetting = 'recipient_public_key';
  static const String recipientLabelSetting = 'recipient_label';

  /// المفتاح العام للمشرف الذي تُشفَّر له الحزم المصدّرة.
  Future<RecipientKey?> recipientKey() async {
    final value = await _settings.get(recipientKeySetting);
    if (value == null || value.isEmpty) return null;
    return RecipientKey(
      SupervisorPublicKey(base64.decode(value)),
      label: await _settings.get(recipientLabelSetting),
    );
  }

  Future<void> setRecipientKey(RecipientKey key) async {
    await _settings.set(recipientKeySetting, key.publicKey.base64Value);
    await _settings.set(recipientLabelSetting, key.label ?? '');
  }

  Future<void> clearRecipientKey() async {
    await _settings.set(recipientKeySetting, '');
    await _settings.set(recipientLabelSetting, '');
  }
}

/// مفتاح المستلم (المشرف) كما يُنقل عبر رمز QR أو نص يُلصق.
class RecipientKey {
  const RecipientKey(this.publicKey, {this.label});

  static const String _prefix = 'FCKEY1';

  final SupervisorPublicKey publicKey;

  /// اسم الجهة/المشرف للعرض فقط.
  final String? label;

  String get fingerprint => publicKey.fingerprint;

  /// `FCKEY1|<base64>|<label>`
  String toPayload() =>
      '$_prefix|${publicKey.base64Value}|${(label ?? '').replaceAll('|', ' ')}';

  /// يعيد null إذا لم يكن النص مفتاحًا صالحًا (32 بايت X25519).
  static RecipientKey? tryParse(String payload) {
    final parts = payload.trim().split('|');
    if (parts.length < 2 || parts[0] != _prefix) return null;
    try {
      final bytes = base64.decode(parts[1]);
      if (bytes.length != 32) return null;
      final label = parts.length > 2 ? parts.sublist(2).join('|').trim() : '';
      return RecipientKey(
        SupervisorPublicKey(bytes),
        label: label.isEmpty ? null : label,
      );
    } on FormatException {
      return null;
    }
  }
}

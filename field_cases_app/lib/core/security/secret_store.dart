import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// تخزين الأسرار (تجزئة PIN، المفاتيح الخاصة) خارج قاعدة البيانات.
///
/// على الجهاز: Keychain في iOS و Keystore في Android عبر flutter_secure_storage.
abstract interface class SecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

abstract final class SecretKeys {
  static const supervisorPinHash = 'supervisor_pin_hash';
  static const supervisorPrivateKey = 'supervisor_x25519_private';
}

class DeviceSecretStore implements SecretStore {
  const DeviceSecretStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    // الأسرار متاحة فقط بعد أول فتح للجهاز، ولا تنتقل لجهاز آخر مع نسخ iCloud.
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// للاختبارات فقط.
class MemorySecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

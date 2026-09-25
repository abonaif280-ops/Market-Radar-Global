import 'package:local_auth/local_auth.dart';

import '../../../core/db/audit_logger.dart';
import '../../../core/security/pin_attempt_guard.dart';
import '../../../core/security/pin_hasher.dart';
import '../../../core/security/secret_store.dart';
import '../../settings/data/settings_repository.dart';

/// التحقق الحيوي (بصمة الوجه/الإصبع). مجرد في واجهة ليُستبدل في الاختبارات.
abstract interface class BiometricAuth {
  Future<bool> isAvailable();

  Future<bool> authenticate(String reason);
}

class DeviceBiometricAuth implements BiometricAuth {
  DeviceBiometricAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on Exception {
      // إلغاء أو قفل البصمة من النظام: الرجوع لرمز PIN.
      return false;
    }
  }
}

/// قفل التطبيق عند الفتح وبعد البقاء في الخلفية.
///
/// - رمز PIN مستقل عن رمز المشرف، يُخزَّن كتجزئة Argon2id في Keychain/Keystore.
/// - البصمة اختيارية ومريحة فقط؛ رمز PIN هو البديل الدائم.
/// - 5 محاولات خاطئة ← إيقاف مؤقت 30 ثانية.
class AppLockService {
  AppLockService({
    required this._settings,
    required this._secrets,
    required this._hasher,
    required this._biometric,
    required this._audit,
    DateTime Function()? clock,
  }) : _guard = PinAttemptGuard(clock: clock);

  final SettingsRepository _settings;
  final SecretStore _secrets;
  final PinHasher _hasher;
  final BiometricAuth _biometric;
  final AuditLogger _audit;
  final PinAttemptGuard _guard;

  Stream<bool> watchEnabled() =>
      _settings.watch(SettingKeys.appLockEnabled).map((v) => v == 'true');

  Future<bool> isEnabled() async =>
      await _settings.get(SettingKeys.appLockEnabled) == 'true' &&
      await _secrets.read(SecretKeys.appLockPinHash) != null;

  Future<bool> biometricEnabled() async =>
      await _settings.get(SettingKeys.appLockBiometric) == 'true';

  Future<bool> biometricAvailable() => _biometric.isAvailable();

  Future<void> enable(String pin, {required bool useBiometric}) async {
    if (!PinHasher.isValidFormat(pin)) {
      throw ArgumentError('PIN must be ${PinHasher.pinLength} digits');
    }
    await _secrets.write(SecretKeys.appLockPinHash, await _hasher.hash(pin));
    await _settings.set(SettingKeys.appLockBiometric, '$useBiometric');
    await _settings.set(SettingKeys.appLockEnabled, 'true');
    await _log({'enabled': true, 'biometric': useBiometric});
  }

  Future<PinCheck> disable(String pin) async {
    final check = await verifyPin(pin);
    if (check is! PinAccepted) return check;
    await _settings.set(SettingKeys.appLockEnabled, 'false');
    await _secrets.delete(SecretKeys.appLockPinHash);
    await _log({'enabled': false});
    return check;
  }

  Future<PinCheck> changePin(String currentPin, String newPin) async {
    if (!PinHasher.isValidFormat(newPin)) {
      throw ArgumentError('PIN must be ${PinHasher.pinLength} digits');
    }
    final check = await verifyPin(currentPin);
    if (check is! PinAccepted) return check;
    await _secrets.write(SecretKeys.appLockPinHash, await _hasher.hash(newPin));
    await _log({'pin_changed': true});
    return check;
  }

  Future<void> setBiometric(bool value) async {
    await _settings.set(SettingKeys.appLockBiometric, '$value');
    await _log({'biometric': value});
  }

  Future<PinCheck> verifyPin(String pin) => _guard.check(() async {
    final stored = await _secrets.read(SecretKeys.appLockPinHash);
    return stored != null && await _hasher.verify(pin, stored);
  });

  /// يعيد true فقط إذا كانت البصمة مفعلة ونجح التحقق.
  Future<bool> unlockWithBiometric() async {
    if (!await biometricEnabled()) return false;
    return _biometric.authenticate('افتح تطبيق الحالات الميدانية');
  }

  Future<void> _log(Map<String, Object?> details) async => _audit.log(
    action: AuditActions.appLockChanged,
    entityType: 'device',
    details: details,
    actor: await _settings.get(SettingKeys.userCode),
  );
}

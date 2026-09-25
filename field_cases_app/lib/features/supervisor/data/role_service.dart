import '../../../core/crypto/key_manager.dart';
import '../../../core/db/audit_logger.dart';
import '../../../core/security/pin_attempt_guard.dart';
import '../../../core/security/pin_hasher.dart';
import '../../../core/security/secret_store.dart';
import '../../cases/domain/case_enums.dart';
import '../../settings/data/settings_repository.dart';

sealed class RoleChangeResult {
  const RoleChangeResult();
}

class RoleChanged extends RoleChangeResult {
  const RoleChanged();
}

class WrongPin extends RoleChangeResult {
  const WrongPin(this.remainingAttempts);

  final int remainingAttempts;
}

class LockedOut extends RoleChangeResult {
  const LockedOut(this.retryAfter);

  final Duration retryAfter;
}

/// التحويل بين وضعي الموظف والمشرف.
///
/// ملاحظة أمنية: الدور بحد ذاته حماية على مستوى الواجهة؛ الحماية الفعلية للحزم
/// هي التشفير بالمفتاح العام للمشرف (المرحلة 13). لذلك يُولَّد زوج مفاتيح المشرف
/// عند أول تفعيل لوضع المشرف.
class RoleService {
  RoleService({
    required this._settings,
    required this._secrets,
    required this._hasher,
    required this._keys,
    required this._audit,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const int maxAttempts = 5;
  static const Duration lockDuration = Duration(seconds: 30);

  final SettingsRepository _settings;
  final SecretStore _secrets;
  final PinHasher _hasher;
  final KeyManager _keys;
  final AuditLogger _audit;
  final DateTime Function() _clock;

  late final PinAttemptGuard _guard = PinAttemptGuard(
    maxAttempts: maxAttempts,
    lockDuration: lockDuration,
    clock: _clock,
  );

  Future<bool> hasSupervisorPin() async =>
      await _secrets.read(SecretKeys.supervisorPinHash) != null;

  /// أول تفعيل: يحفظ تجزئة الرمز ويولد مفاتيح المشرف.
  Future<void> setupSupervisor(String pin) async {
    if (!PinHasher.isValidFormat(pin)) {
      throw ArgumentError('PIN must be ${PinHasher.pinLength} digits');
    }
    if (await hasSupervisorPin()) {
      throw StateError('Supervisor PIN already set');
    }
    await _secrets.write(SecretKeys.supervisorPinHash, await _hasher.hash(pin));
    final publicKey = await _keys.ensureSupervisorKeys();
    await _setRole(UserRole.supervisor, {
      'key_fingerprint': publicKey.fingerprint,
    });
  }

  Future<RoleChangeResult> switchToSupervisor(String pin) async {
    final check = await _verify(pin);
    if (check is! RoleChanged) return check;
    await _keys.ensureSupervisorKeys();
    await _setRole(UserRole.supervisor, const {});
    return check;
  }

  /// العودة لوضع الموظف لا تحتاج رمزًا (صلاحيات أقل) ولا تحذف أي بيانات.
  Future<void> switchToEmployee() => _setRole(UserRole.employee, const {});

  Future<RoleChangeResult> changePin(String currentPin, String newPin) async {
    if (!PinHasher.isValidFormat(newPin)) {
      throw ArgumentError('PIN must be ${PinHasher.pinLength} digits');
    }
    final check = await _verify(currentPin);
    if (check is! RoleChanged) return check;
    await _secrets.write(
      SecretKeys.supervisorPinHash,
      await _hasher.hash(newPin),
    );
    return check;
  }

  Future<RoleChangeResult> _verify(String pin) async {
    final result = await _guard.check(() async {
      final stored = await _secrets.read(SecretKeys.supervisorPinHash);
      return stored != null && await _hasher.verify(pin, stored);
    });
    return switch (result) {
      PinAccepted() => const RoleChanged(),
      PinRejected(:final remainingAttempts) => WrongPin(remainingAttempts),
      PinLockedOut(:final retryAfter) => LockedOut(retryAfter),
    };
  }

  Future<void> _setRole(UserRole role, Map<String, Object?> details) async {
    await _settings.setRole(role);
    await _audit.log(
      action: AuditActions.roleChanged,
      entityType: 'device',
      details: {'role': role.name, ...details},
      actor: await _settings.get(SettingKeys.userCode),
    );
  }
}

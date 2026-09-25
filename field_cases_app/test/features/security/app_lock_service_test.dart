import 'package:drift/native.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/db/audit_logger.dart';
import 'package:field_cases/core/security/pin_attempt_guard.dart';
import 'package:field_cases/core/security/pin_hasher.dart';
import 'package:field_cases/core/security/secret_store.dart';
import 'package:field_cases/features/security/data/app_lock_service.dart';
import 'package:field_cases/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBiometric implements BiometricAuth {
  bool available = true;
  bool succeed = true;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return succeed;
  }
}

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late MemorySecretStore secrets;
  late FakeBiometric biometric;
  late AppLockService lock;
  var now = DateTime(2026, 9, 25, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    secrets = MemorySecretStore();
    biometric = FakeBiometric();
    now = DateTime(2026, 9, 25, 10);
    lock = AppLockService(
      settings: settings,
      secrets: secrets,
      hasher: PinHasher.fast(),
      biometric: biometric,
      audit: AuditLogger(db),
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  test('disabled by default', () async {
    expect(await lock.isEnabled(), isFalse);
    expect(await lock.unlockWithBiometric(), isFalse);
  });

  test('enable stores only an Argon2id hash in secure storage', () async {
    await lock.enable('246810', useBiometric: false);
    expect(await lock.isEnabled(), isTrue);
    final stored = secrets.values[SecretKeys.appLockPinHash]!;
    expect(stored, startsWith('argon2id\$'));
    expect(stored, isNot(contains('246810')));
    final rows = await db.select(db.appSettings).get();
    expect(rows.map((r) => r.value).join(), isNot(contains('246810')));
    expect(await lock.verifyPin('246810'), isA<PinAccepted>());
    expect(await lock.verifyPin('111111'), isA<PinRejected>());
  });

  test('five wrong PINs lock input for 30 seconds', () async {
    await lock.enable('246810', useBiometric: false);
    for (var i = 0; i < 4; i++) {
      expect(await lock.verifyPin('000000'), isA<PinRejected>());
    }
    expect(await lock.verifyPin('000000'), isA<PinLockedOut>());
    // حتى الرمز الصحيح مرفوض أثناء الإيقاف.
    expect(await lock.verifyPin('246810'), isA<PinLockedOut>());
    now = now.add(const Duration(seconds: 31));
    expect(await lock.verifyPin('246810'), isA<PinAccepted>());
  });

  test('disable and change PIN require the current PIN', () async {
    await lock.enable('246810', useBiometric: false);
    expect(await lock.changePin('000000', '135790'), isA<PinRejected>());
    expect(await lock.changePin('246810', '135790'), isA<PinAccepted>());
    expect(await lock.verifyPin('135790'), isA<PinAccepted>());

    expect(await lock.disable('246810'), isA<PinRejected>());
    expect(await lock.isEnabled(), isTrue);
    expect(await lock.disable('135790'), isA<PinAccepted>());
    expect(await lock.isEnabled(), isFalse);
    expect(secrets.values.containsKey(SecretKeys.appLockPinHash), isFalse);
  });

  test('biometric unlock only when the user turned it on', () async {
    await lock.enable('246810', useBiometric: false);
    expect(await lock.unlockWithBiometric(), isFalse);
    expect(biometric.prompts, 0);

    await lock.setBiometric(true);
    expect(await lock.unlockWithBiometric(), isTrue);
    biometric.succeed = false;
    expect(await lock.unlockWithBiometric(), isFalse);
  });

  test('changes are written to the audit log', () async {
    await lock.enable('246810', useBiometric: true);
    await lock.disable('246810');
    final entries = await AuditLogger(db).recent();
    expect(
      entries.where((e) => e.action == AuditActions.appLockChanged),
      hasLength(2),
    );
  });
}

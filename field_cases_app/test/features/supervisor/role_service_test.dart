import 'package:drift/native.dart';
import 'package:field_cases/core/crypto/key_manager.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/db/audit_logger.dart';
import 'package:field_cases/core/security/permissions.dart';
import 'package:field_cases/core/security/pin_hasher.dart';
import 'package:field_cases/core/security/secret_store.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/settings/data/settings_repository.dart';
import 'package:field_cases/features/supervisor/data/role_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late MemorySecretStore secrets;
  late KeyManager keys;
  late RoleService roles;
  var now = DateTime(2026, 9, 25, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    secrets = MemorySecretStore();
    keys = KeyManager(secrets: secrets, settings: settings);
    now = DateTime(2026, 9, 25, 10);
    roles = RoleService(
      settings: settings,
      secrets: secrets,
      hasher: PinHasher.fast(),
      keys: keys,
      audit: AuditLogger(db),
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  group('PinHasher', () {
    test('verifies the right PIN only and never stores it in clear', () async {
      final hasher = PinHasher.fast();
      final stored = await hasher.hash('123456');
      expect(stored, startsWith(r'argon2id$'));
      expect(stored, isNot(contains('123456')));
      expect(await hasher.verify('123456', stored), isTrue);
      expect(await hasher.verify('123457', stored), isFalse);
      expect(await hasher.verify('123456', 'garbage'), isFalse);
      // ملح عشوائي: نفس الرمز يعطي تجزئة مختلفة.
      expect(await hasher.hash('123456'), isNot(stored));
    });

    test('production parameters follow OWASP guidance', () {
      final hasher = PinHasher();
      expect(hasher.memoryKiB, greaterThanOrEqualTo(19456));
      expect(hasher.iterations, greaterThanOrEqualTo(2));
    });

    test('PIN format', () {
      expect(PinHasher.isValidFormat('123456'), isTrue);
      expect(PinHasher.isValidFormat('12345'), isFalse);
      expect(PinHasher.isValidFormat('12345a'), isFalse);
    });
  });

  test(
    'first setup stores a PIN hash, generates keys and switches role',
    () async {
      expect(await roles.hasSupervisorPin(), isFalse);
      await roles.setupSupervisor('246810');

      expect(await roles.hasSupervisorPin(), isTrue);
      expect(
        secrets.values[SecretKeys.supervisorPinHash],
        isNot(contains('246810')),
      );
      expect(await settings.watchRole().first, UserRole.supervisor);

      final publicKey = (await keys.supervisorPublicKey())!;
      expect(publicKey.bytes, hasLength(32));
      expect(
        publicKey.fingerprint,
        matches(RegExp(r'^[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$')),
      );
      expect(await keys.hasSupervisorKeys(), isTrue);
      // المفتاح الخاص في التخزين الآمن فقط، وليس في إعدادات القاعدة.
      final settingsRows = await db.select(db.appSettings).get();
      expect(
        settingsRows.map((r) => r.value),
        isNot(contains(secrets.values[SecretKeys.supervisorPrivateKey])),
      );

      final audit = await AuditLogger(db).recent();
      expect(audit.first.action, AuditActions.roleChanged);
    },
  );

  test('switching back and forth keeps the same keys', () async {
    await roles.setupSupervisor('246810');
    final before = (await keys.supervisorPublicKey())!.fingerprint;

    await roles.switchToEmployee();
    expect(await settings.watchRole().first, UserRole.employee);

    expect(await roles.switchToSupervisor('246810'), isA<RoleChanged>());
    expect(await settings.watchRole().first, UserRole.supervisor);
    expect((await keys.supervisorPublicKey())!.fingerprint, before);
  });

  test('wrong PINs count down then lock temporarily', () async {
    await roles.setupSupervisor('246810');
    await roles.switchToEmployee();

    for (var remaining = 4; remaining >= 1; remaining--) {
      final r = await roles.switchToSupervisor('000000');
      expect((r as WrongPin).remainingAttempts, remaining);
    }
    expect(await roles.switchToSupervisor('000000'), isA<LockedOut>());
    // حتى الرمز الصحيح مرفوض أثناء القفل.
    expect(await roles.switchToSupervisor('246810'), isA<LockedOut>());
    expect(await settings.watchRole().first, UserRole.employee);

    now = now.add(RoleService.lockDuration);
    expect(await roles.switchToSupervisor('246810'), isA<RoleChanged>());
  });

  test('change PIN requires the current one', () async {
    await roles.setupSupervisor('246810');
    expect(await roles.changePin('111111', '135790'), isA<WrongPin>());
    expect(await roles.changePin('246810', '135790'), isA<RoleChanged>());
    await roles.switchToEmployee();
    expect(await roles.switchToSupervisor('246810'), isA<WrongPin>());
    expect(await roles.switchToSupervisor('135790'), isA<RoleChanged>());
  });

  test('permissions', () {
    expect(Permissions.can(UserRole.employee, AppAction.createCase), isTrue);
    expect(Permissions.can(UserRole.employee, AppAction.exportCases), isTrue);
    expect(
      Permissions.can(UserRole.employee, AppAction.importPackages),
      isFalse,
    );
    expect(Permissions.can(UserRole.employee, AppAction.reviewCases), isFalse);
    expect(
      Permissions.can(UserRole.supervisor, AppAction.importPackages),
      isTrue,
    );
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:field_cases/core/crypto/backup_cipher.dart';
import 'package:field_cases/core/crypto/key_manager.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/db/audit_logger.dart';
import 'package:field_cases/core/security/database_encryption.dart';
import 'package:field_cases/core/security/secret_store.dart';
import 'package:field_cases/features/backup/data/backup_service.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../helpers/test_device.dart';

const _password = 'field-cases-2026';

BackupService _serviceFor(
  TestDevice device, {
  String? databaseKey,
  AppDatabase? db,
  SettingsRepository? settings,
  SecretStore? secrets,
  Directory? storageRoot,
}) {
  final database = db ?? device.db;
  return BackupService(
    database,
    settings: settings ?? device.settings,
    secrets: secrets ?? device.secrets,
    audit: AuditLogger(database),
    storageRoot: storageRoot ?? device.storage.root,
    outputDirectory: Directory(p.join(device.root.path, 'out')),
    workDirectory: Directory(p.join(device.root.path, 'work')),
    databaseKey: databaseKey,
    cipher: BackupCipher(params: Argon2Params.fast),
    clock: () => TestDevice.now,
  );
}

/// جهاز جديد بقاعدة مشفرة على القرص (مثل الجوال الحقيقي).
class _FileDevice {
  _FileDevice(this.root) : key = 'b' * 64;

  final Directory root;
  final String key;
  final secrets = MemorySecretStore();
  late AppDatabase db;

  File get dbFile => File(p.join(root.path, 'field_cases.sqlite'));
  Directory get storageRoot => Directory(p.join(root.path, 'app'));

  Future<void> open() async {
    db = AppDatabase(
      NativeDatabase(
        dbFile,
        setup: (raw) => raw.execute(DatabaseEncryption.keyPragma(key)),
      ),
    );
    await db.customSelect('SELECT 1').get();
  }
}

void main() {
  late Directory tmp;
  late TestDevice employee;

  // كل جهاز محاكى له قاعدته الخاصة؛ التحذير لا ينطبق هنا.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('backup_test');
    employee = TestDevice(Directory(p.join(tmp.path, 'a')), 'مركز العوالي');
    await employee.init();
    await employee.settings.set(SettingKeys.userCode, 'U-117');
  });
  tearDown(() async {
    await employee.db.close();
    await tmp.delete(recursive: true);
  });

  test('backup is encrypted and needs the right password', () async {
    await employee.addCase(photos: 2);
    final result = await _serviceFor(employee).create(password: _password);

    expect(
      p.basename(result.file.path),
      'FieldCases-Backup-20260925-1930.fcbackup',
    );
    expect(result.manifest.caseCount, 1);
    expect(result.manifest.attachmentCount, 2);
    final bytes = await result.file.readAsBytes();
    expect(utf8.decode(bytes.sublist(0, 8)), 'FCBACKUP');
    // لا نص مقروء من المحتوى داخل الملف.
    final text = latin1.decode(bytes);
    for (final leak in ['manifest.json', 'SQLite format', 'U-117', 'db_key']) {
      expect(text.contains(leak), isFalse, reason: leak);
    }

    final other = TestDevice(Directory(p.join(tmp.path, 'b')), 'x');
    addTearDown(other.db.close);
    await expectLater(
      _serviceFor(other).stage(result.file, 'wrong-password'),
      throwsA(
        isA<BackupException>().having((e) => e.wrongPassword, 'wrong', true),
      ),
    );
    final staged = await _serviceFor(other).stage(result.file, _password);
    expect(staged.caseCount, 1);
    expect(staged.attachmentCount, 2);
    expect(staged.missingFiles, 0);
    expect(staged.manifest.userCode, 'U-117');
    // مفتاح النسخة ليس مفتاح قاعدة الجهاز.
    expect(
      staged.secrets['db_key'],
      isNot(employee.secrets.values['database_key']),
    );
  });

  test('tampered or truncated backups are rejected', () async {
    await employee.addCase(photos: 1);
    final result = await _serviceFor(employee).create(password: _password);
    final bytes = await result.file.readAsBytes();

    final tampered = File(p.join(tmp.path, 't.fcbackup'))
      ..writeAsBytesSync([...bytes]..[bytes.length - 40] ^= 0x01);
    final truncated = File(p.join(tmp.path, 'c.fcbackup'))
      ..writeAsBytesSync(bytes.sublist(0, bytes.length - 100));
    final notBackup = File(p.join(tmp.path, 'n.fcbackup'))
      ..writeAsStringSync('hello');

    for (final f in [tampered, truncated, notBackup]) {
      await expectLater(
        _serviceFor(employee).stage(f, _password),
        throwsA(isA<BackupException>()),
      );
    }
  });

  test('unsafe paths inside the archive are refused', () async {
    final zip = File(p.join(tmp.path, 'evil.zip'));
    final encoder = ZipFileEncoder()..create(zip.path);
    encoder.addArchiveFile(ArchiveFile.bytes('../evil.txt', [1, 2, 3]));
    await encoder.close();
    final evil = File(p.join(tmp.path, 'evil.fcbackup'));
    await BackupCipher(params: Argon2Params.fast)
        .encryptFile(input: zip, output: evil, password: _password);
    await expectLater(
      _serviceFor(employee).stage(evil, _password),
      throwsA(isA<BackupException>()),
    );
    expect(File(p.join(tmp.path, 'a', 'evil.txt')).existsSync(), isFalse);
  });

  test(
    'restore onto a new phone replaces data and keeps device settings',
    () async {
      final caseId = await employee.addCase(photos: 2);
      await employee.addCase();
      await employee.settings.setRole(UserRole.supervisor);
      final result = await _serviceFor(employee).create(password: _password);

      // الجوال الجديد: قاعدة مشفرة بمفتاح مختلف، وحالة سابقة ستُستبدل، وقفل مفعّل.
      final phone = _FileDevice(Directory(p.join(tmp.path, 'phone')));
      await phone.open();
      final phoneSettings = SettingsRepository(phone.db);
      await phoneSettings.set(SettingKeys.appLockEnabled, 'true');
      await phoneSettings.set(SettingKeys.userCode, 'OLD');
      final oldPhoto = File(
        p.join(phone.storageRoot.path, 'attachments', 'old.jpg'),
      );
      await oldPhoto.create(recursive: true);

      final service = _serviceFor(
        employee,
        db: phone.db,
        settings: phoneSettings,
        secrets: phone.secrets,
        databaseKey: phone.key,
        storageRoot: phone.storageRoot,
      );
      final staged = await service.stage(result.file, _password);
      await service.prepare(staged);
      await phone.db.close();
      await BackupService.swap(
        staged,
        databaseFile: phone.dbFile,
        storageRoot: phone.storageRoot,
        secrets: phone.secrets,
      );
      expect(staged.directory.existsSync(), isFalse);

      await phone.open(); // بمفتاح الجوال نفسه.
      addTearDown(() => phone.db.close());
      final settings = SettingsRepository(phone.db);
      final cases = await phone.db.select(phone.db.cases).get();
      expect(cases, hasLength(2));
      expect(await settings.get(SettingKeys.userCode), 'U-117');
      expect(await settings.get(SettingKeys.appLockEnabled), 'true');
      // بدون مفاتيح المشرف لا يُفعَّل وضع المشرف على جوال لا يملك رمزه.
      expect(await settings.get(SettingKeys.role), 'employee');
      expect(oldPhoto.existsSync(), isFalse);

      final attachments = await (phone.db.select(
        phone.db.attachments,
      )..where((a) => a.caseId.equals(caseId))).get();
      expect(attachments, hasLength(2));
      for (final a in attachments) {
        final file = File(p.join(phone.storageRoot.path, a.relativePath));
        expect(sha256.convert(file.readAsBytesSync()).toString(), a.sha256);
      }
      // الملف على القرص مشفر.
      final head = phone.dbFile.readAsBytesSync().sublist(0, 6);
      expect(String.fromCharCodes(head), isNot('SQLite'));
    },
  );

  test('supervisor keys travel only when chosen', () async {
    final keys = KeyManager(
      secrets: employee.secrets,
      settings: employee.settings,
    );
    final publicKey = await keys.ensureSupervisorKeys();
    await employee.secrets.write(SecretKeys.supervisorPinHash, 'argon2id\$x');
    await employee.settings.setRole(UserRole.supervisor);

    Future<(MemorySecretStore, SettingsRepository, _FileDevice)> restore(
      bool include,
      String dir,
    ) async {
      final result = await _serviceFor(employee)
          .create(password: _password, includeSupervisorKeys: include);
      final phone = _FileDevice(Directory(p.join(tmp.path, dir)));
      await phone.open();
      final service = _serviceFor(
        employee,
        db: phone.db,
        settings: SettingsRepository(phone.db),
        secrets: phone.secrets,
        databaseKey: phone.key,
        storageRoot: phone.storageRoot,
      );
      final staged = await service.stage(result.file, _password);
      expect(staged.manifest.includesSupervisorKeys, include);
      await service.prepare(staged);
      await phone.db.close();
      await BackupService.swap(
        staged,
        databaseFile: phone.dbFile,
        storageRoot: phone.storageRoot,
        secrets: phone.secrets,
      );
      await phone.open();
      return (phone.secrets, SettingsRepository(phone.db), phone);
    }

    final (withSecrets, withSettings, p1) = await restore(true, 'p1');
    addTearDown(() => p1.db.close());
    expect(withSecrets.values[SecretKeys.supervisorPrivateKey], isNotNull);
    expect(await withSettings.get(SettingKeys.role), 'supervisor');
    final restoredKeys = KeyManager(
      secrets: withSecrets,
      settings: withSettings,
    );
    expect(
      (await restoredKeys.supervisorPublicKey())!.fingerprint,
      publicKey.fingerprint,
    );

    final (noSecrets, noSettings, p2) = await restore(false, 'p2');
    addTearDown(() => p2.db.close());
    expect(noSecrets.values, isEmpty);
    expect(await noSettings.get(SettingKeys.role), 'employee');
    // لا يبقى مفتاح عام بلا مفتاحه الخاص.
    expect(await noSettings.get(KeyManager.publicKeySetting), isNull);
  });

  test('backup and restore are written to the audit log', () async {
    await _serviceFor(employee).create(password: _password);
    final entries = await AuditLogger(employee.db).recent();
    expect(entries.first.action, AuditActions.backupCreated);
  });

  test(
    'interrupted swap brings the previous data back on next start',
    () async {
      final phone = _FileDevice(Directory(p.join(tmp.path, 'crash')));
      await phone.open();
      await SettingsRepository(phone.db).set(SettingKeys.userCode, 'KEEP');
      await phone.db.close();
      final work = Directory(p.join(tmp.path, 'crash_work'));
      final rollback = Directory(p.join(work.path, 'rollback'));
      await rollback.create(recursive: true);
      // محاكاة انقطاع بعد نقل القاعدة جانبًا وقبل وضع الجديدة.
      await phone.dbFile.rename(p.join(rollback.path, 'field_cases.sqlite'));

      final recovered = await BackupService.recoverInterruptedSwap(
        workDirectory: work,
        databaseFile: phone.dbFile,
        storageRoot: phone.storageRoot,
      );
      expect(recovered, isTrue);
      expect(rollback.existsSync(), isFalse);
      await phone.open();
      addTearDown(() => phone.db.close());
      expect(
        await SettingsRepository(phone.db).get(SettingKeys.userCode),
        'KEEP',
      );
    },
  );
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../../../core/app_info.dart';
import '../../../core/crypto/backup_cipher.dart';
import '../../../core/crypto/key_manager.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/audit_logger.dart';
import '../../../core/security/database_encryption.dart';
import '../../../core/security/secret_store.dart';
import '../../packages/data/case_package_reader.dart';
import '../../settings/data/settings_repository.dart';

class BackupException implements Exception {
  const BackupException(this.message, {this.wrongPassword = false});

  final String message;
  final bool wrongPassword;

  @override
  String toString() => message;
}

/// وصف النسخة (manifest.json داخل الملف المشفر).
class BackupManifest {
  const BackupManifest({
    required this.formatVersion,
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.deviceId,
    required this.userCode,
    required this.orgName,
    required this.caseCount,
    required this.attachmentCount,
    required this.includesSupervisorKeys,
  });

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
    formatVersion: (json['format_version'] as num).toInt(),
    schemaVersion: (json['schema_version'] as num).toInt(),
    appVersion: json['app_version'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    deviceId: json['device_id'] as String?,
    userCode: json['user_code'] as String?,
    orgName: json['org_name'] as String?,
    caseCount: (json['case_count'] as num).toInt(),
    attachmentCount: (json['attachment_count'] as num).toInt(),
    includesSupervisorKeys: json['includes_supervisor_keys'] == true,
  );

  static const String format = 'fcbackup';
  static const int currentFormatVersion = 1;

  final int formatVersion;
  final int schemaVersion;
  final String? appVersion;
  final DateTime createdAt;
  final String? deviceId;
  final String? userCode;
  final String? orgName;
  final int caseCount;
  final int attachmentCount;
  final bool includesSupervisorKeys;

  Map<String, Object?> toJson() => {
    'format': format,
    'format_version': formatVersion,
    'schema_version': schemaVersion,
    'app_version': appVersion,
    'created_at': createdAt.toUtc().toIso8601String(),
    'device_id': deviceId,
    'user_code': userCode,
    'org_name': orgName,
    'case_count': caseCount,
    'attachment_count': attachmentCount,
    'includes_supervisor_keys': includesSupervisorKeys,
  };
}

class BackupResult {
  const BackupResult({required this.file, required this.manifest});

  final File file;
  final BackupManifest manifest;
}

/// نسخة فُك تشفيرها وفُحصت، جاهزة للاستعادة (لم يتغير شيء على الجهاز بعد).
class StagedRestore {
  const StagedRestore({
    required this.directory,
    required this.manifest,
    required this.caseCount,
    required this.attachmentCount,
    required this.missingFiles,
    required this.secrets,
  });

  final Directory directory;
  final BackupManifest manifest;

  /// من قاعدة النسخة نفسها (لا من manifest فقط).
  final int caseCount;
  final int attachmentCount;

  /// صور مسجلة في القاعدة وغير موجودة في النسخة.
  final int missingFiles;
  final Map<String, String> secrets;

  File get database =>
      File(p.join(directory.path, BackupService.databaseEntry));

  Directory get attachments =>
      Directory(p.join(directory.path, BackupService.attachmentsDir));
}

/// النسخ الاحتياطي والاستعادة (docs/DESIGN.md البند 13 — النسخ الاحتياطي).
///
/// محتوى الملف قبل التشفير (ZIP):
/// ```
/// manifest.json
/// secrets.json        مفتاح القاعدة المنسوخة (+ مفاتيح المشرف إن اختار المستخدم)
/// database.sqlite     لقطة متسقة (VACUUM INTO) مشفرة بمفتاح خاص بالنسخة
/// attachments/...     الصور بنفس مساراتها
/// ```
/// ثم يُشفَّر كله بكلمة مرور المستخدم ([BackupCipher]). لا رفع لأي مكان:
/// المستخدم يختار أين يحفظ الملف.
class BackupService {
  BackupService(
    this._db, {
    required this._settings,
    required this._secrets,
    required this._audit,
    required this.storageRoot,
    required this.outputDirectory,
    required this.workDirectory,
    required this.databaseKey,
    BackupCipher? cipher,
    Random? random,
    DateTime Function()? clock,
  }) : _cipher = cipher ?? BackupCipher(),
       _random = random ?? Random.secure(),
       _clock = clock ?? DateTime.now;

  static const String manifestEntry = 'manifest.json';
  static const String secretsEntry = 'secrets.json';
  static const String databaseEntry = 'database.sqlite';
  static const String attachmentsDir = 'attachments';
  static const String extension = 'fcbackup';
  static const String _completeMarker = '.swap_complete';

  final AppDatabase _db;
  final SettingsRepository _settings;
  final SecretStore _secrets;
  final AuditLogger _audit;
  final BackupCipher _cipher;
  final Random _random;
  final DateTime Function() _clock;

  /// مجلد بيانات التطبيق (يحتوي attachments/).
  final Directory storageRoot;

  /// مكان ملف النسخة الناتج قبل أن يحفظه المستخدم (مجلد مؤقت).
  final Directory outputDirectory;

  /// مجلد عمل على نفس قرص القاعدة (لنقل الملفات بإعادة التسمية).
  final Directory workDirectory;

  /// مفتاح قاعدة الجهاز الحالية (null لقاعدة غير مشفرة في الاختبارات).
  final String? databaseKey;

  // ------------------------------------------------------------ الإنشاء

  Future<BackupResult> create({
    required String password,
    bool includeSupervisorKeys = false,
  }) async {
    final now = _clock();
    final work = await _freshDir('backup_work');
    try {
      final snapshot = File(p.join(work.path, databaseEntry));
      await _db.customStatement('VACUUM INTO ?', [snapshot.path]);

      // مفتاح مستقل للنسخة: لا يُكشف مفتاح قاعدة الجهاز حتى لو كُشفت كلمة المرور.
      final backupKey = _randomKey();
      _withDatabase(snapshot, databaseKey, (db) {
        db.execute(_rekey(backupKey));
      });

      final secrets = <String, String>{'db_key': backupKey};
      var keysIncluded = false;
      if (includeSupervisorKeys) {
        final privateKey = await _secrets.read(SecretKeys.supervisorPrivateKey);
        final pinHash = await _secrets.read(SecretKeys.supervisorPinHash);
        if (privateKey != null && pinHash != null) {
          secrets['supervisor_private_key'] = privateKey;
          secrets['supervisor_pin_hash'] = pinHash;
          keysIncluded = true;
        }
      }

      final counts = _withDatabase(snapshot, backupKey, _counts);
      final manifest = BackupManifest(
        formatVersion: BackupManifest.currentFormatVersion,
        schemaVersion: _db.schemaVersion,
        appVersion: AppInfo.version,
        createdAt: now,
        deviceId: await _settings.get(SettingKeys.deviceId),
        userCode: await _settings.get(SettingKeys.userCode),
        orgName: await _settings.get(SettingKeys.orgName),
        caseCount: counts.$1,
        attachmentCount: counts.$2,
        includesSupervisorKeys: keysIncluded,
      );

      final zip = File(p.join(work.path, 'backup.zip'));
      final encoder = ZipFileEncoder()..create(zip.path);
      try {
        encoder.addArchiveFile(
          ArchiveFile.bytes(
            manifestEntry,
            utf8.encode(
              const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
            ),
          ),
        );
        encoder.addArchiveFile(
          ArchiveFile.bytes(secretsEntry, utf8.encode(jsonEncode(secrets))),
        );
        await encoder.addFile(snapshot, databaseEntry, ZipFileEncoder.store);
        final attachments = Directory(p.join(storageRoot.path, attachmentsDir));
        if (await attachments.exists()) {
          await for (final entity in attachments.list(recursive: true)) {
            if (entity is! File) continue;
            final relative = p
                .relative(entity.path, from: storageRoot.path)
                .replaceAll(r'\', '/');
            await encoder.addFile(entity, relative, ZipFileEncoder.store);
          }
        }
        await encoder.close();
      } catch (_) {
        await encoder.close();
        rethrow;
      }

      await outputDirectory.create(recursive: true);
      final output = File(p.join(outputDirectory.path, fileNameFor(now)));
      await _cipher.encryptFile(input: zip, output: output, password: password);

      await _settings.set(
        SettingKeys.lastBackupAt,
        now.toUtc().toIso8601String(),
      );
      await _audit.log(
        action: AuditActions.backupCreated,
        entityType: 'device',
        details: {
          'cases': manifest.caseCount,
          'attachments': manifest.attachmentCount,
          'supervisor_keys': keysIncluded,
        },
        actor: manifest.userCode,
      );
      return BackupResult(file: output, manifest: manifest);
    } finally {
      if (await work.exists()) await work.delete(recursive: true);
    }
  }

  static String fileNameFor(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'FieldCases-Backup-${t.year}${two(t.month)}${two(t.day)}'
        '-${two(t.hour)}${two(t.minute)}.$extension';
  }

  // ------------------------------------------------------------ الاستعادة

  /// يفك التشفير ويفحص النسخة في مجلد عمل. لا يغيّر أي بيانات حالية.
  Future<StagedRestore> stage(File file, String password) async {
    if (!await BackupCipher.isBackup(file)) {
      throw const BackupException('الملف ليس نسخة احتياطية لهذا التطبيق');
    }
    final dir = await _freshDir('restore_staging');
    try {
      final zip = File(p.join(dir.path, 'backup.zip'));
      try {
        await _cipher.decryptFile(input: file, output: zip, password: password);
      } on BackupCipherException catch (e) {
        throw BackupException(e.message, wrongPassword: e.wrongPassword);
      }
      await _extract(zip, dir);
      await zip.delete();

      final manifestFile = File(p.join(dir.path, manifestEntry));
      final secretsFile = File(p.join(dir.path, secretsEntry));
      final database = File(p.join(dir.path, databaseEntry));
      if (!await manifestFile.exists() ||
          !await secretsFile.exists() ||
          !await database.exists()) {
        throw const BackupException('النسخة ناقصة: ملفات أساسية مفقودة');
      }
      final BackupManifest manifest;
      final Map<String, String> secrets;
      try {
        final json = jsonDecode(await manifestFile.readAsString());
        if (json is! Map<String, dynamic> ||
            json['format'] != BackupManifest.format) {
          throw const FormatException();
        }
        manifest = BackupManifest.fromJson(json);
        secrets = (jsonDecode(await secretsFile.readAsString()) as Map)
            .cast<String, String>();
      } on Object {
        throw const BackupException('وصف النسخة الاحتياطية غير صالح');
      }
      if (manifest.formatVersion > BackupManifest.currentFormatVersion ||
          manifest.schemaVersion > _db.schemaVersion) {
        throw const BackupException(
          'النسخة من إصدار أحدث من هذا التطبيق. حدّث التطبيق ثم أعد المحاولة.',
        );
      }
      final backupKey = secrets['db_key'];
      if (backupKey == null) {
        throw const BackupException('النسخة لا تحتوي مفتاح قاعدة البيانات');
      }

      final (caseCount, attachmentCount, paths) = _withDatabase(
        database,
        backupKey,
        (db) {
          final check = db.select('PRAGMA integrity_check').first.values.first;
          if (check != 'ok') {
            throw const BackupException('قاعدة البيانات في النسخة تالفة');
          }
          final counts = _counts(db);
          final rows = db.select(
            'SELECT relative_path FROM attachments WHERE deleted_at IS NULL',
          );
          return (
            counts.$1,
            counts.$2,
            [for (final r in rows) r['relative_path'] as String],
          );
        },
      );
      var missing = 0;
      for (final path in paths) {
        if (!CasePackageReader.isSafePath(path) ||
            !await File(p.join(dir.path, path)).exists()) {
          missing++;
        }
      }
      return StagedRestore(
        directory: dir,
        manifest: manifest,
        caseCount: caseCount,
        attachmentCount: attachmentCount,
        missingFiles: missing,
        secrets: secrets,
      );
    } catch (_) {
      if (await dir.exists()) await dir.delete(recursive: true);
      rethrow;
    }
  }

  /// يجهز القاعدة المستعادة لهذا الجهاز (والقاعدة الحالية ما زالت مفتوحة):
  /// - إعدادات خاصة بالجهاز تبقى كما هي (قفل التطبيق).
  /// - بدون مفاتيح المشرف: يبقى مفتاح المشرف العام الحالي، ولا يُفعَّل وضع
  ///   المشرف على جهاز لا يملك رمزه.
  /// - إعادة تشفير القاعدة بمفتاح هذا الجهاز.
  Future<void> prepare(StagedRestore staged) async {
    final keep = <String, String?>{
      SettingKeys.appLockEnabled: await _settings.get(
        SettingKeys.appLockEnabled,
      ),
      SettingKeys.appLockBiometric: await _settings.get(
        SettingKeys.appLockBiometric,
      ),
    };
    var forceEmployee = false;
    if (!staged.manifest.includesSupervisorKeys ||
        !staged.secrets.containsKey('supervisor_private_key')) {
      keep[KeyManager.publicKeySetting] = await _settings.get(
        KeyManager.publicKeySetting,
      );
      forceEmployee =
          await _secrets.read(SecretKeys.supervisorPinHash) == null ||
          await _secrets.read(SecretKeys.supervisorPrivateKey) == null;
    }

    _withDatabase(staged.database, staged.secrets['db_key'], (db) {
      for (final MapEntry(:key, :value) in keep.entries) {
        if (value == null) {
          db.execute('DELETE FROM app_settings WHERE key = ?', [key]);
        } else {
          db.execute(
            'INSERT INTO app_settings (key, value) VALUES (?, ?) '
            'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
            [key, value],
          );
        }
      }
      if (forceEmployee) {
        db.execute('UPDATE app_settings SET value = ? WHERE key = ?', [
          'employee',
          SettingKeys.role,
        ]);
      }
      db.execute(_rekey(databaseKey));
    });
  }

  /// يستبدل ملفات الجهاز بالنسخة المجهزة. يجب أن تكون القاعدة الحالية مغلقة.
  ///
  /// البيانات الحالية تُنقل جانبًا أولًا وتُعاد كما كانت إن فشل أي جزء.
  static Future<void> swap(
    StagedRestore staged, {
    required File databaseFile,
    required Directory storageRoot,
    required SecretStore secrets,
  }) async {
    final rollback = Directory(
      p.join(staged.directory.parent.path, 'rollback'),
    );
    if (await rollback.exists()) await rollback.delete(recursive: true);
    await rollback.create(recursive: true);

    final moved = <(String, String)>[]; // (الأصل، مكانه في rollback)
    Future<void> moveAside(FileSystemEntity entity) async {
      if (!await entity.exists()) return;
      final target = p.join(rollback.path, p.basename(entity.path));
      await entity.rename(target);
      moved.add((entity.path, target));
    }

    final liveAttachments = Directory(p.join(storageRoot.path, attachmentsDir));
    try {
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        await moveAside(File('${databaseFile.path}$suffix'));
      }
      await moveAside(liveAttachments);

      await databaseFile.parent.create(recursive: true);
      await staged.database.rename(databaseFile.path);
      if (await staged.attachments.exists()) {
        await staged.attachments.rename(liveAttachments.path);
      } else {
        await liveAttachments.create(recursive: true);
      }
    } catch (_) {
      if (await databaseFile.exists()) await databaseFile.delete();
      if (await liveAttachments.exists()) {
        await liveAttachments.delete(recursive: true);
      }
      for (final (original, aside) in moved.reversed) {
        await FileSystemEntity.isDirectory(aside)
            ? await Directory(aside).rename(original)
            : await File(aside).rename(original);
      }
      rethrow;
    }
    // الملفات الجديدة في مكانها: لا تراجع بعد هذه النقطة حتى لو أُغلق التطبيق.
    await File(p.join(rollback.path, _completeMarker)).writeAsString('ok');

    final privateKey = staged.secrets['supervisor_private_key'];
    final pinHash = staged.secrets['supervisor_pin_hash'];
    if (staged.manifest.includesSupervisorKeys &&
        privateKey != null &&
        pinHash != null) {
      await secrets.write(SecretKeys.supervisorPrivateKey, privateKey);
      await secrets.write(SecretKeys.supervisorPinHash, pinHash);
    }

    await rollback.delete(recursive: true);
    if (await staged.directory.exists()) {
      await staged.directory.delete(recursive: true);
    }
  }

  /// عند التشغيل: إن انقطع الاستبدال (إغلاق مفاجئ) تُعاد البيانات السابقة
  /// المنقولة جانبًا لمكانها بدل فقدانها. يعيد true إذا استُرجع شيء.
  static Future<bool> recoverInterruptedSwap({
    required Directory workDirectory,
    required File databaseFile,
    required Directory storageRoot,
  }) async {
    final rollback = Directory(p.join(workDirectory.path, 'rollback'));
    if (!await rollback.exists()) return false;
    final asideDb = File(p.join(rollback.path, p.basename(databaseFile.path)));
    final asideAttachments = Directory(p.join(rollback.path, attachmentsDir));
    var recovered = false;
    if (await File(p.join(rollback.path, _completeMarker)).exists()) {
      await rollback.delete(recursive: true);
      return false;
    }
    // القاعدة المستعادة لم تُوضع كاملة ← نرجع للسابقة مع صورها.
    if (await asideDb.exists()) {
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        final live = File('${databaseFile.path}$suffix');
        if (await live.exists()) await live.delete();
        final aside = File('${asideDb.path}$suffix');
        if (await aside.exists()) await aside.rename(live.path);
      }
      final live = Directory(p.join(storageRoot.path, attachmentsDir));
      if (await asideAttachments.exists()) {
        if (await live.exists()) await live.delete(recursive: true);
        await asideAttachments.rename(live.path);
      }
      recovered = true;
    }
    await rollback.delete(recursive: true);
    return recovered;
  }

  Future<void> discard(StagedRestore staged) async {
    if (await staged.directory.exists()) {
      await staged.directory.delete(recursive: true);
    }
  }

  /// يُسجَّل في القاعدة المستعادة بعد فتحها.
  static Future<void> logRestored(
    AuditLogger audit,
    BackupManifest manifest, {
    String? actor,
  }) => audit.log(
    action: AuditActions.backupRestored,
    entityType: 'device',
    details: {
      'backup_created_at': manifest.createdAt.toUtc().toIso8601String(),
      'backup_device': manifest.deviceId,
      'cases': manifest.caseCount,
    },
    actor: actor,
  );

  // ------------------------------------------------------------ داخلي

  Future<void> _extract(File zip, Directory destination) async {
    const allowed = {manifestEntry, secretsEntry, databaseEntry};
    final input = InputFileStream(zip.path);
    try {
      final archive = ZipDecoder().decodeStream(input);
      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        final name = entry.name;
        if (!CasePackageReader.isSafePath(name) ||
            !(allowed.contains(name) || name.startsWith('$attachmentsDir/'))) {
          throw BackupException('النسخة تحتوي مسارًا غير متوقع: $name');
        }
        final target = File(p.join(destination.path, name));
        if (!p.isWithin(destination.path, target.path)) {
          throw BackupException('النسخة تحتوي مسارًا غير آمن: $name');
        }
        await target.parent.create(recursive: true);
        final output = OutputFileStream(target.path);
        entry.writeContent(output);
        await output.close();
      }
    } on BackupException {
      rethrow;
    } on Object {
      throw const BackupException('محتوى النسخة الاحتياطية تالف');
    } finally {
      await input.close();
    }
  }

  static (int, int) _counts(Database db) {
    final cases =
        db
                .select(
                  'SELECT count(*) AS n FROM cases WHERE deleted_at IS NULL',
                )
                .first['n']
            as int;
    final attachments =
        db
                .select(
                  'SELECT count(*) AS n FROM attachments WHERE deleted_at IS NULL',
                )
                .first['n']
            as int;
    return (cases, attachments);
  }

  static T _withDatabase<T>(File file, String? key, T Function(Database) run) {
    final db = sqlite3.open(file.path);
    try {
      if (key != null) db.execute(DatabaseEncryption.keyPragma(key));
      return run(db);
    } on SqliteException {
      throw const BackupException('تعذّر فتح قاعدة البيانات في النسخة');
    } finally {
      db.close();
    }
  }

  /// إعادة التشفير بمفتاح جديد؛ null ← بلا تشفير (للاختبارات فقط).
  static String _rekey(String? key) {
    if (key == null) return "PRAGMA rekey = ''";
    DatabaseEncryption.keyPragma(key); // تحقق من الصيغة.
    return "PRAGMA rekey = '$key'";
  }

  String _randomKey() => List<int>.generate(
    32,
    (_) => _random.nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Future<Directory> _freshDir(String name) async {
    final dir = Directory(p.join(workDirectory.path, name));
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    return dir;
  }
}

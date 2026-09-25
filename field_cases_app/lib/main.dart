import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app_restart.dart';
import 'app/providers.dart';
import 'core/db/app_database.dart';
import 'core/files/attachment_storage.dart';
import 'core/security/backup_exclusion.dart';
import 'core/security/database_encryption.dart';
import 'core/security/secret_store.dart';
import 'features/backup/data/backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');

  // القاعدة والصور والحزم الواردة لا تُرفع إلى iCloud.
  await BackupExclusion.exclude([
    await getApplicationSupportDirectory(),
    await getApplicationDocumentsDirectory(),
  ]);

  final restart = AppRestartController();
  Future<ProviderContainer> bootstrap() => _createContainer(restart);
  runApp(
    AppRoot(
      controller: restart,
      initial: await bootstrap(),
      bootstrap: bootstrap,
    ),
  );
}

/// يفتح القاعدة ويجهز الخدمات. يُستدعى عند التشغيل وبعد الاستعادة.
Future<ProviderContainer> _createContainer(AppRestartController restart) async {
  final supportDir = await getApplicationSupportDirectory();

  // مفتاح القاعدة من Keychain/Keystore؛ قاعدة قديمة غير مشفرة تُشفَّر مرة واحدة.
  final dbKey = await DatabaseEncryption(const DeviceSecretStore()).obtainKey();
  final dbFile = await AppDatabase.databaseFile();
  final backupWorkDir = Directory(p.join(supportDir.path, 'backup_work'));
  await BackupService.recoverInterruptedSwap(
    workDirectory: backupWorkDir,
    databaseFile: dbFile,
    storageRoot: supportDir,
  );
  await DatabaseEncryption.encryptIfPlain(dbFile, dbKey);
  final database = AppDatabase.open(key: dbKey);
  final storage = AttachmentStorage(supportDir);
  // صور نماذج لم تُحفظ في جلسة سابقة (مثل إغلاق التطبيق أثناء الإدخال).
  await storage.clearStaging();
  // ملفات التصدير والنسخ الاحتياطي مؤقتة: نسخها المحفوظة لدى المستخدم.
  final exportDir = Directory(
    '${(await getTemporaryDirectory()).path}/exports',
  );
  if (await exportDir.exists()) await exportDir.delete(recursive: true);

  final importDir = Directory(p.join(supportDir.path, 'imports'));
  // بقايا استعادة لم تكتمل (مثل إغلاق التطبيق أثناء فحص النسخة).
  if (await backupWorkDir.exists()) {
    await backupWorkDir.delete(recursive: true);
  }

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      attachmentStorageProvider.overrideWithValue(storage),
      exportDirectoryProvider.overrideWithValue(exportDir),
      importDirectoryProvider.overrideWithValue(importDir),
      databaseKeyProvider.overrideWithValue(dbKey),
      databaseFileProvider.overrideWithValue(dbFile),
      backupWorkDirectoryProvider.overrideWithValue(backupWorkDir),
      appRestartProvider.overrideWithValue(restart),
    ],
  );
  // يضمن توليد المعرف المنطقي للجهاز عند أول تشغيل.
  await container.read(settingsRepositoryProvider).deviceId();
  return container;
}

import 'dart:io';

import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/db/app_database.dart';
import 'core/files/attachment_storage.dart';
import 'core/security/database_encryption.dart';
import 'core/security/secret_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تنفيذ أصلي (أسرع) لـ AES-GCM و X25519 على iOS/Android.
  FlutterCryptography.enable();
  await initializeDateFormatting('ar');

  // مفتاح القاعدة من Keychain/Keystore؛ قاعدة قديمة غير مشفرة تُشفَّر مرة واحدة.
  final dbKey = await DatabaseEncryption(const DeviceSecretStore()).obtainKey();
  await DatabaseEncryption.encryptIfPlain(
    await AppDatabase.databaseFile(),
    dbKey,
  );
  final database = AppDatabase.open(key: dbKey);
  final storage = AttachmentStorage(await getApplicationSupportDirectory());
  // صور نماذج لم تُحفظ في جلسة سابقة (مثل إغلاق التطبيق أثناء الإدخال).
  await storage.clearStaging();
  // حزم التصدير مؤقتة: نسخها المشاركة لدى المستلم، ولا حاجة لبقائها هنا.
  final exportDir = Directory(
    '${(await getTemporaryDirectory()).path}/exports',
  );
  if (await exportDir.exists()) await exportDir.delete(recursive: true);

  final importDir = Directory(
    '${(await getApplicationSupportDirectory()).path}/imports',
  );

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      attachmentStorageProvider.overrideWithValue(storage),
      exportDirectoryProvider.overrideWithValue(exportDir),
      importDirectoryProvider.overrideWithValue(importDir),
    ],
  );
  // يضمن توليد المعرف المنطقي للجهاز عند أول تشغيل.
  await container.read(settingsRepositoryProvider).deviceId();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FieldCasesApp(),
    ),
  );
}

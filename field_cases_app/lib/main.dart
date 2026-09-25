import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/db/app_database.dart';
import 'core/files/attachment_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');

  final database = AppDatabase.open();
  final storage = AttachmentStorage(await getApplicationSupportDirectory());
  // صور نماذج لم تُحفظ في جلسة سابقة (مثل إغلاق التطبيق أثناء الإدخال).
  await storage.clearStaging();

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      attachmentStorageProvider.overrideWithValue(storage),
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

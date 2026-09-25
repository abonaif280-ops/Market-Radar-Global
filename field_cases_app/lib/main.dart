import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');

  final database = AppDatabase.open();
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
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

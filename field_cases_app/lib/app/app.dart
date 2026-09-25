import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/incoming/incoming_file_listener.dart';
import '../features/security/presentation/app_lock_gate.dart';
import 'app_shell.dart';
import 'theme.dart';

class FieldCasesApp extends StatelessWidget {
  const FieldCasesApp({super.key});

  static const Locale arabic = Locale('ar');

  /// لرسائل تظهر بعد إعادة بناء التطبيق (مثل نجاح الاستعادة).
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الحالات الميدانية',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      // العربية فقط؛ اتجاه RTL يُطبَّق تلقائيًا من اللغة.
      locale: arabic,
      supportedLocales: const [arabic],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) => AppLockGate(child: child!),
      home: const IncomingFileListener(child: AppShell()),
    );
  }
}

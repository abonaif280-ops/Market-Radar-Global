import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_shell.dart';
import 'theme.dart';

class FieldCasesApp extends StatelessWidget {
  const FieldCasesApp({super.key});

  static const Locale arabic = Locale('ar');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الحالات الميدانية',
      debugShowCheckedModeBanner: false,
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
      home: const AppShell(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_shell.dart';
import 'ui/app_theme.dart';

class DeadlineNoteApp extends StatelessWidget {
  const DeadlineNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '마감노트',
      theme: AppTheme.light(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:deadline_note/l10n/app_localizations.dart';

import 'screens/splash_screen.dart';
import 'ui/app_theme.dart';

import 'state/app_state_scope.dart';

class DeadlineNoteApp extends StatelessWidget {
  const DeadlineNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final localeCode = appState.settings.localeCode;
    final locale = localeCode != null ? Locale(localeCode) : null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}

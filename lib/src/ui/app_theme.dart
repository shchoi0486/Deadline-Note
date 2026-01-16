import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final seedScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2F5EFF));
    // Override surface colors to be neutral/white to avoid pink tint
    final scheme = seedScheme.copyWith(
      surface: Colors.white,
      surfaceContainerLow: const Color(0xFFF8F9FA),
      surfaceContainer: const Color(0xFFF1F3F5),
      surfaceContainerHigh: const Color(0xFFE9ECEF),
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.surfaceContainerHigh,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppColors {
  static const Color accent = Color(0xFF0866FF);
  static const Color pageBackground = Color(0xFFF0F2F5);
  static const Color surface = Colors.white;
  static const Color secondarySurface = Color(0xFFF7F8FA);
  static const Color textPrimary = Color(0xFF1C1E21);
  static const Color textSecondary = Color(0xFF65676B);
  static const Color border = Color(0xFFDADDE1);
  static const Color onAccent = Colors.white;
}

class AppTheme {
  static const Color primaryColor = AppColors.accent;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.pageBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.pageBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppColors.textSecondary),
    ),
  );
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

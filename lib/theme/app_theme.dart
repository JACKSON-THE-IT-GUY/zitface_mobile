import 'package:flutter/material.dart';

class AppColors {
  static const Color accent = Color(0xFFC62828);
  static const Color pageBackground = Color(0xFFF5F1F1);
  static const Color darkPageBackground = Color(0xFF171313);
  static const Color surface = Colors.white;
  static const Color darkSurface = Color(0xFF241D1D);
  static const Color secondarySurface = Color(0xFFF9F3F3);
  static const Color darkSecondarySurface = Color(0xFF302626);
  static const Color textPrimary = Color(0xFF111111);
  static const Color darkTextPrimary = Color(0xFFF5EEEE);
  static const Color textSecondary = Color(0xFF4B4B4B);
  static const Color darkTextSecondary = Color(0xFFD0C3C3);
  static const Color border = Color(0xFFE9D9D9);
  static const Color darkBorder = Color(0xFF514141);
  static const Color onAccent = Colors.white;
}

class AppTheme {
  static const Color primaryColor = AppColors.accent;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.darkPageBackground,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ).copyWith(
          surface: AppColors.darkSurface,
          surfaceContainer: AppColors.darkSurface,
          surfaceContainerLow: AppColors.darkSurface,
          surfaceContainerHigh: AppColors.darkSecondarySurface,
          surfaceContainerHighest: AppColors.darkSecondarySurface,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkBorder,
          surfaceTint: Colors.transparent,
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppColors.darkTextSecondary),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.pageBackground,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ).copyWith(
          surface: AppColors.surface,
          surfaceContainer: AppColors.surface,
          surfaceContainerLow: AppColors.surface,
          surfaceContainerHigh: AppColors.secondarySurface,
          surfaceContainerHighest: AppColors.secondarySurface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
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

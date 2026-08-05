import 'package:flutter/material.dart';

class AppColors {
  static const Color accent = Color(0xFF7C3AED);

  static const Color darkBackgroundTop = Color(0xFF3A0B1E);
  static const Color darkBackgroundBottom = Color(0xFF080204);
  static const Color darkText = Colors.white;

  static const Color lightBackgroundTop = Color(0xFFF9FAFB);
  static const Color lightBackgroundBottom = Color(0xFFE5E7EB);
  static const Color lightText = Color(0xFF111827);
}

class AppTheme {
  static const Color primaryColor = AppColors.accent;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ),
  );
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
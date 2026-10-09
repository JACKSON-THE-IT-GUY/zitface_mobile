import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'screens/main_shell_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const ZitfaceApp(),
    ),
  );
}

class ZitfaceApp extends StatelessWidget {
  const ZitfaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZITFACE',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: const MainShellScreen(),
    );
  }
}

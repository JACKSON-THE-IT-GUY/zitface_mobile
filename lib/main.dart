import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_bootstrap.dart';
import 'services/zitface_backend.dart';
import 'screens/login_screen.dart';
import 'screens/member_identity_screen.dart';
import 'screens/main_shell_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late final bool isSupabaseConfigured;
  try {
    isSupabaseConfigured = await initializeSupabase(
      requireHttps: kReleaseMode,
    );
  } on Exception catch (error) {
    if (!kReleaseMode) rethrow;
    debugPrint('Supabase production configuration is invalid: $error');
    runApp(const _BackendUnavailableApp());
    return;
  }
  if (!isSupabaseConfigured) {
    if (kReleaseMode) {
      runApp(const _BackendUnavailableApp());
      return;
    }
    debugPrint(
      'Supabase is not configured; running with the app local demo data.',
    );
  }

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'ZITFACE',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        home: const _AppEntryPoint(),
      ),
    );
  }
}

class _AppEntryPoint extends StatelessWidget {
  const _AppEntryPoint();

  @override
  Widget build(BuildContext context) {
    if (!ZitfaceBackend.isConfigured) {
      return kReleaseMode
          ? const _BackendUnavailableScreen()
          : const MainShellScreen();
    }

    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not check your sign-in status: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final session = snapshot.data?.session ?? client.auth.currentSession;
        return session == null
          ? const LoginScreen()
          : const MemberIdentityGate();
      },
    );
  }
}

class _BackendUnavailableApp extends StatelessWidget {
  const _BackendUnavailableApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const _BackendUnavailableScreen(),
    );
  }
}

class _BackendUnavailableScreen extends StatelessWidget {
  const _BackendUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'ZITFACE is temporarily unavailable. Please try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

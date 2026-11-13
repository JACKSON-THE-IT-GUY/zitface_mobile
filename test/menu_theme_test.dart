import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zitface_mobile/screens/menu_screen.dart';
import 'package:zitface_mobile/screens/main_shell_screen.dart';
import 'package:zitface_mobile/screens/account_settings_screen.dart';
import 'package:zitface_mobile/screens/legal_information_screen.dart';
import 'package:zitface_mobile/theme/app_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => themeNotifier.value = ThemeMode.light);

  testWidgets('menu switches the app between dark and light themes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, themeMode, _) => MaterialApp(
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const MenuScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Settings & Privacy'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dark mode'));
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();

    expect(themeNotifier.value, ThemeMode.dark);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.byType(MenuScreen))).brightness,
      Brightness.dark,
    );

    await tester.ensureVisible(find.text('Light mode'));
    await tester.tap(find.text('Light mode'));
    await tester.pumpAndSettle();

    expect(themeNotifier.value, ThemeMode.light);
    expect(
      Theme.of(tester.element(find.byType(MenuScreen))).brightness,
      Brightness.light,
    );
  });

  testWidgets('menu shortcuts open existing shell pages', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campus Buy/Sell'));
    await tester.pumpAndSettle();
    expect(find.text('Campus Market'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See your profile'));
    await tester.pumpAndSettle();
    expect(find.text('Create Profile'), findsOneWidget);
  });

  testWidgets('account settings exposes privacy and session controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AccountSettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Account & Privacy'), findsOneWidget);
    expect(find.text('Change display name'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Private profile'), findsOneWidget);
    expect(find.text('This device'), findsOneWidget);
    expect(find.text('Sign out other devices'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Delete account'), findsOneWidget);
  });

  testWidgets('privacy and terms page identifies itself as a draft', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LegalInformationScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Privacy and Terms'), findsOneWidget);
    expect(find.textContaining('MVP draft'), findsOneWidget);
    expect(find.text('Privacy summary'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(find.text('Terms summary'), findsOneWidget);
  });
}

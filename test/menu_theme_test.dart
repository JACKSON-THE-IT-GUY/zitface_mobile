import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zitface_mobile/screens/menu_screen.dart';
import 'package:zitface_mobile/theme/app_theme.dart';

void main() {
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
}

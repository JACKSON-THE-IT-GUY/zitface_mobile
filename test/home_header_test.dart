import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zitface_mobile/screens/main_shell_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home profile-head button opens the Profile tab', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));

    await tester.tap(find.byTooltip('Profile'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Create Profile'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zitface_mobile/screens/main_shell_screen.dart';

void main() {
  testWidgets('tablet landscape keeps centered bottom navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));
    await tester.pump();

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('desktop layout shows labeled side navigation', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('ZITFACE'),
      ),
      findsOneWidget,
    );
    expect(find.text('Materials'), findsOneWidget);
  });
}
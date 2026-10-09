import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zitface_mobile/screens/main_shell_screen.dart';
import 'package:zitface_mobile/screens/materials_screen.dart';

void main() {
  testWidgets('filters schools and shows an empty materials state', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MaterialsScreen()));

    expect(find.text('Study Materials'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'sict');
    await tester.pumpAndSettle();

    expect(
      find.text('School of Information and Communication Technology'),
      findsOneWidget,
    );
    expect(find.text('School of Business'), findsNothing);

    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    expect(find.text('Materials are being collected'), findsOneWidget);
    expect(
      find.text(
        'Program-specific notes, past papers, and study guides will appear here once added.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens the Materials tab from the bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));

    await tester.tap(find.text('Materials'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Study Materials'), findsOneWidget);
  });
}

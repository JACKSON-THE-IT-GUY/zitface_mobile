import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zitface_mobile/screens/group_hub_screen.dart';
import 'package:zitface_mobile/screens/groups_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('creates linked cohort groups and shows cohort metadata', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GroupsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'School'),
      'School of ICT',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Program'),
      'Computer Science',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class representative name'),
      'Jackson Nsonga',
    );
    await tester.tap(find.text('Create groups'));
    await tester.pumpAndSettle();

    expect(find.text('Computer Science'), findsOneWidget);
    expect(find.text('School of ICT · Year 1'), findsOneWidget);
    expect(find.text('Class representative: Jackson Nsonga'), findsOneWidget);
    expect(find.text('Program group (data group)'), findsOneWidget);
    expect(find.text('Class group'), findsOneWidget);
    expect(find.text('Study group'), findsOneWidget);
    expect(find.text('Lecture group'), findsOneWidget);
    expect(find.text('Tutorial group'), findsOneWidget);

    await tester.tap(find.text('Computer Science Year 1 Class Group'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupHubScreen), findsOneWidget);
    expect(find.text('COHORT CONNECTION'), findsOneWidget);
    expect(find.text('School of ICT'), findsOneWidget);
    expect(find.text('Year 1'), findsOneWidget);
    expect(find.text('Jackson Nsonga'), findsOneWidget);
    expect(find.text('Join Group'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: GroupsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Computer Science Year 1 Tutorial Group'), findsOneWidget);
    expect(find.text('Class representative: Jackson Nsonga'), findsOneWidget);
  });

  testWidgets('requires school, program, and class representative', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GroupsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create groups'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsNWidgets(3));
    expect(find.text('Create academic cohort'), findsOneWidget);
  });
}

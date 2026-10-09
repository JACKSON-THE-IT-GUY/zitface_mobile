import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zitface_mobile/screens/profile_screen.dart';

void main() {
  const imagePickerChannel = MethodChannel('plugins.flutter.io/image_picker');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(imagePickerChannel, null);
  });

  testWidgets('a profile can be created and remains saved after recreation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Your profile'), findsOneWidget);
    expect(find.text('Create Profile'), findsOneWidget);

    await tester.tap(find.text('Create Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Updated Name');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Name'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Updated Name'), findsOneWidget);
    expect(find.text('Jackson Nsonga'), findsNothing);
  });

  testWidgets('profile photo action opens the gallery picker', (tester) async {
    MethodCall? pickerCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(imagePickerChannel, (call) async {
          pickerCall = call;
          return null;
        });

    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add profile photo'));
    await tester.pumpAndSettle();

    expect(pickerCall?.method, 'pickImage');
    expect(pickerCall?.arguments['source'], 1);
    expect(pickerCall?.arguments['maxWidth'], 1024);
  });
}

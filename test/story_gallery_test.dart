import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zitface_mobile/screens/home_screen.dart';

void main() {
  const imagePickerChannel = MethodChannel('plugins.flutter.io/image_picker');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(imagePickerChannel, null);
  });

  testWidgets('Create story opens the image picker with the gallery source', (
    tester,
  ) async {
    MethodCall? pickerCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(imagePickerChannel, (call) async {
          pickerCall = call;
          return null;
        });

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.tap(find.text('Create story'));
    await tester.pumpAndSettle();

    expect(pickerCall?.method, 'pickImage');
    expect(pickerCall?.arguments['source'], 1);
    expect(find.text('Create story'), findsOneWidget);
  });
}

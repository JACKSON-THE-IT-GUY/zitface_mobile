import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zitface_mobile/screens/home_screen.dart';
import 'package:zitface_mobile/screens/story_composer_sheet.dart';

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

  testWidgets('adds a selected music track to the story', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.tap(find.byTooltip('Add story music'));
    await tester.pumpAndSettle();

    expect(find.text('Add music to your story'), findsOneWidget);
    await tester.tap(find.text('Paper Skies'));
    await tester.pumpAndSettle();

    expect(find.text('Paper Skies'), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsNWidgets(2));
  });

  testWidgets('story composer supports video selection and audience control', (
    tester,
  ) async {
    MethodCall? pickerCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(imagePickerChannel, (call) async {
          pickerCall = call;
          return null;
        });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StoryComposerSheet())),
    );
    await tester.tap(find.text('Video'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose video (up to 60 seconds)'));
    await tester.pumpAndSettle();

    expect(pickerCall?.method, 'pickVideo');
    expect(find.text('Add a caption'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
  });

  testWidgets('story composer exposes soundtrack upload with rights gate', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const StoryComposerSheet(),
                ),
                child: const Text('Open story composer'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open story composer'));
    await tester.pumpAndSettle();

    expect(find.text('Add your own soundtrack'), findsOneWidget);
    expect(find.text('I have the rights to use this audio.'), findsNothing);
    final shareButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Share for 24 hours'),
    );
    expect(shareButton.onPressed, isNull);
  });
}

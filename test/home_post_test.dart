import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zitface_mobile/screens/home_screen.dart';

void main() {
  const imagePickerChannel = MethodChannel('plugins.flutter.io/image_picker');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(imagePickerChannel, null);
  });

  testWidgets('composes and publishes a post to the home feed', (tester) async {
    MethodCall? pickerCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(imagePickerChannel, (call) async {
          pickerCall = call;
          return null;
        });

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.tap(find.text("What's on your mind?"));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    expect(pickerCall?.method, 'pickImage');
    expect(pickerCall?.arguments['source'], 1);

    await tester.enterText(find.byType(TextField).first, 'Hello campus!');
    await tester.pump();
    final postButton = find.ancestor(
      of: find.text('Post'),
      matching: find.byType(ElevatedButton),
    );
    expect(tester.widget<ElevatedButton>(postButton).onPressed, isNotNull);
    await tester.tap(postButton);
    await tester.pumpAndSettle();

    expect(find.text('Hello campus!'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.textContaining('Just now'), findsOneWidget);
  });

  testWidgets('post has Facebook-style Like, Comment, Share actions', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.tap(find.text("What's on your mind?"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'React to this');
    await tester.pump();
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    final postText = find.text('React to this');
    await tester.ensureVisible(postText);
    expect(find.text('Like'), findsWidgets);
    expect(find.text('Comment'), findsWidgets);
    expect(find.text('Share'), findsWidgets);

    final likeAction = find.text('Like').first;
    await tester.ensureVisible(likeAction);
    await tester.tap(likeAction);
    await tester.pumpAndSettle();
    expect(find.text('👍'), findsNWidgets(2));

    final selectedLike = find.text('Like').last;
    await tester.longPress(selectedLike);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Laugh'));
    await tester.pumpAndSettle();
    expect(find.text('Laugh'), findsOneWidget);
  });

  testWidgets('Comment action opens composer and adds a comment', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.tap(find.text("What's on your mind?"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Post with comment');
    await tester.pump();
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    final postText = find.text('Post with comment');
    await tester.ensureVisible(postText);
    final commentAction = find.text('Comment').first;
    await tester.ensureVisible(commentAction);
    await tester.tap(commentAction);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Nice post!');
    await tester.pump();
    final sendComment = find.byTooltip('Send comment');
    await tester.ensureVisible(sendComment);
    await tester.tap(sendComment);
    await tester.pumpAndSettle();

    expect(find.text('1 comment'), findsOneWidget);

    await tester.ensureVisible(commentAction);
    await tester.tap(commentAction);
    await tester.pumpAndSettle();
    expect(find.text('Nice post!'), findsOneWidget);
  });
}

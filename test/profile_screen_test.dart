import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zitface_mobile/screens/profile_screen.dart';
import 'package:zitface_mobile/screens/main_shell_screen.dart';
import 'package:zitface_mobile/screens/create_post_screen.dart';
import 'package:zitface_mobile/screens/menu_screen.dart';
import 'package:zitface_mobile/screens/market_detail_screen.dart';
import 'package:zitface_mobile/widget/profile_avatar.dart';
import 'package:zitface_mobile/services/zitface_backend.dart';
import 'package:zitface_mobile/services/profile_identity.dart';

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
    await tester.enterText(find.byType(TextField).at(3), 'Computer Science');
    await tester.enterText(find.byType(TextField).at(4), 'Year 2');
    await tester.enterText(find.byType(TextField).at(5), 'Robotics, design');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Name'), findsOneWidget);
    expect(find.text('Computer Science'), findsOneWidget);
    expect(find.text('Year 2'), findsOneWidget);
    expect(find.text('Robotics, design'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Updated Name'), findsOneWidget);
    await tester.ensureVisible(find.text('Computer Science'));
    expect(find.text('Computer Science'), findsOneWidget);
    expect(find.text('Year 2'), findsOneWidget);
    expect(find.text('Robotics, design'), findsOneWidget);
    expect(find.text('Jackson Nsonga'), findsNothing);
  });

  testWidgets('profile page reflects shared account name changes', (
    tester,
  ) async {
    final profile = ValueNotifier(const ProfileIdentity(name: 'First Name'));
    await tester.pumpWidget(MaterialApp(home: ProfileScreen(profile: profile)));
    await tester.pumpAndSettle();

    profile.value = const ProfileIdentity(name: 'Updated From Settings');
    await tester.pumpAndSettle();

    expect(find.text('Updated From Settings'), findsOneWidget);
    profile.dispose();
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

  testWidgets('profile opens messages and gains a star for a post', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));
    await tester.tap(find.text("What's on your mind?"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'My contribution');
    await tester.pump();
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('1 contribution star'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('New message'), findsOneWidget);
  });

  testWidgets('saved identity appears and updates across home, menu and market', (
    tester,
  ) async {
    const photo =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC';
    SharedPreferences.setMockInitialValues({
      'profile': jsonEncode({
        'name': 'Campus Member',
        'handle': 'campus_member',
        'school': 'SICT',
        'bio': 'Hello',
        'photoData': photo,
        'photoPath': '',
      }),
    });
    await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ProfileAvatar>(find.byType(ProfileAvatar).first).photoData,
      photo,
    );

    await tester.tap(find.text("What's on your mind?"));
    await tester.pumpAndSettle();
    expect(find.text('Campus Member'), findsOneWidget);
    expect(
      tester
          .widget<ProfileAvatar>(
            find.descendant(
              of: find.byType(CreatePostScreen),
              matching: find.byType(ProfileAvatar),
            ),
          )
          .photoData,
      photo,
    );
    await tester.enterText(find.byType(TextField).first, 'A campus post');
    await tester.pump();
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(find.text('Campus Member'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Updated Member');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Updated Member'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(MenuScreen),
        matching: find.text('Updated Member'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ProfileAvatar>(
            find.descendant(
              of: find.byType(MenuScreen),
              matching: find.byType(ProfileAvatar),
            ),
          )
          .photoData,
      photo,
    );
    await tester.tap(find.text('Campus Buy/Sell'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sell Item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'My listing');
    await tester.enterText(find.byType(TextField).at(2), '50');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(find.text('Updated Member'), findsOneWidget);
    await tester.tap(
      find
          .ancestor(of: find.text('My listing'), matching: find.byType(InkWell))
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Updated Member'), findsOneWidget);
    expect(
      tester
          .widget<ProfileAvatar>(
            find.descendant(
              of: find.byType(MarketDetailScreen),
              matching: find.byType(ProfileAvatar),
            ),
          )
          .photoData,
      photo,
    );
  });

  test('profile image content types match the uploaded bytes', () {
    expect(
      ZitfaceBackend.avatarContentType(base64Decode('iVBORw0KGgo=')),
      'image/png',
    );
    expect(
      ZitfaceBackend.avatarContentType(base64Decode('/9j/')),
      'image/jpeg',
    );
    expect(
      () => ZitfaceBackend.avatarContentType(base64Decode('R0lGODlh')),
      throwsFormatException,
    );
  });

  test('avatar URLs resolve only to objects in the avatar bucket', () {
    expect(
      ZitfaceBackend.avatarStoragePath('member/avatar.jpg'),
      'member/avatar.jpg',
    );
    expect(
      ZitfaceBackend.avatarStoragePath(
        'https://example.test/storage/v1/object/public/avatars/member/avatar.jpg',
      ),
      'member/avatar.jpg',
    );
    expect(
      ZitfaceBackend.avatarStoragePath('https://example.test/avatar.jpg'),
      '',
    );
  });
}

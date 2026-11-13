import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zitface_mobile/screens/friends_screen.dart';
import 'package:zitface_mobile/screens/main_shell_screen.dart';
import 'package:zitface_mobile/screens/chat_detail_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('searches students and saves sent friend requests', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Find students'), findsOneWidget);
    expect(find.text('Phanciah M.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'electrical');
    await tester.pumpAndSettle();

    expect(find.text('Joe K.'), findsOneWidget);
    expect(find.text('Phanciah M.'), findsNothing);

    await tester.tap(find.text('Add friend'));
    await tester.pumpAndSettle();

    expect(find.text('Request sent'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getStringList(
        'friend_requests_sent',
      ),
      contains('joe'),
    );
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatDetailScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Hello Joe');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Hello Joe'), findsOneWidget);
  });

  testWidgets('opens Friends from the bottom navigation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));

    await tester.tap(find.text('Friends'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Find students'), findsOneWidget);
  });

  testWidgets('a message started in Friends appears in Chats', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Victor Mundia');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Hello Victor');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    expect(find.text('Hello Victor'), findsOneWidget);
    await tester.tap(find.text('Hello Victor'));
    await tester.pumpAndSettle();
    expect(find.text('Hello Victor'), findsOneWidget);
  });
}

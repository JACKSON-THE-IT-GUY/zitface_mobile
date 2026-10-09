import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zitface_mobile/screens/chat_detail_screen.dart';
import 'package:zitface_mobile/screens/chats_screen.dart';

void main() {
  testWidgets('search and unread filter narrow the conversation list', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChatsScreen()));

    await tester.tap(find.text('Unread 2'));
    await tester.pumpAndSettle();

    expect(find.text('Phanciah M.'), findsOneWidget);
    expect(find.text('ICTAZ Tech Group'), findsOneWidget);
    expect(find.text('Victor Mundia'), findsNothing);

    await tester.tap(find.text('All 5'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'backend routes');
    await tester.pumpAndSettle();

    expect(find.text('Victor Mundia'), findsOneWidget);
    expect(find.text('Phanciah M.'), findsNothing);
  });

  testWidgets('new message opens a conversation with an active contact', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChatsScreen()));

    await tester.tap(find.byTooltip('New message'));
    await tester.pumpAndSettle();
    expect(find.text('New message'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'JOE'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatDetailScreen), findsOneWidget);
    expect(find.text('JOE'), findsOneWidget);
  });

  testWidgets('conversation sends a plain-text message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChatDetailScreen(peerName: 'Phanciah', peerHandle: 'SICT'),
      ),
    );

    await tester.enterText(find.byType(TextField), 'See you at the library');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    expect(find.text('See you at the library'), findsOneWidget);
  });
}

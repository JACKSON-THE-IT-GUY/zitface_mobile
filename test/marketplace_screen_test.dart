import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zitface_mobile/screens/market_detail_screen.dart';
import 'package:zitface_mobile/screens/market_screen.dart';

void main() {
  testWidgets('creates a listing and opens its detail page', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MarketplaceScreen()));

    await tester.tap(find.text('Sell Item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Scientific calculator');
    await tester.enterText(find.byType(TextField).at(2), '75.50');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(find.text('Scientific calculator'), findsOneWidget);
    expect(find.text('K75.50'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);

    await tester.tap(find.text('Scientific calculator'));
    await tester.pumpAndSettle();

    expect(find.byType(MarketDetailScreen), findsOneWidget);
    expect(find.text('Message You'), findsOneWidget);
  });
}

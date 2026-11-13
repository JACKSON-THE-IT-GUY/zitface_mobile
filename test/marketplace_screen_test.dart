import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zitface_mobile/screens/market_detail_screen.dart';
import 'package:zitface_mobile/screens/market_screen.dart';
import 'package:zitface_mobile/widget/market_image.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  testWidgets('creates a listing and opens its detail page', (tester) async {
    MethodCall? pickerCall;
    const channel = MethodChannel('plugins.flutter.io/image_picker');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          pickerCall = call;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await tester.pumpWidget(const MaterialApp(home: MarketplaceScreen()));

    await tester.tap(find.text('Sell Item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add item photo'));
    await tester.pumpAndSettle();
    expect(pickerCall?.method, 'pickImage');
    expect(pickerCall?.arguments['source'], 1);
    await tester.enterText(
      find.byType(TextField).at(1),
      'Scientific calculator',
    );
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

  testWidgets('selected item photo appears on the listing and detail', (
    tester,
  ) async {
    final photo = XFile.fromData(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      ),
      name: 'item.png',
      mimeType: 'image/png',
    );
    await tester.pumpWidget(
      MaterialApp(home: MarketplaceScreen(pickImage: () async => photo)),
    );
    await tester.tap(find.text('Sell Item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add item photo'));
    await tester.pumpAndSettle();
    expect(find.text('Change item photo'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'Photo item');
    await tester.enterText(find.byType(TextField).at(2), '50');
    await tester.ensureVisible(find.text('Post'));
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    final card = tester.widget<MarketImage>(find.byType(MarketImage).first);
    expect(card.bytes, isNotNull);
    await tester.tap(find.text('Photo item'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MarketImage>(find.byType(MarketImage)).bytes,
      isNotNull,
    );
    expect(find.text('Photo item'), findsOneWidget);
    expect(find.text('K50'), findsOneWidget);
    expect(find.text('Message You'), findsOneWidget);
  });

  testWidgets('rejects unsupported images and can remove a selected photo', (
    tester,
  ) async {
    var file = XFile.fromData(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      ),
      name: 'item.gif',
      mimeType: 'image/gif',
    );
    await tester.pumpWidget(
      MaterialApp(home: MarketplaceScreen(pickImage: () async => file)),
    );
    await tester.tap(find.text('Sell Item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add item photo'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Choose a JPEG, PNG, or WebP image.'),
      findsOneWidget,
    );
    file = XFile.fromData(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      ),
      name: 'item.png',
      mimeType: 'image/png',
    );
    await tester.tap(find.text('Add item photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    expect(find.text('Add item photo'), findsOneWidget);
    expect(find.text('Remove photo'), findsNothing);
  });
}

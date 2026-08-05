import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zitface_mobile/screens/signup_screen.dart';

void main() {
  testWidgets('signup screen renders its auth card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignUpScreen(),
      ),
    );

    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(RichText), findsWidgets);
  });
}

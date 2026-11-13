import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zitface_mobile/screens/login_screen.dart';
import 'package:zitface_mobile/screens/signup_screen.dart';

void main() {
  testWidgets('login requires Supabase configuration instead of fake success', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.enterText(find.byType(TextField).first, 'student@example.com');
    await tester.enterText(find.byType(TextField).last, 'correct-horse');
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Configure Supabase to sign in.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('resend confirmation requires Supabase configuration', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.enterText(find.byType(TextField).first, 'student@example.com');
    await tester.tap(find.text('Resend confirmation email'));
    await tester.pump();

    expect(
      find.text('Configure Supabase to resend a confirmation email.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'signup requires Supabase configuration instead of fake success',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

      await tester.enterText(
        find.widgetWithText(TextField, 'Display name'),
        'Campus Student',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email address'),
        'student@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'correct-horse',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm password'),
        'correct-horse',
      );
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(
        find.text('Configure Supabase to create an account.'),
        findsOneWidget,
      );
      expect(find.byType(SignUpScreen), findsOneWidget);
    },
  );
}

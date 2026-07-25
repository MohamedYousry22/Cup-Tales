import 'package:cup_tales/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Google auth button shows its label and invokes the callback', (
    tester,
  ) async {
    var wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoogleAuthButton(
            label: 'Continue with Google',
            onPressed: () => wasPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Continue with Google'), findsOneWidget);
    await tester.tap(find.byType(GoogleAuthButton));
    expect(wasPressed, isTrue);
  });
}

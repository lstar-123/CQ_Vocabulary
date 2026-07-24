import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/features/login/login_screen.dart';

/// Smoke tests for the Login screen UI.
///
/// These are NOT integration tests — they verify widget rendering
/// and form validation without a real backend.
void main() {
  testWidgets('LoginScreen renders two tabs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Two tab labels should be visible.
    expect(find.text('Student'), findsWidgets);
    expect(find.text('Teacher'), findsWidgets);
  });

  testWidgets('LoginScreen has login buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // At least one FilledButton is present.
    expect(find.byType(FilledButton), findsWidgets);
  });

  testWidgets('LoginScreen shows error when submitting empty form', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Tap the first login button without entering credentials.
    final buttons = find.byType(FilledButton);
    await tester.tap(buttons.first);
    await tester.pump();

    // Form validation error should appear.
    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('LoginScreen shows password visibility toggle', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Visibility toggle icons should be present.
    expect(find.byIcon(Icons.visibility_off_outlined), findsWidgets);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/features/quiz/quiz_screen.dart';

/// Smoke tests for QuizScreen UI rendering.
void main() {
  testWidgets('QuizScreen renders app bar with unit name', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuizScreen(unitId: 1, unitName: 'Unit 1'),
        ),
      ),
    );

    expect(find.text('Unit 1'), findsOneWidget);
  });

  testWidgets('QuizScreen shows loading initially', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuizScreen(unitId: 1, unitName: 'Unit 1'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('QuizScreen renders Scaffold without crash', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuizScreen(unitId: 1, unitName: 'Unit 1'),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The screen renders either loading, error with retry, or empty.
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

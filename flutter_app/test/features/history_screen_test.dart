import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/features/history/history_screen.dart';

/// Smoke tests for HistoryScreen UI rendering.
void main() {
  testWidgets('HistoryScreen renders app bar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );

    expect(find.text('Quiz History'), findsOneWidget);
  });

  testWidgets('HistoryScreen shows loading initially', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HistoryScreen renders without crash', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Either loading, empty, or error — but never crashes.
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

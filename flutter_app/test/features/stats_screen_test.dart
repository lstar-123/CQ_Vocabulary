import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/features/stats/stats_screen.dart';

/// Smoke tests for Statistics Dashboard UI rendering.
void main() {
  testWidgets('StatsScreen renders app bar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StatsScreen(),
        ),
      ),
    );

    expect(find.text('Statistics'), findsOneWidget);
  });

  testWidgets('StatsScreen shows loading initially', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StatsScreen(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('StatsScreen renders without crash', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StatsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Loading, error with retry, or empty state — always renders.
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

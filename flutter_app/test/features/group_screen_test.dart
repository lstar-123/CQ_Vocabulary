import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/features/group/group_screen.dart';

/// Smoke tests for GroupScreen UI rendering.
void main() {
  testWidgets('GroupScreen renders app bar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: GroupScreen(unitId: 1, unitName: 'Unit 1'),
        ),
      ),
    );

    expect(find.text('Unit 1'), findsOneWidget);
  });

  testWidgets('GroupScreen shows loading initially', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: GroupScreen(unitId: 1, unitName: 'Unit 1'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

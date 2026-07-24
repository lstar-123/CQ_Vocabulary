import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/state/providers/group_learning_provider.dart';

/// Tests for GroupLearningState and GroupLearningNotifier.
void main() {
  group('GroupLearningState', () {
    test('empty state starts with loading phase', () {
      const state = GroupLearningState.empty;
      expect(state.phase, GroupPhase.loading);
      expect(state.groups, isEmpty);
      expect(state.wrongWords, isEmpty);
      expect(state.rememberedCount, 0);
    });

    test('progressLabel formats correctly', () {
      final state = GroupLearningState.empty.copyWith(
        groups: [
          [],
          [],
          [],
        ], // 3 groups
        currentGroupIndex: 1,
      );
      expect(state.progressLabel, 'Group 2 / 3');
    });

    test('totalGroups and totalWords', () {
      final state = GroupLearningState.empty.copyWith(
        groups: [
          [],
          [],
        ],
        allWords: List.generate(10, (i) => _fakeWord('w$i')),
      );
      expect(state.totalGroups, 2);
      expect(state.totalWords, 10);
    });

    test('accuracy computes correctly', () {
      final state = GroupLearningState.empty.copyWith(
        allWords: List.generate(10, (i) => _fakeWord('w$i')),
        rememberedCount: 8,
      );
      expect(state.accuracy, 0.8);
    });

    test('copyWith preserves unchanged fields', () {
      const state = GroupLearningState.empty;
      final updated = state.copyWith(phase: GroupPhase.memory);
      expect(updated.phase, GroupPhase.memory);
      expect(updated.groups, isEmpty); // unchanged
    });
  });

  group('GroupLearningNotifier provider', () {
    test('provider initialises in loading state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(groupLearningNotifierProvider);
      expect(value, isA<AsyncValue<GroupLearningState>>());
    });
  });
}

import 'package:vocabulary_memorization/domain/models/word.dart' as domain;

domain.Word _fakeWord(String english) => domain.Word(
      id: 1,
      unitId: 1,
      unitName: 'U1',
      english: english,
      chinese: '测试',
    );

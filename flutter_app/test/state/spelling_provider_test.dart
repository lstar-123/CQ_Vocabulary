import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/domain/models/spelling.dart';
import 'package:vocabulary_memorization/state/providers/spelling_provider.dart';

/// Tests for SpellingNotifier and SpellingChecker.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ────────────────────────────────────────────────────────────
  // SpellingChecker — comparison logic
  // ────────────────────────────────────────────────────────────
  group('SpellingChecker', () {
    test('exact match', () {
      expect(SpellingChecker.check('apple', 'apple'), isTrue);
    });

    test('case insensitive match', () {
      expect(SpellingChecker.check('Apple', 'apple'), isTrue);
      expect(SpellingChecker.check('APPLE', 'apple'), isTrue);
      expect(SpellingChecker.check('aPpLe', 'apple'), isTrue);
    });

    test('trims whitespace', () {
      expect(SpellingChecker.check('  apple  ', 'apple'), isTrue);
      expect(SpellingChecker.check('apple ', 'apple'), isTrue);
    });

    test('mismatch', () {
      expect(SpellingChecker.check('apples', 'apple'), isFalse);
      expect(SpellingChecker.check('', 'apple'), isFalse);
    });

    test('empty vs empty', () {
      expect(SpellingChecker.check('', ''), isTrue);
      expect(SpellingChecker.check('  ', ''), isTrue);
    });

    test('multi-word comparison', () {
      expect(
        SpellingChecker.check('good morning', 'Good Morning'),
        isTrue,
      );
      expect(
        SpellingChecker.check('  Good   Morning  ', 'Good Morning'),
        isFalse, // internal whitespace is NOT collapsed — only trim
      );
    });
  });

  // ────────────────────────────────────────────────────────────
  // SpellingState — immutable copyWith
  // ────────────────────────────────────────────────────────────
  group('SpellingState', () {
    test('copyWith preserves unchanged fields', () {
      const state = SpellingState(
        words: [],
        currentIndex: 0,
        results: [],
        currentInput: '',
        isPlaying: false,
        showResult: false,
      );

      final updated = state.copyWith(currentInput: 'hello');

      expect(updated.currentInput, 'hello');
      expect(updated.currentIndex, 0); // unchanged
      expect(updated.isPlaying, false); // unchanged
    });

    test('currentResult returns result for current index', () {
      final state = SpellingState(
        words: [],
        currentIndex: 1,
        results: [
          const SpellingResult(
            word: _fakeWord('a', 'A'),
            userAnswer: 'a',
            isCorrect: true,
          ),
          const SpellingResult(
            word: _fakeWord('b', 'B'),
            userAnswer: 'x',
            isCorrect: false,
          ),
        ],
        currentInput: '',
        isPlaying: false,
        showResult: true,
      );

      expect(state.currentResult!.isCorrect, isFalse);
    });
  });
}

// Minimal fake Word for tests — avoids depending on actual model.
import 'package:vocabulary_memorization/domain/models/word.dart' as domain;

domain.Word _fakeWord(String english, String chinese) {
  return domain.Word(
    id: 1,
    unitId: 1,
    unitName: 'Unit 1',
    english: english,
    chinese: chinese,
  );
}

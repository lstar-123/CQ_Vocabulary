import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/domain/models/quiz_question.dart';
import 'package:vocabulary_memorization/domain/models/word.dart' as domain;

/// Tests for QuizQuestionGenerator and QuizState.
void main() {
  // ────────────────────────────────────────────────────────────
  // QuizQuestionGenerator
  // ────────────────────────────────────────────────────────────
  group('QuizQuestionGenerator', () {
    final words = List.generate(
      10,
      (i) => domain.Word(
        id: i + 1,
        unitId: 1,
        unitName: 'Unit 1',
        english: 'word_$i',
        chinese: '中文_$i',
      ),
    );

    test('generates one question per word', () {
      final questions = QuizQuestionGenerator.generate(words, shuffle: false);

      expect(questions.length, words.length);
    });

    test('each question has exactly 4 options', () {
      final questions = QuizQuestionGenerator.generate(words);

      for (final q in questions) {
        expect(q.options.length, 4);
      }
    });

    test('correctIndex points to the correct Chinese', () {
      final questions = QuizQuestionGenerator.generate(words, shuffle: false);

      for (final q in questions) {
        expect(q.options[q.correctIndex], q.word.chinese);
      }
    });

    test('isCorrect returns true only for correct index', () {
      final questions = QuizQuestionGenerator.generate(words, shuffle: false);

      for (final q in questions) {
        expect(q.isCorrect(q.correctIndex), isTrue);
        // Any other index should be false (unless dupes exist).
        for (var i = 0; i < q.options.length; i++) {
          if (i != q.correctIndex) {
            // Could still match if options have duplicates.
            final actuallyWrong = q.options[i] != q.correctAnswer;
            if (actuallyWrong) {
              expect(q.isCorrect(i), isFalse);
            }
          }
        }
      }
    });

    test('shuffled questions have different order than input', () {
      // With many words, shuffled order is almost certainly different.
      final ordered = QuizQuestionGenerator.generate(words, shuffle: false);
      final shuffled = QuizQuestionGenerator.generate(words, shuffle: true);

      final orderedEng =
          ordered.map((q) => q.word.english).toList();
      final shuffledEng =
          shuffled.map((q) => q.word.english).toList();

      // They might coincidentally match, but extremely unlikely with 10 items.
      final sameOrder = _listEquals(orderedEng, shuffledEng);
      // Not an assertion — just informational. Random could match.
      if (sameOrder) {
        // Run again to verify randomness.
        final reshuffled =
            QuizQuestionGenerator.generate(words, shuffle: true);
        final reshuffledEng =
            reshuffled.map((q) => q.word.english).toList();
        expect(
          _listEquals(orderedEng, reshuffledEng),
          isFalse,
          reason: 'Shuffled order should differ from original after two tries',
        );
      }
    });

    test('handles fewer than 4 unique Chinese distractor words', () {
      // Only 2 distinct Chinese values — distractors will be limited.
      final fewWords = [
        domain.Word(
            id: 1, unitId: 1, unitName: 'U1', english: 'a', chinese: '甲'),
        domain.Word(
            id: 2, unitId: 1, unitName: 'U1', english: 'b', chinese: '甲'),
        domain.Word(
            id: 3, unitId: 1, unitName: 'U1', english: 'c', chinese: '乙'),
      ];

      final questions =
          QuizQuestionGenerator.generate(fewWords, shuffle: false);

      // Should not crash — options may have fewer than 4 unique values.
      for (final q in questions) {
        expect(q.options.isNotEmpty, isTrue);
        expect(q.options.length <= 4, isTrue);
        expect(q.options[q.correctIndex], q.word.chinese);
      }
    });
  });
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

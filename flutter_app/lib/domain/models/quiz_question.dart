import 'dart:math';

import 'word.dart';

/// A single quiz question: English prompt + 4 Chinese options.
///
/// Options are generated client-side from the word pool.
/// [correctIndex] always points to the correct Chinese translation.
class QuizQuestion {
  const QuizQuestion({
    required this.word,
    required this.options,
    required this.correctIndex,
  });

  final Word word;
  final List<String> options;
  final int correctIndex;

  String get correctAnswer => options[correctIndex];

  /// Check whether the selected option is correct.
  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;
}

/// Generates quiz questions from a list of words.
///
/// Each question presents the English word and four Chinese options:
/// one correct + three random distractors from the pool.
abstract final class QuizQuestionGenerator {
  static const int _optionCount = 4;

  /// Generate questions for the given [words].
  ///
  /// If [shuffle] is true (default), questions and options are
  /// randomised using the provided [random] source.
  static List<QuizQuestion> generate(
    List<Word> words, {
    bool shuffle = true,
    Random? random,
  }) {
    final rng = random ?? Random();
    final pool = words.toList(growable: false);
    if (shuffle) pool.shuffle(rng);

    // Collect all Chinese translations for distractor sampling.
    final allChinese = words.map((w) => w.chinese).toSet().toList();

    return pool.map((word) {
      final correct = word.chinese;

      // Pick distractors: any Chinese != correct.
      final distractors = allChinese
          .where((c) => c != correct)
          .toList(growable: false);
      distractors.shuffle(rng);

      final pickedDistractors =
          distractors.take(_optionCount - 1).toList(growable: false);

      // Assemble and shuffle options.
      final options = [correct, ...pickedDistractors];
      // Use index-based shuffle to track correct position.
      final indices = List.generate(options.length, (i) => i);
      indices.shuffle(rng);

      final shuffledOptions =
          indices.map((i) => options[i]).toList(growable: false);
      final correctIndex = shuffledOptions.indexOf(correct);

      return QuizQuestion(
        word: word,
        options: shuffledOptions,
        correctIndex: correctIndex,
      );
    }).toList(growable: false);
  }
}

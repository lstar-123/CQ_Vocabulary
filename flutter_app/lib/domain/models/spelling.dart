import 'word.dart';

/// The result of a single spelling attempt.
class SpellingResult {
  const SpellingResult({
    required this.word,
    required this.userAnswer,
    required this.isCorrect,
    this.skipped = false,
  });

  final Word word;
  final String userAnswer;
  final bool isCorrect;
  final bool skipped;

  /// The trimmed-and-lowered answer that was compared.
  String get normalizedAnswer => userAnswer.trim().toLowerCase();
}

/// Domain-level string comparison for spelling.
///
/// Case-insensitive, whitespace-insensitive. The UI layer never
/// does its own comparison — it calls [SpellingChecker.check].
abstract final class SpellingChecker {
  /// Returns `true` when [userAnswer] matches [correctAnswer] after
  /// normalisation (trim + lowercase).
  static bool check(String userAnswer, String correctAnswer) {
    return userAnswer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
  }
}

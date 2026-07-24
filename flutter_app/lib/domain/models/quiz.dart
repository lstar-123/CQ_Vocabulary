/// Domain models for quiz sessions.
///
/// Key difference from DTOs: [unitIds] is [List<int>] here,
/// while the backend sends it as a comma-separated String.
/// The [QuizMapper] performs this conversion.
class QuizSession {
  const QuizSession({
    required this.id,
    required this.unitIds,
    required this.totalCount,
    required this.correctCount,
    required this.scorePct,
    this.durationSeconds,
    this.bookSchema,
    this.completedAt,
  });

  final int id;
  final List<int> unitIds;
  final int totalCount;
  final int correctCount;
  final double scorePct;
  final int? durationSeconds;
  final String? bookSchema;
  final String? completedAt;

  double get accuracy => totalCount > 0 ? correctCount / totalCount : 0;
}

class QuizSessionDetail {
  const QuizSessionDetail({
    required this.id,
    required this.unitIds,
    required this.totalCount,
    required this.correctCount,
    required this.scorePct,
    this.durationSeconds,
    this.bookSchema,
    this.completedAt,
    required this.answers,
  });

  final int id;
  final List<int> unitIds;
  final int totalCount;
  final int correctCount;
  final double scorePct;
  final int? durationSeconds;
  final String? bookSchema;
  final String? completedAt;
  final List<QuizAnswer> answers;

  double get accuracy => totalCount > 0 ? correctCount / totalCount : 0;
}

class QuizAnswer {
  const QuizAnswer({
    required this.wordId,
    required this.chinese,
    required this.english,
    required this.userAnswer,
    required this.isCorrect,
  });

  final int wordId;
  final String chinese;
  final String english;
  final String userAnswer;
  final bool isCorrect;
}

/// Result returned after submitting a quiz.
class QuizResult {
  const QuizResult({
    required this.sessionId,
    required this.totalCount,
    required this.correctCount,
    required this.scorePct,
  });

  final int sessionId;
  final int totalCount;
  final int correctCount;
  final double scorePct;

  double get accuracy => totalCount > 0 ? correctCount / totalCount : 0;
}

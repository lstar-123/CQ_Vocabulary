/// Quiz session DTOs — mapped from quiz submission, history, and teacher APIs.
///
/// Backend sources:
///   POST /api/quiz/submit       → QuizSubmitResponse
///   GET  /api/history           → QuizSessionBrief (in PaginatedResponse)
///   GET  /api/history/<id>      → QuizSessionDetail
library;

/// Appears in history lists and teacher student sessions.
class QuizSessionBrief {
  const QuizSessionBrief({
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
  final String unitIds; // "1,2,3" — Repository converts to/from List<int>
  final int totalCount;
  final int correctCount;
  final double scorePct;
  final int? durationSeconds;
  final String? bookSchema;
  final String? completedAt; // ISO 8601

  factory QuizSessionBrief.fromJson(Map<String, dynamic> json) {
    return QuizSessionBrief(
      id: json['id'] as int,
      unitIds: json['unit_ids'] as String,
      totalCount: json['total_count'] as int,
      correctCount: json['correct_count'] as int,
      scorePct: (json['score_pct'] as num).toDouble(),
      durationSeconds: json['duration_seconds'] as int?,
      bookSchema: json['book_schema'] as String?,
      completedAt: json['completed_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_ids': unitIds,
      'total_count': totalCount,
      'correct_count': correctCount,
      'score_pct': scorePct,
      'duration_seconds': durationSeconds,
      'book_schema': bookSchema,
      'completed_at': completedAt,
    };
  }
}

/// Full quiz session with answer details.
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
  final String unitIds;
  final int totalCount;
  final int correctCount;
  final double scorePct;
  final int? durationSeconds;
  final String? bookSchema;
  final String? completedAt;
  final List<QuizAnswerItem> answers;

  factory QuizSessionDetail.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as List<dynamic>? ?? [];
    return QuizSessionDetail(
      id: json['id'] as int,
      unitIds: json['unit_ids'] as String,
      totalCount: json['total_count'] as int,
      correctCount: json['correct_count'] as int,
      scorePct: (json['score_pct'] as num).toDouble(),
      durationSeconds: json['duration_seconds'] as int?,
      bookSchema: json['book_schema'] as String?,
      completedAt: json['completed_at'] as String?,
      answers: rawAnswers
          .map((a) => QuizAnswerItem.fromJson(a as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

/// A single answer within a quiz session.
class QuizAnswerItem {
  const QuizAnswerItem({
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

  factory QuizAnswerItem.fromJson(Map<String, dynamic> json) {
    return QuizAnswerItem(
      wordId: json['word_id'] as int,
      chinese: json['chinese'] as String,
      english: json['english'] as String,
      userAnswer: json['user_answer'] as String,
      isCorrect: json['is_correct'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word_id': wordId,
      'chinese': chinese,
      'english': english,
      'user_answer': userAnswer,
      'is_correct': isCorrect,
    };
  }
}

// ── Quiz Submission ──────────────────────────────────────────

/// Request body for POST /api/quiz/submit.
class QuizSubmitRequest {
  const QuizSubmitRequest({
    required this.unitIds,
    required this.answers,
    this.durationSeconds,
    this.bookSchema,
  });

  final List<int> unitIds;
  final List<AnswerSubmit> answers;
  final int? durationSeconds;
  final String? bookSchema;

  Map<String, dynamic> toJson() {
    return {
      'unit_ids': unitIds,
      'answers': answers.map((a) => a.toJson()).toList(),
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (bookSchema != null) 'book_schema': bookSchema,
    };
  }
}

class AnswerSubmit {
  const AnswerSubmit({
    required this.wordId,
    required this.userAnswer,
    required this.isCorrect,
  });

  final int wordId;
  final String userAnswer;
  final bool isCorrect;

  Map<String, dynamic> toJson() {
    return {
      'word_id': wordId,
      'user_answer': userAnswer,
      'is_correct': isCorrect,
    };
  }
}

/// Response from POST /api/quiz/submit.
class QuizSubmitResponse {
  const QuizSubmitResponse({
    required this.sessionId,
    required this.totalCount,
    required this.correctCount,
    required this.scorePct,
  });

  final int sessionId;
  final int totalCount;
  final int correctCount;
  final double scorePct;

  factory QuizSubmitResponse.fromJson(Map<String, dynamic> json) {
    return QuizSubmitResponse(
      sessionId: json['session_id'] as int,
      totalCount: json['total_count'] as int,
      correctCount: json['correct_count'] as int,
      scorePct: (json['score_pct'] as num).toDouble(),
    );
  }
}

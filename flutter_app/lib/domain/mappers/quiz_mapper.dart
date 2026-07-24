import '../../models/quiz_session.dart' as dto;
import '../models/quiz.dart' as domain;

abstract final class QuizMapper {
  /// Convert comma-separated unit_ids String → List<int>.
  static List<int> _parseUnitIds(String s) {
    if (s.isEmpty) return [];
    return s.split(',').map((e) => int.parse(e.trim())).toList(growable: false);
  }

  static domain.QuizSession fromBriefDto(dto.QuizSessionBrief d) {
    return domain.QuizSession(
      id: d.id,
      unitIds: _parseUnitIds(d.unitIds),
      totalCount: d.totalCount,
      correctCount: d.correctCount,
      scorePct: d.scorePct,
      durationSeconds: d.durationSeconds,
      bookSchema: d.bookSchema,
      completedAt: d.completedAt,
    );
  }

  static domain.QuizSessionDetail fromDetailDto(dto.QuizSessionDetail d) {
    return domain.QuizSessionDetail(
      id: d.id,
      unitIds: _parseUnitIds(d.unitIds),
      totalCount: d.totalCount,
      correctCount: d.correctCount,
      scorePct: d.scorePct,
      durationSeconds: d.durationSeconds,
      bookSchema: d.bookSchema,
      completedAt: d.completedAt,
      answers: d.answers.map(_answer).toList(growable: false),
    );
  }

  static domain.QuizAnswer _answer(dto.QuizAnswerItem a) {
    return domain.QuizAnswer(
      wordId: a.wordId,
      chinese: a.chinese,
      english: a.english,
      userAnswer: a.userAnswer,
      isCorrect: a.isCorrect,
    );
  }

  static domain.QuizResult fromSubmitResponseDto(dto.QuizSubmitResponse d) {
    return domain.QuizResult(
      sessionId: d.sessionId,
      totalCount: d.totalCount,
      correctCount: d.correctCount,
      scorePct: d.scorePct,
    );
  }
}

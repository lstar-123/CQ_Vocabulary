/// Statistics DTOs — mapped from GET /api/stats/* endpoints.
///
/// Backend sources:
///   GET /api/stats/trend    → List<TrendPoint>
///   GET /api/stats/summary  → StatsSummary
library;

/// A single data point in the score trend.
class TrendPoint {
  const TrendPoint({
    required this.date,
    required this.scorePct,
    required this.totalCount,
    required this.correctCount,
    required this.unitIds,
    required this.unitNames,
    this.unitScores,
  });

  final String date;
  final double scorePct;
  final int totalCount;
  final int correctCount;
  final String unitIds;
  final List<String> unitNames;
  final Map<String, UnitScore>? unitScores;

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    final rawUnitScores =
        json['unit_scores'] as Map<String, dynamic>?;
    final rawNames = json['unit_names'] as List<dynamic>? ?? [];

    return TrendPoint(
      date: json['date'] as String,
      scorePct: (json['score_pct'] as num).toDouble(),
      totalCount: json['total_count'] as int,
      correctCount: json['correct_count'] as int,
      unitIds: json['unit_ids'] as String,
      unitNames: rawNames.map((n) => n as String).toList(growable: false),
      unitScores: rawUnitScores?.map(
        (k, v) => MapEntry(k, UnitScore.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}

class UnitScore {
  const UnitScore({
    required this.total,
    required this.correct,
    required this.scorePct,
  });

  final int total;
  final int correct;
  final double scorePct;

  factory UnitScore.fromJson(Map<String, dynamic> json) {
    return UnitScore(
      total: json['total'] as int,
      correct: json['correct'] as int,
      scorePct: (json['score_pct'] as num).toDouble(),
    );
  }
}

/// Response from GET /api/stats/summary.
class StatsSummary {
  const StatsSummary({
    required this.totalQuizzes,
    required this.avgScore,
    required this.bestScore,
    required this.totalWordsTested,
    required this.totalCorrect,
    required this.totalUnitsStudied,
    required this.totalGroupSessions,
  });

  final int totalQuizzes;
  final double avgScore;
  final double bestScore;
  final int totalWordsTested;
  final int totalCorrect;
  final int totalUnitsStudied;
  final int totalGroupSessions;

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    return StatsSummary(
      totalQuizzes: json['total_quizzes'] as int,
      avgScore: (json['avg_score'] as num).toDouble(),
      bestScore: (json['best_score'] as num).toDouble(),
      totalWordsTested: json['total_words_tested'] as int,
      totalCorrect: json['total_correct'] as int,
      totalUnitsStudied: json['total_units_studied'] as int,
      totalGroupSessions: json['total_group_sessions'] as int,
    );
  }
}

/// Domain models for learning statistics.
class ScoreTrend {
  const ScoreTrend({
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
  final List<int> unitIds;
  final List<String> unitNames;
  final Map<int, UnitScore>? unitScores;

  double get accuracy => totalCount > 0 ? correctCount / totalCount : 0;
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
}

class StudySummary {
  const StudySummary({
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

  double get overallAccuracy =>
      totalWordsTested > 0 ? totalCorrect / totalWordsTested : 0;
}

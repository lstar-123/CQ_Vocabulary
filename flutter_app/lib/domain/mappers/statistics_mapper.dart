import '../../models/statistics.dart' as dto;
import '../models/statistics.dart' as domain;

abstract final class StatisticsMapper {
  static domain.ScoreTrend fromTrendPointDto(dto.TrendPoint d) {
    return domain.ScoreTrend(
      date: d.date,
      scorePct: d.scorePct,
      totalCount: d.totalCount,
      correctCount: d.correctCount,
      unitIds: _parseUnitIds(d.unitIds),
      unitNames: d.unitNames,
      unitScores: d.unitScores?.map(
        (k, v) => MapEntry(int.parse(k), _unitScore(v)),
      ),
    );
  }

  static domain.UnitScore _unitScore(dto.UnitScore s) {
    return domain.UnitScore(
      total: s.total,
      correct: s.correct,
      scorePct: s.scorePct,
    );
  }

  static domain.StudySummary fromSummaryDto(dto.StatsSummary d) {
    return domain.StudySummary(
      totalQuizzes: d.totalQuizzes,
      avgScore: d.avgScore,
      bestScore: d.bestScore,
      totalWordsTested: d.totalWordsTested,
      totalCorrect: d.totalCorrect,
      totalUnitsStudied: d.totalUnitsStudied,
      totalGroupSessions: d.totalGroupSessions,
    );
  }

  static List<int> _parseUnitIds(String s) {
    if (s.isEmpty) return [];
    return s.split(',').map((e) => int.parse(e.trim())).toList(growable: false);
  }
}

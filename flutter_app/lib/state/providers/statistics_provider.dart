import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/learning_record.dart' as domain;
import '../../domain/models/statistics.dart' as domain;
import '../../repositories/stats_repository.dart';

/// Aggregated statistics state — all data in one immutable object.
class StatisticsState {
  const StatisticsState({
    required this.summary,
    required this.trend,
    required this.recentRecords,
    required this.loadedAt,
  });

  final domain.StudySummary summary;
  final List<domain.ScoreTrend> trend;
  final List<domain.LearningRecord> recentRecords;
  final DateTime loadedAt;

  bool get isEmpty =>
      summary.totalQuizzes == 0 &&
      summary.totalGroupSessions == 0 &&
      trend.isEmpty;

  /// Last 7 trend points for the accuracy chart.
  List<domain.ScoreTrend> get recentTrend {
    if (trend.length <= 7) return trend;
    return trend.sublist(trend.length - 7);
  }

  /// Build weekly activity buckets from trend data.
  /// Returns last 7 days as [WeekDay] list.
  List<WeekDay> get weeklyActivity {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    return days.map((day) {
      final match = trend.where((t) {
        // Trend dates are "MM-dd HH:mm"
        final parts = t.date.split(' ');
        if (parts.isEmpty) return false;
        final dp = parts[0].split('-');
        if (dp.length < 2) return false;
        final m = int.tryParse(dp[0]) ?? 0;
        final d = int.tryParse(dp[1]) ?? 0;
        return m == day.month && d == day.day;
      }).toList();

      return WeekDay(
        label: _dayLabel(day.weekday),
        quizCount: match.length,
        totalWords: match.fold<int>(0, (s, t) => s + t.totalCount),
      );
    }).toList();
  }

  /// Estimated streak based on consecutive days with quizzes.
  int get estimatedStreak {
    if (trend.isEmpty) return 0;
    // Simple: count unique recent days.
    final daySet = <String>{};
    for (final t in trend) {
      final parts = t.date.split(' ');
      if (parts.isNotEmpty) daySet.add(parts[0]);
    }
    return daySet.length.clamp(0, 999);
  }

  static String _dayLabel(int weekday) {
    return switch (weekday) {
      1 => 'Mon',
      2 => 'Tue',
      3 => 'Wed',
      4 => 'Thu',
      5 => 'Fri',
      6 => 'Sat',
      7 => 'Sun',
      _ => '',
    };
  }
}

class WeekDay {
  const WeekDay({
    required this.label,
    required this.quizCount,
    required this.totalWords,
  });

  final String label;
  final int quizCount;
  final int totalWords;
}

/// Fetches and aggregates all statistics from the backend.
class StatisticsNotifier extends AsyncNotifier<StatisticsState> {
  @override
  Future<StatisticsState> build() async {
    return _loadAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadAll());
  }

  Future<StatisticsState> _loadAll() async {
    final repo = StatsRepository();
    final results = await Future.wait([
      repo.getSummary(),
      repo.getTrend(),
      repo.getGroupHistory(),
    ]);

    return StatisticsState(
      summary: results[0] as domain.StudySummary,
      trend: results[1] as List<domain.ScoreTrend>,
      recentRecords: (results[2] as List<domain.LearningRecord>).take(10).toList(),
      loadedAt: DateTime.now(),
    );
  }
}

final statisticsNotifierProvider =
    AsyncNotifierProvider<StatisticsNotifier, StatisticsState>(
  StatisticsNotifier.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/domain/models/statistics.dart' as domain;
import 'package:vocabulary_memorization/state/providers/statistics_provider.dart';

/// Tests for StatisticsState computed properties.
void main() {
  group('StatisticsState', () {
    test('isEmpty returns true when no data', () {
      const state = StatisticsState(
        summary: domain.StudySummary(
          totalQuizzes: 0,
          avgScore: 0,
          bestScore: 0,
          totalWordsTested: 0,
          totalCorrect: 0,
          totalUnitsStudied: 0,
          totalGroupSessions: 0,
        ),
        trend: [],
        recentRecords: [],
        loadedAt: null,
      );

      expect(state.isEmpty, isTrue);
    });

    test('isEmpty returns false when there is data', () {
      final state = StatisticsState(
        summary: const domain.StudySummary(
          totalQuizzes: 1,
          avgScore: 80,
          bestScore: 100,
          totalWordsTested: 10,
          totalCorrect: 8,
          totalUnitsStudied: 1,
          totalGroupSessions: 0,
        ),
        trend: [],
        recentRecords: [],
        loadedAt: DateTime.now(),
      );

      expect(state.isEmpty, isFalse);
    });

    test('weeklyActivity returns 7 days', () {
      final today = DateTime.now();
      final state = StatisticsState(
        summary: const domain.StudySummary(
          totalQuizzes: 0,
          avgScore: 0,
          bestScore: 0,
          totalWordsTested: 0,
          totalCorrect: 0,
          totalUnitsStudied: 0,
          totalGroupSessions: 0,
        ),
        trend: [
          domain.ScoreTrend(
            date:
                '${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')} 10:00',
            scorePct: 80,
            totalCount: 10,
            correctCount: 8,
            unitIds: '1',
            unitNames: ['Unit 1'],
          ),
        ],
        recentRecords: [],
        loadedAt: DateTime.now(),
      );

      final week = state.weeklyActivity;
      expect(week.length, 7);

      // Today should have 1 quiz with 10 words.
      final todayDay = week[6];
      expect(todayDay.quizCount, 1);
      expect(todayDay.totalWords, 10);
    });

    test('recentTrend caps at 7 items', () {
      final state = StatisticsState(
        summary: const domain.StudySummary(
          totalQuizzes: 10,
          avgScore: 0,
          bestScore: 0,
          totalWordsTested: 0,
          totalCorrect: 0,
          totalUnitsStudied: 0,
          totalGroupSessions: 0,
        ),
        trend: List.generate(
          20,
          (i) => domain.ScoreTrend(
            date: '07-${(i + 1).toString().padLeft(2, '0')} 10:00',
            scorePct: 50 + i * 2.0,
            totalCount: 5,
            correctCount: 3,
            unitIds: '1',
            unitNames: ['Unit 1'],
          ),
        ),
        recentRecords: [],
        loadedAt: DateTime.now(),
      );

      expect(state.recentTrend.length, 7);
    });

    test('estimatedStreak counts unique days', () {
      final state = StatisticsState(
        summary: const domain.StudySummary(
          totalQuizzes: 0,
          avgScore: 0,
          bestScore: 0,
          totalWordsTested: 0,
          totalCorrect: 0,
          totalUnitsStudied: 0,
          totalGroupSessions: 0,
        ),
        trend: [
          domain.ScoreTrend(
            date: '07-20 10:00',
            scorePct: 80,
            totalCount: 5,
            correctCount: 4,
            unitIds: '1',
            unitNames: ['Unit 1'],
          ),
          domain.ScoreTrend(
            date: '07-21 10:00',
            scorePct: 90,
            totalCount: 5,
            correctCount: 4,
            unitIds: '1',
            unitNames: ['Unit 1'],
          ),
          domain.ScoreTrend(
            date: '07-21 14:00',
            scorePct: 95,
            totalCount: 5,
            correctCount: 5,
            unitIds: '1',
            unitNames: ['Unit 1'],
          ),
        ],
        recentRecords: [],
        loadedAt: DateTime.now(),
      );

      // 2 unique days (07-20, 07-21)
      expect(state.estimatedStreak, 2);
    });
  });

  group('WeekDay', () {
    test('WeekDay holds correct values', () {
      const day = WeekDay(label: 'Mon', quizCount: 3, totalWords: 30);
      expect(day.label, 'Mon');
      expect(day.quizCount, 3);
      expect(day.totalWords, 30);
    });
  });

  group('StatisticsNotifier provider', () {
    test('provider initialises and can be read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Provider should be readable without crash.
      final provider = container.read(statisticsNotifierProvider);
      expect(provider, isA<AsyncValue<StatisticsState>>());
    });
  });
}

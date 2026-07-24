import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/statistics.dart' as domain;

/// Learning distribution donut chart.
///
/// Shows breakdown by mode: Flashcard + Spelling + Quiz.
/// Since the backend doesn't track mode-level stats, we show
/// quiz vs group-learning distribution.
class DistributionDonut extends StatelessWidget {
  const DistributionDonut({super.key, required this.summary});

  final domain.StudySummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Quiz sessions vs group-learning sessions.
    final quizPct = summary.totalQuizzes + summary.totalGroupSessions > 0
        ? summary.totalQuizzes /
            (summary.totalQuizzes + summary.totalGroupSessions)
        : 0.0;
    final groupPct = 1.0 - quizPct;

    if (summary.totalQuizzes == 0 && summary.totalGroupSessions == 0) {
      return Card(
        child: SizedBox(
          height: 140,
          child: Center(
            child: Text(
              'No data yet',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Donut
            SizedBox(
              width: 120,
              height: 120,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 32,
                  sections: [
                    PieChartSectionData(
                      value: (quizPct * 100).clamp(1, 100),
                      title: '${(quizPct * 100).round()}%',
                      titleStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                      color: colorScheme.primary,
                      radius: 32,
                    ),
                    PieChartSectionData(
                      value: (groupPct * 100).clamp(1, 100),
                      title: '${(groupPct * 100).round()}%',
                      titleStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                      color: colorScheme.tertiary,
                      radius: 32,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),

            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendDot(
                    color: colorScheme.primary,
                    label: 'Quiz',
                    value: '${summary.totalQuizzes} sessions',
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _LegendDot(
                    color: colorScheme.tertiary,
                    label: 'Group Study',
                    value: '${summary.totalGroupSessions} sessions',
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _LegendDot(
                    color: Colors.green,
                    label: 'Units Done',
                    value: '${summary.totalUnitsStudied}',
                    textTheme: textTheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final Color color;
  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: textTheme.labelMedium),
        const Spacer(),
        Text(
          value,
          style: textTheme.labelSmall?.copyWith(
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

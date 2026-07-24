import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/statistics.dart' as domain;

/// Hero summary card at the top of the Statistics dashboard.
///
/// Shows key metrics in a Material 3 elevated card with a gradient
/// accent strip. Design inspired by Google Fit.
class SummaryHeader extends StatelessWidget {
  const SummaryHeader({super.key, required this.summary, required this.trend});

  final domain.StudySummary summary;
  final List<domain.ScoreTrend> trend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.04),
              colorScheme.surface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Icon(Icons.auto_graph_rounded,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Study Summary',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Top stats row
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.menu_book_rounded,
                    value: '${summary.totalWordsTested}',
                    label: 'Words',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.quiz_rounded,
                    value: '${summary.totalQuizzes}',
                    label: 'Quizzes',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.trending_up_rounded,
                    value: '${summary.avgScore.round()}%',
                    label: 'Avg Score',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
  });

  final IconData icon;
  final String value;
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: colorScheme.primary.withOpacity(0.7)),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

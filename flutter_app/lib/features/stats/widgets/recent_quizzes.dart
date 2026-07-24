import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/statistics.dart' as domain;

/// Recent quiz sessions as cards.
class RecentQuizzes extends StatelessWidget {
  const RecentQuizzes({super.key, required this.trend});

  final List<domain.ScoreTrend> trend;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return Card(
        child: SizedBox(
          height: 100,
          child: Center(
            child: Text(
              'No recent quizzes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
            ),
          ),
        ),
      );
    }

    // Show up to 5 recent items.
    final items = trend.take(5).toList();

    return Column(
      children: items.map((item) {
        return _QuizCard(item: item);
      }).toList(),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.item});

  final domain.ScoreTrend item;

  Color _scoreColor(double pct, ColorScheme cs) {
    if (pct >= 80) return Colors.green;
    if (pct >= 60) return Colors.orange;
    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scoreColor = _scoreColor(item.scorePct, colorScheme);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: InkWell(
          onTap: () => context.go(AppRouter.historyPath),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Score circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      '${item.scorePct.round()}%',
                      style: textTheme.labelLarge?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.unitNames.join(', '),
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.date,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats
                Text(
                  '✓ ${item.correctCount}/${item.totalCount}',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

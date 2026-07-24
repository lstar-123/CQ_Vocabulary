import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/models/quiz.dart' as domain;
import '../../state/providers/history_provider.dart';

/// Quiz history screen — paginated list of past quiz sessions.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(historyNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz History')),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(err, ref, colorScheme),
        data: (state) {
          if (state.isEmpty) {
            return _buildEmpty(colorScheme, textTheme);
          }
          return _buildList(state, ref, colorScheme, textTheme);
        },
      ),
    );
  }

  Widget _buildError(Object err, WidgetRef ref, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load'),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.read(historyNotifierProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 48,
              color: colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No quiz history yet',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    HistoryState state,
    WidgetRef ref,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(historyNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            // Load-more indicator.
            ref.read(historyNotifierProvider.notifier).loadPage(state.page + 1);
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _HistoryCard(
            session: state.items[index],
            colorScheme: colorScheme,
            textTheme: textTheme,
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// History Card
// ────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.session,
    required this.colorScheme,
    required this.textTheme,
  });

  final domain.QuizSession session;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } on FormatException {
      return iso;
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '—';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  Color _scoreColor(double pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 60) return Colors.orange;
    return colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(session.scorePct);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: date + score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(session.completedAt),
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Text(
                      '${session.scorePct.round()}%',
                      style: textTheme.labelLarge?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Stats row
              Row(
                children: [
                  _MiniStat(
                    icon: Icons.check_circle_outline,
                    value: '${session.correctCount}',
                    label: 'Correct',
                    color: Colors.green,
                    textTheme: textTheme,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _MiniStat(
                    icon: Icons.cancel_outlined,
                    value: '${session.totalCount - session.correctCount}',
                    label: 'Wrong',
                    color: colorScheme.error,
                    textTheme: textTheme,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _MiniStat(
                    icon: Icons.timer_outlined,
                    value: _formatDuration(session.durationSeconds),
                    label: 'Time',
                    color: colorScheme.primary,
                    textTheme: textTheme,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.textTheme,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

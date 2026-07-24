import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../state/providers/statistics_provider.dart';
import 'widgets/accuracy_chart.dart';
import 'widgets/distribution_donut.dart';
import 'widgets/recent_quizzes.dart';
import 'widgets/summary_header.dart';
import 'widgets/weekly_chart.dart';

/// Statistics Dashboard — mobile-first, Material 3.
///
/// Design language: Google Fit / Duolingo / Material You.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(statisticsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: false,
      ),
      body: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => _ErrorCard(
          onRetry: () =>
              ref.read(statisticsNotifierProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.isEmpty) return const _EmptyState();
          return _Dashboard(state: state);
        },
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.state});

  final StatisticsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(statisticsNotifierProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          // ── Hero Summary Card ──────────────────────────
          SummaryHeader(summary: state.summary, trend: state.trend),
          const SizedBox(height: AppSpacing.lg),

          // ── Accuracy Trend ─────────────────────────────
          _SectionTitle(title: 'Accuracy Trend'),
          const SizedBox(height: AppSpacing.sm),
          AccuracyChart(trend: state.recentTrend),
          const SizedBox(height: AppSpacing.xl),

          // ── Weekly Activity ────────────────────────────
          _SectionTitle(title: 'Weekly Activity'),
          const SizedBox(height: AppSpacing.sm),
          WeeklyChart(weekDays: state.weeklyActivity),
          const SizedBox(height: AppSpacing.xl),

          // ── Learning Distribution ──────────────────────
          _SectionTitle(title: 'Learning Distribution'),
          const SizedBox(height: AppSpacing.sm),
          DistributionDonut(summary: state.summary),
          const SizedBox(height: AppSpacing.xl),

          // ── Recent Quizzes ─────────────────────────────
          _SectionTitle(
            title: 'Recent Quizzes',
            action: 'See All',
            onAction: () {
              // Navigate to history.
              Navigator.of(context).pushNamed('history');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          RecentQuizzes(trend: state.recentTrend.reversed.toList()),
        ],
      ),
    );
  }
}

/// Section title with optional action link.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!),
          ),
      ],
    );
  }
}

/// Empty state when no study data exists.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📚', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No study records yet',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start learning today!',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state with retry card.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Failed to load statistics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

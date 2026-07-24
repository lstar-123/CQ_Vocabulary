import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/statistics.dart' as domain;

/// Accuracy trend line chart (last 7 days).
///
/// Shows score_pct over time with a gradient fill.
class AccuracyChart extends StatelessWidget {
  const AccuracyChart({super.key, required this.trend});

  final List<domain.ScoreTrend> trend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (trend.isEmpty) {
      return const _EmptyChart(message: 'No accuracy data yet');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 25,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= trend.length) {
                        return const SizedBox.shrink();
                      }
                      final parts = trend[idx].date.split(' ');
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          parts[0],
                          style: TextStyle(
                            fontSize: 9,
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final idx = s.x.toInt();
                    final label =
                        idx < trend.length ? trend[idx].date : '';
                    return LineTooltipItem(
                      '$label\n${s.y.toInt()}%',
                      TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    trend.length,
                    (i) => FlSpot(i.toDouble(), trend[i].scorePct),
                  ),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: colorScheme.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: trend.length <= 10,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: colorScheme.primary,
                      strokeWidth: 1.5,
                      strokeColor: colorScheme.surface,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary.withOpacity(0.2),
                        colorScheme.primary.withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 160,
        child: Center(
          child: Text(
            message,
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
}

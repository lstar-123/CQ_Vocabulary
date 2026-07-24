import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../state/providers/statistics_provider.dart';

/// Weekly activity bar chart — 7 days, word count per day.
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key, required this.weekDays});

  final List<WeekDay> weekDays;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxWords = weekDays.fold<int>(0, (m, d) => d.totalWords > m ? d.totalWords : m);

    if (maxWords == 0) {
      return const _EmptyChart(message: 'No activity this week');
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
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxWords * 1.3).ceilToDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _niceInterval(maxWords),
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
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
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
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= weekDays.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          weekDays[idx].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day = weekDays[group.x.toInt()];
                    return BarTooltipItem(
                      '${day.totalWords} words\n${day.quizCount} quizzes',
                      TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              barGroups: List.generate(weekDays.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: weekDays[i].totalWords.toDouble(),
                      color: colorScheme.primary.withOpacity(0.7),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  double _niceInterval(int maxVal) {
    if (maxVal <= 5) return 1;
    if (maxVal <= 20) return 5;
    if (maxVal <= 50) return 10;
    if (maxVal <= 100) return 20;
    return (maxVal / 4).ceilToDouble();
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 140,
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

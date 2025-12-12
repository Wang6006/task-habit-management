import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/habit.dart';
import '../../../models/habit_status.dart';

class WeeklyActivityChart extends StatefulWidget {
  final List<HabitStatus> statuses;
  final Habit habit;

  const WeeklyActivityChart({
    super.key,
    required this.statuses,
    required this.habit,
  });

  @override
  State<WeeklyActivityChart> createState() => _WeeklyActivityChartState();
}

class _WeeklyActivityChartState extends State<WeeklyActivityChart> {
  int _selectedWeeks = 8;

  List<double> _prepareLineChartData() {
    const totalWeeks = 16;
    final now = DateTime.now();

    // Group statuses by week
    final Map<int, int> weeklyCount = {};

    for (var status in widget.statuses) {
      final weeksDiff = now.difference(status.date).inDays ~/ 7;
      if (weeksDiff < totalWeeks) {
        weeklyCount[totalWeeks - weeksDiff - 1] =
            (weeklyCount[totalWeeks - weeksDiff - 1] ?? 0) + 1;
      }
    }

    // Create data points
    return List.generate(totalWeeks, (index) {
      return (weeklyCount[index] ?? 0).toDouble().clamp(0.0, 7.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _prepareLineChartData();
    final displayData = data.sublist(data.length - _selectedWeeks, data.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Weekly Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPeriodChip(4),
                const SizedBox(width: 8),
                _buildPeriodChip(8),
                const SizedBox(width: 8),
                _buildPeriodChip(16),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'W${value.toInt() + 1}',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: (displayData.length - 1).toDouble(),
                  minY: 0,
                  maxY: 7,
                  lineBarsData: [
                    LineChartBarData(
                      spots: displayData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.5),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(int weeks) {
    final isSelected = _selectedWeeks == weeks;
    return FilterChip(
      label: Text('$weeks weeks'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedWeeks = weeks;
        });
      },
    );
  }
}

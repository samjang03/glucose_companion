// lib/presentation/widgets/analytics/time_in_range_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TimeInRangeChart extends StatelessWidget {
  final double timeInRange;
  final double timeAboveRange;
  final double timeBelowRange;

  const TimeInRangeChart({
    Key? key,
    required this.timeInRange,
    required this.timeAboveRange,
    required this.timeBelowRange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: [
            // Нижче діапазону - червоний
            PieChartSectionData(
              color: Colors.red,
              value: timeBelowRange,
              title: '${timeBelowRange.toStringAsFixed(1)}%',
              radius: 40,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // В діапазоні - зелений
            PieChartSectionData(
              color: Colors.green,
              value: timeInRange,
              title: '${timeInRange.toStringAsFixed(1)}%',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Вище діапазону - помаранчевий
            PieChartSectionData(
              color: Colors.orange,
              value: timeAboveRange,
              title: '${timeAboveRange.toStringAsFixed(1)}%',
              radius: 40,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

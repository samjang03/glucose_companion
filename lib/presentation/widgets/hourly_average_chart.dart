// lib/presentation/widgets/analytics/hourly_average_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HourlyAverageChart extends StatelessWidget {
  final Map<String, double> hourlyAverages;
  final double lowThreshold;
  final double highThreshold;

  const HourlyAverageChart({
    Key? key,
    required this.hourlyAverages,
    this.lowThreshold = 3.9,
    this.highThreshold = 10.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hourlyAverages.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Перетворюємо мапу значень у список точок для графіка
    final List<FlSpot> spots = [];
    for (int hour = 0; hour < 24; hour++) {
      final hourString = hour.toString();
      if (hourlyAverages.containsKey(hourString)) {
        spots.add(FlSpot(hour.toDouble(), hourlyAverages[hourString]!));
      }
    }

    // Якщо немає жодної точки, показуємо повідомлення
    if (spots.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Знаходимо мінімальне та максимальне значення для осі Y
    double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    // Додаємо поля для кращого вигляду графіка
    minY = (minY - 1.0).clamp(2.0, 4.0);
    maxY = (maxY + 1.0).clamp(10.0, 20.0);

    return AspectRatio(
      aspectRatio: 1.8,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color:
                    (value == lowThreshold || value == highThreshold)
                        ? Colors.red.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                strokeWidth:
                    (value == lowThreshold || value == highThreshold) ? 2 : 1,
                dashArray:
                    (value == lowThreshold || value == highThreshold)
                        ? [5, 5]
                        : null,
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
                interval: 6,
                getTitlesWidget: (value, meta) {
                  final hour = value.toInt();
                  String text = '';
                  if (hour == 0 || hour == 24) {
                    text = '12 AM';
                  } else if (hour == 6) {
                    text = '6 AM';
                  } else if (hour == 12) {
                    text = '12 PM';
                  } else if (hour == 18) {
                    text = '6 PM';
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xff67727d),
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Color(0xff67727d),
                        fontSize: 12,
                      ),
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          minX: 0,
          maxX: 23,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.cyan],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  Color dotColor;
                  if (spot.y < lowThreshold) {
                    dotColor = Colors.red;
                  } else if (spot.y > highThreshold) {
                    dotColor = Colors.orange;
                  } else {
                    dotColor = Colors.blue;
                  }
                  return FlDotCirclePainter(
                    radius: 4,
                    color: dotColor,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.cyan.withOpacity(0.3),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // Лінія нижнього порогу
            LineChartBarData(
              spots: [FlSpot(0, lowThreshold), FlSpot(23, lowThreshold)],
              isCurved: false,
              color: Colors.red.withOpacity(0.5),
              barWidth: 1,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
              dashArray: [5, 5],
            ),
            // Лінія верхнього порогу
            LineChartBarData(
              spots: [FlSpot(0, highThreshold), FlSpot(23, highThreshold)],
              isCurved: false,
              color: Colors.red.withOpacity(0.5),
              barWidth: 1,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }
}

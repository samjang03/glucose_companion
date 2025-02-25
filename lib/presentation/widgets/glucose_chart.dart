import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:glucose_companion/data/models/glucose_chart_data.dart';
import 'package:intl/intl.dart';

class GlucoseChart extends StatelessWidget {
  final GlucoseChartData data;
  final double lowThreshold;
  final double highThreshold;

  const GlucoseChart({
    Key? key,
    required this.data,
    this.lowThreshold = 3.9,
    this.highThreshold = 10.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.spots.isEmpty) {
      return const Center(child: Text('No glucose data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 30,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color:
                  value == lowThreshold || value == highThreshold
                      ? Colors.red.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
              strokeWidth:
                  value == lowThreshold || value == highThreshold ? 2 : 1,
              dashArray:
                  value == lowThreshold || value == highThreshold
                      ? [5, 5]
                      : null,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
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
              interval: 60,
              getTitlesWidget: bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: data.minX,
        maxX: data.maxX,
        minY: data.minY,
        maxY: data.maxY,
        lineBarsData: [
          LineChartBarData(
            spots: data.spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: data.gradientColors,
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
                colors:
                    data.gradientColors
                        .map((color) => color.withOpacity(0.3))
                        .toList(),
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          // Лінія нижнього порогу
          LineChartBarData(
            spots: [
              FlSpot(data.minX, lowThreshold),
              FlSpot(data.maxX, lowThreshold),
            ],
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
            spots: [
              FlSpot(data.minX, highThreshold),
              FlSpot(data.maxX, highThreshold),
            ],
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
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    // Відображаємо час (зміщення від поточного часу)
    String text;
    if (value == 0) {
      text = 'Now';
    } else {
      // Конвертуємо хвилини в години
      final hours = (value.abs() / 60).floor();
      final minutes = (value.abs() % 60).floor();

      if (hours > 0) {
        text = '-${hours}h${minutes > 0 ? '${minutes}m' : ''}';
      } else {
        text = '-${minutes}m';
      }
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff67727d),
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    String text = value.toStringAsFixed(1);

    return Text(text, style: style, textAlign: TextAlign.center);
  }
}

// lib/presentation/widgets/glucose_trend_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as Math;

class GlucoseTrendChart extends StatelessWidget {
  final List<GlucoseDataPoint> historyData;
  final List<GlucoseDataPoint> predictionData;
  final double lowThreshold;
  final double highThreshold;

  const GlucoseTrendChart({
    Key? key,
    required this.historyData,
    required this.predictionData,
    this.lowThreshold = 3.9,
    this.highThreshold = 10.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Glucose Trend',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Implement refresh functionality
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 300, child: LineChart(_createChartData())),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  LineChartData _createChartData() {
    final now = DateTime.now();

    // Створюємо часову шкалу: -2 години до +1 години
    final startTime = now.subtract(const Duration(hours: 2));
    final endTime = now.add(const Duration(hours: 1));

    final minX = startTime.millisecondsSinceEpoch.toDouble();
    final maxX = endTime.millisecondsSinceEpoch.toDouble();
    final nowX = now.millisecondsSinceEpoch.toDouble();

    // Фіксовані межі по Y як на скриншоті
    final minY = 3.5; // Трохи нижче щоб показати лінію 3.9
    final maxY = 12.5;

    return LineChartData(
      backgroundColor: Colors.transparent,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: 1.0,
        verticalInterval: (maxX - minX) / 6, // 6 основних ліній
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: 1.0,
            getTitlesWidget: (value, meta) {
              // Показуємо мітки тільки в діапазоні 4-12
              if (value >= 4 && value <= 12 && value % 1 == 0) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 25,
            getTitlesWidget: (value, meta) {
              // Розраховуємо позиції міток на основі часового діапазону
              final timeRange = maxX - minX; // Весь діапазон від -2h до +1h
              final position = (value - minX) / timeRange; // Позиція від 0 до 1

              // Мітки на фіксованих позиціях:
              // -2h = 0/3 = 0.0
              // -1h = 1/3 = 0.33
              // Now = 2/3 = 0.67
              // +1h = 3/3 = 1.0

              if (position >= -0.05 && position <= 0.05) {
                // -2h
                return const Text(
                  '-2h',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                );
              } else if (position >= 0.30 && position <= 0.37) {
                // -1h
                return const Text(
                  '-1h',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                );
              } else if (position >= 0.63 && position <= 0.70) {
                // Now
                return const Text(
                  'Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else if (position >= 0.95 && position <= 1.05) {
                // +1h
                return const Text(
                  '+1h',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.black.withOpacity(0.8),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          tooltipMargin: 8,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final DateTime spotTime = DateTime.fromMillisecondsSinceEpoch(
                barSpot.x.toInt(),
              );
              final String timeStr =
                  '${spotTime.hour.toString().padLeft(2, '0')}:${spotTime.minute.toString().padLeft(2, '0')}';
              final String glucoseStr = barSpot.y.toStringAsFixed(1);

              // Різні кольори для історії та прогнозу
              final Color textColor =
                  barSpot.barIndex == 0
                      ? const Color(0xFF00BCD4) // Cyan для історії
                      : const Color(0xFF9C27B0); // Purple для прогнозу

              final String label =
                  barSpot.barIndex == 0 ? 'History' : 'Prediction';

              return LineTooltipItem(
                '$timeStr - $glucoseStr mmol/L',
                TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          // Можна додати додаткову логіку при торканні
        },
        handleBuiltInTouches: true,
      ),
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        // History line (cyan/blue)
        if (historyData.isNotEmpty)
          LineChartBarData(
            spots:
                historyData.map((point) {
                  return FlSpot(
                    point.timestamp.millisecondsSinceEpoch.toDouble(),
                    point.glucose,
                  );
                }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF00BCD4), // Bright cyan
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFF00BCD4),
                  strokeWidth: 1,
                  strokeColor: Colors.white.withOpacity(0.8),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF00BCD4).withOpacity(0.4),
                  const Color(0xFF00BCD4).withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

        // Prediction line (purple)
        if (predictionData.isNotEmpty)
          LineChartBarData(
            spots:
                predictionData.map((point) {
                  return FlSpot(
                    point.timestamp.millisecondsSinceEpoch.toDouble(),
                    point.glucose,
                  );
                }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF9C27B0), // Purple color like in screenshot
            barWidth: 3,
            dashArray: [8, 4], // Більш виразний пунктир
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFF9C27B0),
                  strokeWidth: 1,
                  strokeColor: Colors.white.withOpacity(0.8),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF9C27B0).withOpacity(0.4),
                  const Color(0xFF9C27B0).withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
      ],
      extraLinesData: ExtraLinesData(
        verticalLines: [
          // Вертикальна лінія "Now" - червона пунктирна
          VerticalLine(
            x: nowX,
            color: Colors.red.withOpacity(0.8),
            strokeWidth: 2,
            dashArray: [4, 4],
          ),
        ],
        horizontalLines: [
          // Low threshold line (3.9)
          HorizontalLine(
            y: 3.9,
            color: Colors.red.withOpacity(0.7),
            strokeWidth: 2,
            dashArray: [6, 4],
          ),
          // High threshold line
          HorizontalLine(
            y: highThreshold,
            color: Colors.red.withOpacity(0.7),
            strokeWidth: 2,
            dashArray: [6, 4],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(
          color: const Color(0xFF00BCD4),
          label: 'History',
          isDashed: false,
        ),
        _buildLegendItem(
          color: const Color(0xFF9C27B0),
          label: 'Prediction',
          isDashed: true,
        ),
        _buildLegendItem(
          color: Colors.red.withOpacity(0.7),
          label: 'Thresholds',
          isDashed: true,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDashed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(1.5),
          ),
          child:
              isDashed
                  ? CustomPaint(painter: DashedLinePainter(color: color))
                  : null,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}

class GlucoseDataPoint {
  final DateTime timestamp;
  final double glucose;
  final bool isPrediction;

  GlucoseDataPoint({
    required this.timestamp,
    required this.glucose,
    this.isPrediction = false,
  });
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset((startX + dashWidth).clamp(0.0, size.width), size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper function to generate sample data for testing
class GlucoseDataGenerator {
  static List<GlucoseDataPoint> generateHistoryData() {
    final now = DateTime.now();
    final List<GlucoseDataPoint> data = [];

    // Generate ТОЧНО 2 години історії (24 точки, кожні 5 хвилин)
    for (int i = 23; i >= 0; i--) {
      // Змінив з 24 на 23, щоб було рівно 24 точки
      final timestamp = now.subtract(Duration(minutes: i * 5));

      // Симулюємо реалістичну криву: підйом, плато, потім спад
      final timeProgress = (23 - i) / 23.0;
      double baseValue;

      if (timeProgress < 0.4) {
        // Підйом перші 40% часу
        baseValue = 7.2 + (timeProgress * 2.5 * 1.6); // до 10.2
      } else if (timeProgress < 0.7) {
        // Плато
        baseValue = 10.2 + (Math.sin((timeProgress - 0.4) * 10) * 0.3);
      } else {
        // Спад останні 30%
        final fallProgress = (timeProgress - 0.7) / 0.3;
        baseValue = 10.2 - (fallProgress * 3.5); // спад до 6.7
      }

      // Округляємо до десятих та додаємо невеликий шум
      final noise = (i % 3 - 1) * 0.1;
      final glucose = double.parse((baseValue + noise).toStringAsFixed(1));

      data.add(
        GlucoseDataPoint(
          timestamp: timestamp,
          glucose: glucose.clamp(6.0, 11.5),
          isPrediction: false,
        ),
      );
    }

    return data;
  }

  static List<GlucoseDataPoint> generatePredictionData() {
    final now = DateTime.now();
    final List<GlucoseDataPoint> data = [];

    // Починаємо з поточного значення близько 7.6
    double currentValue = 7.6;

    // Generate 1 hour of prediction data (12 points, every 5 minutes)
    for (int i = 1; i <= 12; i++) {
      final timestamp = now.add(Duration(minutes: i * 5));

      // Плавний підйом без гармошки
      final timeProgress = i / 12.0;
      final smoothRise =
          currentValue + (timeProgress * 0.6); // підйом на 0.6 за годину

      // Мінімальний шум для реалістичності
      final variation = (Math.sin(i * 0.5) * 0.05); // дуже малі коливання

      final glucose = double.parse((smoothRise + variation).toStringAsFixed(1));

      data.add(
        GlucoseDataPoint(
          timestamp: timestamp,
          glucose: glucose.clamp(7.0, 9.0),
          isPrediction: true,
        ),
      );
    }

    return data;
  }
}

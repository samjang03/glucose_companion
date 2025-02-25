import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';

class GlucoseChartData {
  final List<FlSpot> spots;
  final double minY;
  final double maxY;
  final double minX;
  final double maxX;
  final List<Color> gradientColors;

  GlucoseChartData({
    required this.spots,
    required this.minY,
    required this.maxY,
    required this.minX,
    required this.maxX,
    required this.gradientColors,
  });

  factory GlucoseChartData.fromReadings(
    List<GlucoseReading> readings,
    DateTime nowTime,
  ) {
    if (readings.isEmpty) {
      return GlucoseChartData(
        spots: [],
        minY: 3.0,
        maxY: 10.0,
        minX: -180,
        maxX: 0,
        gradientColors: [Colors.cyan, Colors.blue],
      );
    }

    // Сортуємо дані за часом
    readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Конвертуємо у точки для графіка
    List<FlSpot> spots = [];

    for (var reading in readings) {
      final diffInMinutes = reading.timestamp.difference(nowTime).inMinutes;
      spots.add(FlSpot(diffInMinutes.toDouble(), reading.mmolL));
    }

    // Визначаємо мінімум та максимум
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }

    // Додаємо відступи та встановлюємо мінімальні межі
    minY = (minY - 1.0).clamp(2.0, 4.0);
    maxY = (maxY + 1.0).clamp(10.0, 20.0);

    // Часовий діапазон (останні 3 години)
    double minX = -180;
    double maxX = 0;

    return GlucoseChartData(
      spots: spots,
      minY: minY,
      maxY: maxY,
      minX: minX,
      maxX: maxX,
      gradientColors: [Colors.cyan, Colors.blue],
    );
  }
}

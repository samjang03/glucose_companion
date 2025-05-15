import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';

class GlucoseChartData {
  final List<FlSpot> spots;
  final List<FlSpot> predictionSpots; // Прогнозовані значення
  final double minY;
  final double maxY;
  final double minX;
  final double maxX;
  final List<Color> historyGradientColors; // Кольори для історичних даних
  final List<Color> predictionGradientColors; // Кольори для прогнозу

  GlucoseChartData({
    required this.spots,
    this.predictionSpots = const [], // За замовчуванням порожній список
    required this.minY,
    required this.maxY,
    required this.minX,
    required this.maxX,
    required this.historyGradientColors,
    this.predictionGradientColors = const [Colors.purple, Colors.purpleAccent],
  });

  factory GlucoseChartData.fromReadings(
    List<GlucoseReading> readings,
    DateTime nowTime, {
    double? predictedValue,
    DateTime? predictionTime,
  }) {
    print(
      'Creating chart data with prediction: $predictedValue at $predictionTime',
    );

    if (readings.isEmpty) {
      return GlucoseChartData(
        spots: [],
        predictionSpots: [],
        minY: 3.0,
        maxY: 10.0,
        minX: -180,
        maxX:
            predictionTime != null
                ? 60
                : 0, // Розширюємо діапазон, якщо є прогноз
        historyGradientColors: [Colors.cyan, Colors.blue],
        predictionGradientColors: [Colors.purple, Colors.purpleAccent],
      );
    }

    // Сортуємо дані за часом
    readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Конвертуємо у точки для графіка - завжди зберігаємо в mmol/L для стандартизації
    List<FlSpot> spots = [];

    for (var reading in readings) {
      final diffInMinutes = reading.timestamp.difference(nowTime).inMinutes;
      spots.add(FlSpot(diffInMinutes.toDouble(), reading.mmolL));
    }

    // Створюємо прогноз, якщо наданий
    List<FlSpot> predictionSpots = [];
    if (predictedValue != null && predictionTime != null) {
      print(
        'Creating prediction spots for value: $predictedValue at time: $predictionTime',
      );

      // Останнє реальне значення
      final lastReading = readings.last;
      final lastSpot = spots.last;

      // Прогнозована точка
      final diffInMinutes = predictionTime.difference(nowTime).inMinutes;
      final predictionSpot = FlSpot(diffInMinutes.toDouble(), predictedValue);

      // Додаємо проміжну точку для плавного з'єднання (опціонально)
      // Можна використовувати лінійну інтерполяцію
      final midX = (lastSpot.x + predictionSpot.x) / 2;
      final midY = (lastReading.mmolL + predictedValue) / 2;

      predictionSpots = [
        FlSpot(
          lastSpot.x,
          lastReading.mmolL,
        ), // Повторюємо останню точку як початок прогнозу
        FlSpot(midX, midY), // Проміжна точка
        predictionSpot, // Кінцева прогнозована точка
      ];

      print('Generated prediction spots: $predictionSpots');
    }

    // Визначаємо мінімум та максимум
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }

    // Перевіряємо прогнозовані значення
    for (var spot in predictionSpots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }

    // Додаємо відступи та встановлюємо мінімальні межі
    minY = (minY - 1.0).clamp(2.0, 4.0);
    maxY = (maxY + 1.0).clamp(10.0, 20.0);

    // Часовий діапазон (останні 3 години)
    double minX = -180;
    double maxX =
        predictionTime != null
            ? 60
            : 0; // Розширюємо часовий діапазон, якщо є прогноз

    if (predictionSpots.isNotEmpty) {
      print('Generated prediction spots: $predictionSpots');
    } else {
      print('No prediction spots generated');
    }

    return GlucoseChartData(
      spots: spots,
      minY: minY,
      maxY: maxY,
      minX: minX,
      maxX: maxX,
      historyGradientColors: [Colors.cyan, Colors.blue],
      predictionGradientColors: [Colors.purple, Colors.purpleAccent],
    );
  }
}

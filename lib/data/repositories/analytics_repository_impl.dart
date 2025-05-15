// lib/data/repositories/analytics_repository_impl.dart
import 'package:glucose_companion/data/datasources/local/database_helper.dart';
import 'package:glucose_companion/data/models/analytics_data.dart';
import 'package:glucose_companion/domain/repositories/analytics_repository.dart';
import 'dart:math';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final DatabaseHelper _databaseHelper;

  AnalyticsRepositoryImpl(this._databaseHelper);

  @override
  Future<GlucoseAnalyticsData> getAnalyticsData(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;

    // Отримуємо всі вимірювання глюкози за вказаний період
    final readingsData = await db.query(
      'glucose_readings',
      where: 'user_id = ? AND timestamp BETWEEN ? AND ? AND is_valid = 1',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'timestamp ASC',
    );

    if (readingsData.isEmpty) {
      return GlucoseAnalyticsData.empty();
    }

    // Конвертуємо результати у список значень глюкози
    final List<double> glucoseValues =
        readingsData.map((e) => e['mmol_l'] as double).toList();

    // Підрахунок статистики
    double sum = 0;
    double sumSquared = 0;
    int inRange = 0;
    int aboveRange = 0;
    int belowRange = 0;
    int urgentLow = 0;
    int urgentHigh = 0;
    int hypoEvents = 0;
    int hyperEvents = 0;
    bool wasHypo = false;
    bool wasHyper = false;

    // Hourly averages
    Map<String, List<double>> hourlyData = {};

    for (int i = 0; i < readingsData.length; i++) {
      final value = glucoseValues[i];
      final timestamp = DateTime.parse(readingsData[i]['timestamp'] as String);
      final hour = timestamp.hour;

      // Додаємо значення до відповідної години
      if (!hourlyData.containsKey(hour.toString())) {
        hourlyData[hour.toString()] = [];
      }
      hourlyData[hour.toString()]!.add(value);

      // Обчислення суми і суми квадратів для середнього та стандартного відхилення
      sum += value;
      sumSquared += value * value;

      // Класифікація значень за діапазонами
      if (value < 3.0) {
        urgentLow++;
        belowRange++;

        // Підрахунок гіпоглікемічних подій
        if (!wasHypo) {
          hypoEvents++;
          wasHypo = true;
        }
      } else if (value < 3.9) {
        belowRange++;

        // Підрахунок гіпоглікемічних подій
        if (!wasHypo) {
          hypoEvents++;
          wasHypo = true;
        }
      } else if (value <= 10.0) {
        inRange++;
        wasHypo = false;
        wasHyper = false;
      } else if (value <= 13.9) {
        aboveRange++;

        // Підрахунок гіперглікемічних подій
        if (!wasHyper) {
          hyperEvents++;
          wasHyper = true;
        }
      } else {
        urgentHigh++;
        aboveRange++;

        // Підрахунок гіперглікемічних подій
        if (!wasHyper) {
          hyperEvents++;
          wasHyper = true;
        }
      }
    }

    final int totalReadings = glucoseValues.length;
    final double average = sum / totalReadings;
    final double variance = (sumSquared / totalReadings) - (average * average);
    final double stdDev = sqrt(variance);

    // Розрахунок середніх по годинах
    Map<String, double> hourlyAverages = {};
    hourlyData.forEach((hour, values) {
      hourlyAverages[hour] = values.reduce((a, b) => a + b) / values.length;
    });

    // Розрахунок GMI (Glucose Management Indicator)
    // Формула: GMI (%) = 3.31 + 0.02392 × [mean glucose in mg/dL]
    final double gmi = 3.31 + (0.02392 * average * 18.0);

    return GlucoseAnalyticsData(
      startDate: startDate,
      endDate: endDate,
      averageGlucose: average,
      standardDeviation: stdDev,
      timeInRange: inRange / totalReadings * 100,
      timeAboveRange: aboveRange / totalReadings * 100,
      timeBelowRange: belowRange / totalReadings * 100,
      timeInUrgentLow: urgentLow / totalReadings * 100,
      timeInUrgentHigh: urgentHigh / totalReadings * 100,
      readingsCount: totalReadings,
      gmi: gmi,
      hourlyAverages: hourlyAverages,
      hypoEvents: hypoEvents,
      hyperEvents: hyperEvents,
    );
  }
}

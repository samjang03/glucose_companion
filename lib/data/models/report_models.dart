import 'dart:math';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/activity_record.dart';

class ReportDataModel {
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final double averageGlucose;
  final double standardDeviation;
  final double coefficientOfVariation;
  final double timeInRange;
  final double timeAboveRange;
  final double timeBelowRange;
  final double timeVeryLow;
  final double timeVeryHigh;
  final int totalReadings;
  final int activeDays;
  final double sensorUsage;
  final double gmi;
  final double estimatedA1c;
  final List<DailyStatistic> dailyStats;
  final List<DetectedPattern> detectedPatterns;
  final List<HourlyStatistic> hourlyStats;
  final AGPData agpData;
  final List<GlucoseReading> allReadings;
  final List<InsulinRecord> insulinRecords;
  final List<CarbRecord> carbRecords;

  ReportDataModel({
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.averageGlucose,
    required this.standardDeviation,
    required this.coefficientOfVariation,
    required this.timeInRange,
    required this.timeAboveRange,
    required this.timeBelowRange,
    required this.timeVeryLow,
    required this.timeVeryHigh,
    required this.totalReadings,
    required this.activeDays,
    required this.sensorUsage,
    required this.gmi,
    required this.estimatedA1c,
    required this.dailyStats,
    required this.detectedPatterns,
    required this.hourlyStats,
    required this.agpData,
    required this.allReadings,
    required this.insulinRecords,
    required this.carbRecords,
  });

  factory ReportDataModel.fromData({
    required List<GlucoseReading> readings,
    required List<InsulinRecord> insulinRecords,
    required List<CarbRecord> carbRecords,
    required List<ActivityRecord> activityRecords,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (readings.isEmpty) {
      return ReportDataModel._empty(startDate, endDate);
    }

    // Фільтруємо дані за періодом
    final filteredReadings =
        readings
            .where(
              (r) =>
                  r.timestamp.isAfter(
                    startDate.subtract(const Duration(minutes: 1)),
                  ) &&
                  r.timestamp.isBefore(endDate.add(const Duration(minutes: 1))),
            )
            .toList();

    // Розрахунок основних метрик
    final glucoseValues = filteredReadings.map((r) => r.mmolL).toList();

    final averageGlucose =
        glucoseValues.isNotEmpty
            ? glucoseValues.reduce((a, b) => a + b) / glucoseValues.length
            : 0.0;

    final variance =
        glucoseValues.isNotEmpty
            ? glucoseValues
                    .map((v) => (v - averageGlucose) * (v - averageGlucose))
                    .reduce((a, b) => a + b) /
                glucoseValues.length
            : 0.0;
    final standardDeviation = variance > 0 ? sqrt(variance) : 0.0;
    final coefficientOfVariation =
        averageGlucose > 0 ? (standardDeviation / averageGlucose) * 100 : 0.0;

    // Розрахунок Time in Range
    final inRangeCount =
        glucoseValues.where((v) => v >= 3.9 && v <= 10.0).length;
    final aboveRangeCount =
        glucoseValues.where((v) => v > 10.0 && v <= 13.9).length;
    final belowRangeCount =
        glucoseValues.where((v) => v < 3.9 && v >= 3.0).length;
    final veryLowCount = glucoseValues.where((v) => v < 3.0).length;
    final veryHighCount = glucoseValues.where((v) => v > 13.9).length;

    final total = glucoseValues.length;
    final timeInRange = total > 0 ? inRangeCount / total : 0.0;
    final timeAboveRange = total > 0 ? aboveRangeCount / total : 0.0;
    final timeBelowRange = total > 0 ? belowRangeCount / total : 0.0;
    final timeVeryLow = total > 0 ? veryLowCount / total : 0.0;
    final timeVeryHigh = total > 0 ? veryHighCount / total : 0.0;

    // Розрахунок активних днів
    final uniqueDays =
        filteredReadings
            .map(
              (r) => DateTime(
                r.timestamp.year,
                r.timestamp.month,
                r.timestamp.day,
              ),
            )
            .toSet()
            .length;

    final totalPossibleDays = endDate.difference(startDate).inDays + 1;
    final sensorUsage = uniqueDays / totalPossibleDays;

    // GMI та eA1C
    final averageMgdl = averageGlucose * 18.0;
    final gmi = averageMgdl > 0 ? 3.31 + (0.02392 * averageMgdl) : 0.0;
    final estimatedA1c =
        averageGlucose > 0 ? (averageGlucose + 2.59) / 1.59 : 0.0;

    // Створення щоденної статистики
    final dailyStats = _calculateDailyStatistics(
      filteredReadings,
      startDate,
      endDate,
    );

    // Створення погодинної статистики
    final hourlyStats = _calculateHourlyStatistics(filteredReadings);

    // Виявлення патернів
    final detectedPatterns = _detectPatterns(filteredReadings);

    // Створення AGP даних
    final agpData = _calculateAGPData(filteredReadings);

    return ReportDataModel(
      startDate: startDate,
      endDate: endDate,
      totalDays: totalPossibleDays,
      averageGlucose: averageGlucose,
      standardDeviation: standardDeviation,
      coefficientOfVariation: coefficientOfVariation,
      timeInRange: timeInRange,
      timeAboveRange: timeAboveRange,
      timeBelowRange: timeBelowRange,
      timeVeryLow: timeVeryLow,
      timeVeryHigh: timeVeryHigh,
      totalReadings: total,
      activeDays: uniqueDays,
      sensorUsage: sensorUsage,
      gmi: gmi,
      estimatedA1c: estimatedA1c,
      dailyStats: dailyStats,
      detectedPatterns: detectedPatterns,
      hourlyStats: hourlyStats,
      agpData: agpData,
      allReadings: filteredReadings,
      insulinRecords: insulinRecords,
      carbRecords: carbRecords,
    );
  }

  factory ReportDataModel._empty(DateTime startDate, DateTime endDate) {
    return ReportDataModel(
      startDate: startDate,
      endDate: endDate,
      totalDays: endDate.difference(startDate).inDays + 1,
      averageGlucose: 0.0,
      standardDeviation: 0.0,
      coefficientOfVariation: 0.0,
      timeInRange: 0.0,
      timeAboveRange: 0.0,
      timeBelowRange: 0.0,
      timeVeryLow: 0.0,
      timeVeryHigh: 0.0,
      totalReadings: 0,
      activeDays: 0,
      sensorUsage: 0.0,
      gmi: 0.0,
      estimatedA1c: 0.0,
      dailyStats: [],
      detectedPatterns: [],
      hourlyStats: [],
      agpData: AGPData.empty(),
      allReadings: [],
      insulinRecords: [],
      carbRecords: [],
    );
  }

  static List<DailyStatistic> _calculateDailyStatistics(
    List<GlucoseReading> readings,
    DateTime startDate,
    DateTime endDate,
  ) {
    final stats = <DailyStatistic>[];
    final totalDays = endDate.difference(startDate).inDays + 1;

    for (int i = 0; i < totalDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayReadings =
          readings
              .where(
                (r) =>
                    r.timestamp.isAfter(
                      dayStart.subtract(const Duration(minutes: 1)),
                    ) &&
                    r.timestamp.isBefore(dayEnd),
              )
              .toList();

      if (dayReadings.isNotEmpty) {
        final glucoseValues = dayReadings.map((r) => r.mmolL).toList();
        final average =
            glucoseValues.reduce((a, b) => a + b) / glucoseValues.length;

        final inRange =
            glucoseValues.where((v) => v >= 3.9 && v <= 10.0).length;
        final aboveRange = glucoseValues.where((v) => v > 10.0).length;
        final belowRange = glucoseValues.where((v) => v < 3.9).length;

        final total = glucoseValues.length;

        stats.add(
          DailyStatistic(
            date: date,
            averageGlucose: average,
            timeInRange: total > 0 ? inRange / total : 0.0,
            timeAboveRange: total > 0 ? aboveRange / total : 0.0,
            timeBelowRange: total > 0 ? belowRange / total : 0.0,
            totalReadings: total,
            minGlucose: glucoseValues.reduce(min),
            maxGlucose: glucoseValues.reduce(max),
          ),
        );
      }
    }

    return stats;
  }

  static List<HourlyStatistic> _calculateHourlyStatistics(
    List<GlucoseReading> readings,
  ) {
    final stats = <HourlyStatistic>[];

    for (int hour = 0; hour < 24; hour++) {
      final hourReadings =
          readings.where((r) => r.timestamp.hour == hour).toList();

      if (hourReadings.isNotEmpty) {
        final glucoseValues = hourReadings.map((r) => r.mmolL).toList();
        final average =
            glucoseValues.reduce((a, b) => a + b) / glucoseValues.length;

        final inRange =
            glucoseValues.where((v) => v >= 3.9 && v <= 10.0).length;
        final aboveRange = glucoseValues.where((v) => v > 10.0).length;
        final belowRange = glucoseValues.where((v) => v < 3.9).length;

        final total = glucoseValues.length;

        stats.add(
          HourlyStatistic(
            hour: hour,
            averageGlucose: average,
            timeInRange: total > 0 ? inRange / total : 0.0,
            timeAboveRange: total > 0 ? aboveRange / total : 0.0,
            timeBelowRange: total > 0 ? belowRange / total : 0.0,
            totalReadings: total,
          ),
        );
      }
    }

    return stats;
  }

  static List<DetectedPattern> _detectPatterns(List<GlucoseReading> readings) {
    final patterns = <DetectedPattern>[];

    if (readings.length < 100) return patterns;

    // Нічна гіперглікемія
    final nightReadings =
        readings
            .where((r) => r.timestamp.hour >= 0 && r.timestamp.hour < 6)
            .toList();

    if (nightReadings.isNotEmpty) {
      final nightHighs = nightReadings.where((r) => r.mmolL > 10.0).length;
      final nightPercentage = nightHighs / nightReadings.length;

      if (nightPercentage > 0.3) {
        patterns.add(
          DetectedPattern(
            type: 'nighttime_highs',
            title: 'Nighttime Highs',
            description:
                'Pattern of elevated glucose levels between 22:00 and 07:00',
            severity: 'moderate',
            percentage: nightPercentage * 100,
          ),
        );
      }
    }

    // Ранкова гіпоглікемія
    final morningReadings =
        readings
            .where((r) => r.timestamp.hour >= 6 && r.timestamp.hour < 10)
            .toList();

    if (morningReadings.isNotEmpty) {
      final morningLows = morningReadings.where((r) => r.mmolL < 3.9).length;
      final morningPercentage = morningLows / morningReadings.length;

      if (morningPercentage > 0.15) {
        patterns.add(
          DetectedPattern(
            type: 'morning_lows',
            title: 'Morning Lows',
            description: 'Pattern of low glucose levels in the morning hours',
            severity: 'high',
            percentage: morningPercentage * 100,
          ),
        );
      }
    }

    return patterns;
  }

  static AGPData _calculateAGPData(List<GlucoseReading> readings) {
    if (readings.isEmpty) return AGPData.empty();

    final Map<int, List<double>> hourlyValues = {};

    // Групуємо значення за годинами
    for (final reading in readings) {
      final hour = reading.timestamp.hour;
      if (!hourlyValues.containsKey(hour)) {
        hourlyValues[hour] = [];
      }
      hourlyValues[hour]!.add(reading.mmolL);
    }

    final agpPoints = <AGPPoint>[];

    // Розраховуємо перцентилі для кожної години
    for (int hour = 0; hour < 24; hour++) {
      if (hourlyValues.containsKey(hour)) {
        final values = hourlyValues[hour]!..sort();
        if (values.isNotEmpty) {
          agpPoints.add(
            AGPPoint(
              hour: hour,
              p5: _calculatePercentile(values, 5),
              p25: _calculatePercentile(values, 25),
              p50: _calculatePercentile(values, 50),
              p75: _calculatePercentile(values, 75),
              p95: _calculatePercentile(values, 95),
            ),
          );
        }
      }
    }

    return AGPData(points: agpPoints);
  }

  static double _calculatePercentile(
    List<double> sortedValues,
    int percentile,
  ) {
    final index = (percentile / 100.0) * (sortedValues.length - 1);
    final lower = index.floor();
    final upper = index.ceil();

    if (lower == upper) {
      return sortedValues[lower];
    }

    final weight = index - lower;
    return sortedValues[lower] * (1 - weight) + sortedValues[upper] * weight;
  }
}

class DailyStatistic {
  final DateTime date;
  final double averageGlucose;
  final double timeInRange;
  final double timeAboveRange;
  final double timeBelowRange;
  final int totalReadings;
  final double minGlucose;
  final double maxGlucose;

  DailyStatistic({
    required this.date,
    required this.averageGlucose,
    required this.timeInRange,
    required this.timeAboveRange,
    required this.timeBelowRange,
    required this.totalReadings,
    required this.minGlucose,
    required this.maxGlucose,
  });
}

class HourlyStatistic {
  final int hour;
  final double averageGlucose;
  final double timeInRange;
  final double timeAboveRange;
  final double timeBelowRange;
  final int totalReadings;

  HourlyStatistic({
    required this.hour,
    required this.averageGlucose,
    required this.timeInRange,
    required this.timeAboveRange,
    required this.timeBelowRange,
    required this.totalReadings,
  });
}

class DetectedPattern {
  final String type;
  final String title;
  final String description;
  final String severity;
  final double percentage;

  DetectedPattern({
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.percentage,
  });
}

class AGPData {
  final List<AGPPoint> points;

  AGPData({required this.points});

  factory AGPData.empty() => AGPData(points: []);
}

class AGPPoint {
  final int hour;
  final double p5;
  final double p25;
  final double p50;
  final double p75;
  final double p95;

  AGPPoint({
    required this.hour,
    required this.p5,
    required this.p25,
    required this.p50,
    required this.p75,
    required this.p95,
  });
}

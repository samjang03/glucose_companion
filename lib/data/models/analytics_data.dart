// lib/data/models/analytics_data.dart
import 'package:equatable/equatable.dart';

class GlucoseAnalyticsData extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final double averageGlucose;
  final double standardDeviation;
  final double
  timeInRange; // відсоток часу в цільовому діапазоні (3.9-10.0 ммоль/л)
  final double timeAboveRange; // відсоток часу вище діапазону (>10.0 ммоль/л)
  final double timeBelowRange; // відсоток часу нижче діапазону (<3.9 ммоль/л)
  final double
  timeInUrgentLow; // відсоток часу в загрозливо низькому рівні (<3.0 ммоль/л)
  final double
  timeInUrgentHigh; // відсоток часу в загрозливо високому рівні (>13.9 ммоль/л)
  final int readingsCount; // кількість вимірювань
  final double gmi; // Glucose Management Indicator
  final Map<String, double> hourlyAverages; // середні значення по годинах
  final int hypoEvents; // кількість гіпоглікемічних подій
  final int hyperEvents; // кількість гіперглікемічних подій

  const GlucoseAnalyticsData({
    required this.startDate,
    required this.endDate,
    required this.averageGlucose,
    required this.standardDeviation,
    required this.timeInRange,
    required this.timeAboveRange,
    required this.timeBelowRange,
    required this.timeInUrgentLow,
    required this.timeInUrgentHigh,
    required this.readingsCount,
    required this.gmi,
    required this.hourlyAverages,
    required this.hypoEvents,
    required this.hyperEvents,
  });

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    averageGlucose,
    standardDeviation,
    timeInRange,
    timeAboveRange,
    timeBelowRange,
    timeInUrgentLow,
    timeInUrgentHigh,
    readingsCount,
    gmi,
    hourlyAverages,
    hypoEvents,
    hyperEvents,
  ];

  // Порожній об'єкт для випадків без даних
  factory GlucoseAnalyticsData.empty() {
    return GlucoseAnalyticsData(
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
      averageGlucose: 0,
      standardDeviation: 0,
      timeInRange: 0,
      timeAboveRange: 0,
      timeBelowRange: 0,
      timeInUrgentLow: 0,
      timeInUrgentHigh: 0,
      readingsCount: 0,
      gmi: 0,
      hourlyAverages: const {},
      hypoEvents: 0,
      hyperEvents: 0,
    );
  }
}

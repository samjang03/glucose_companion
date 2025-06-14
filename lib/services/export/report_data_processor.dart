// lib/services/export/report_data_processor.dart
import 'dart:math';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/services/mock_data_service.dart';

class ReportPeriodData {
  final DateTime startDate;
  final DateTime endDate;
  final List<GlucoseReading> glucoseReadings;
  final List<InsulinRecord> insulinRecords;
  final List<CarbRecord> carbRecords;
  final Map<String, dynamic> statistics;
  final List<Map<String, dynamic>> patterns;
  final Map<String, List<GlucoseReading>> dailyReadings;
  final Map<int, List<GlucoseReading>> hourlyReadings;

  ReportPeriodData({
    required this.startDate,
    required this.endDate,
    required this.glucoseReadings,
    required this.insulinRecords,
    required this.carbRecords,
    required this.statistics,
    required this.patterns,
    required this.dailyReadings,
    required this.hourlyReadings,
  });
}

class ReportDataProcessor {
  final MockDataService _mockDataService = MockDataService();

  Future<ReportPeriodData> processDataForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    // Calculate days difference
    final daysDifference = endDate.difference(startDate).inDays;

    // Generate mock data for the specified period
    final glucoseReadings = _mockDataService.generateMockGlucoseData(
      daysDifference,
      userId,
    );

    final insulinRecords = _mockDataService.generateMockInsulinRecords(
      daysDifference,
      userId,
    );

    final carbRecords = _mockDataService.generateMockCarbRecords(
      daysDifference,
      userId,
    );

    // Filter data to exact period
    final filteredGlucoseReadings =
        glucoseReadings
            .where(
              (reading) =>
                  reading.timestamp.isAfter(startDate) &&
                  reading.timestamp.isBefore(endDate),
            )
            .toList();

    final filteredInsulinRecords =
        insulinRecords
            .where(
              (record) =>
                  record.timestamp.isAfter(startDate) &&
                  record.timestamp.isBefore(endDate),
            )
            .toList();

    final filteredCarbRecords =
        carbRecords
            .where(
              (record) =>
                  record.timestamp.isAfter(startDate) &&
                  record.timestamp.isBefore(endDate),
            )
            .toList();

    // Calculate statistics
    final statistics = _mockDataService.generateStatistics(
      filteredGlucoseReadings,
    );

    // Analyze patterns
    final patterns = _mockDataService.analyzePatterns(filteredGlucoseReadings);

    // Group data by day and hour
    final dailyReadings = _groupReadingsByDay(filteredGlucoseReadings);
    final hourlyReadings = _groupReadingsByHour(filteredGlucoseReadings);

    return ReportPeriodData(
      startDate: startDate,
      endDate: endDate,
      glucoseReadings: filteredGlucoseReadings,
      insulinRecords: filteredInsulinRecords,
      carbRecords: filteredCarbRecords,
      statistics: statistics,
      patterns: patterns,
      dailyReadings: dailyReadings,
      hourlyReadings: hourlyReadings,
    );
  }

  Map<String, List<GlucoseReading>> _groupReadingsByDay(
    List<GlucoseReading> readings,
  ) {
    final Map<String, List<GlucoseReading>> grouped = {};

    for (var reading in readings) {
      final dayKey =
          '${reading.timestamp.year}-${reading.timestamp.month.toString().padLeft(2, '0')}-${reading.timestamp.day.toString().padLeft(2, '0')}';

      if (!grouped.containsKey(dayKey)) {
        grouped[dayKey] = [];
      }
      grouped[dayKey]!.add(reading);
    }

    return grouped;
  }

  Map<int, List<GlucoseReading>> _groupReadingsByHour(
    List<GlucoseReading> readings,
  ) {
    final Map<int, List<GlucoseReading>> grouped = {};

    for (var reading in readings) {
      final hour = reading.timestamp.hour;

      if (!grouped.containsKey(hour)) {
        grouped[hour] = [];
      }
      grouped[hour]!.add(reading);
    }

    return grouped;
  }
}

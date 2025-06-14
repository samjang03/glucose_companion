import 'package:glucose_companion/data/models/report_models.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/activity_record.dart';
import 'package:glucose_companion/services/mock_data_service.dart';

class ReportDataService {
  final MockDataService _mockDataService;

  ReportDataService(this._mockDataService);

  /// Створює звіт за вказаний період
  Future<ReportDataModel> generateReportData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // В реальній імплементації тут би були запити до репозиторіїв
      // Поки що використовуємо MockDataService для демонстрації

      final totalDays = endDate.difference(startDate).inDays + 1;

      // Генеруємо дані за період
      final glucoseReadings = _mockDataService.generateMockGlucoseData(
        totalDays,
        userId,
      );
      final insulinRecords = _mockDataService.generateMockInsulinRecords(
        totalDays,
        userId,
      );
      final carbRecords = _mockDataService.generateMockCarbRecords(
        totalDays,
        userId,
      );
      final activityRecords = _mockDataService.generateMockActivityRecords(
        totalDays,
        userId,
      );

      // Фільтруємо дані за періодом
      final filteredGlucoseReadings =
          glucoseReadings
              .where(
                (reading) =>
                    reading.timestamp.isAfter(
                      startDate.subtract(const Duration(minutes: 1)),
                    ) &&
                    reading.timestamp.isBefore(
                      endDate.add(const Duration(minutes: 1)),
                    ),
              )
              .toList();

      final filteredInsulinRecords =
          insulinRecords
              .where(
                (record) =>
                    record.timestamp.isAfter(
                      startDate.subtract(const Duration(minutes: 1)),
                    ) &&
                    record.timestamp.isBefore(
                      endDate.add(const Duration(minutes: 1)),
                    ),
              )
              .toList();

      final filteredCarbRecords =
          carbRecords
              .where(
                (record) =>
                    record.timestamp.isAfter(
                      startDate.subtract(const Duration(minutes: 1)),
                    ) &&
                    record.timestamp.isBefore(
                      endDate.add(const Duration(minutes: 1)),
                    ),
              )
              .toList();

      final filteredActivityRecords =
          activityRecords
              .where(
                (record) =>
                    record.timestamp.isAfter(
                      startDate.subtract(const Duration(minutes: 1)),
                    ) &&
                    record.timestamp.isBefore(
                      endDate.add(const Duration(minutes: 1)),
                    ),
              )
              .toList();

      // Створюємо модель звіту
      final reportData = ReportDataModel.fromData(
        readings: filteredGlucoseReadings,
        insulinRecords: filteredInsulinRecords,
        carbRecords: filteredCarbRecords,
        activityRecords: filteredActivityRecords,
        startDate: startDate,
        endDate: endDate,
      );

      return reportData;
    } catch (e) {
      throw Exception('Failed to generate report data: $e');
    }
  }

  /// Створює звіт для демонстрації з реалістичними даними
  Future<ReportDataModel> generateDemoReportData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Використовуємо існуючі методи MockDataService
      final totalDays = endDate.difference(startDate).inDays + 1;

      final glucoseReadings = _mockDataService.generateMockGlucoseData(
        totalDays,
        userId,
      );
      final insulinRecords = _mockDataService.generateMockInsulinRecords(
        totalDays,
        userId,
      );
      final carbRecords = _mockDataService.generateMockCarbRecords(
        totalDays,
        userId,
      );
      final activityRecords = _mockDataService.generateMockActivityRecords(
        totalDays,
        userId,
      );

      // Створюємо модель звіту
      final reportData = ReportDataModel.fromData(
        readings: glucoseReadings,
        insulinRecords: insulinRecords,
        carbRecords: carbRecords,
        activityRecords: activityRecords,
        startDate: startDate,
        endDate: endDate,
      );

      return reportData;
    } catch (e) {
      throw Exception('Failed to generate demo report data: $e');
    }
  }

  /// Створює швидкий звіт за останні N днів
  Future<ReportDataModel> generateQuickReport({
    required String userId,
    required int days,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    return generateReportData(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Валідує дані перед створенням звіту
  bool validateReportParameters({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) {
    // Перевіряємо, що дати коректні
    if (startDate.isAfter(endDate)) {
      return false;
    }

    // Перевіряємо, що період не більше 90 днів
    final daysDifference = endDate.difference(startDate).inDays;
    if (daysDifference > 90) {
      return false;
    }

    // Перевіряємо, що користувач вказаний
    if (userId.isEmpty) {
      return false;
    }

    // Перевіряємо, що кінцева дата не в майбутньому
    if (endDate.isAfter(DateTime.now())) {
      return false;
    }

    return true;
  }

  /// Розраховує рекомендований період для звіту
  Map<String, DateTime> getRecommendedPeriod() {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(
      const Duration(days: 14),
    ); // Стандартний період 14 днів

    return {'startDate': startDate, 'endDate': endDate};
  }

  /// Отримує доступні періоди для звітів
  List<Map<String, dynamic>> getAvailablePeriods() {
    final now = DateTime.now();

    return [
      {
        'name': 'Last 7 days',
        'startDate': now.subtract(const Duration(days: 7)),
        'endDate': now,
        'days': 7,
      },
      {
        'name': 'Last 14 days',
        'startDate': now.subtract(const Duration(days: 14)),
        'endDate': now,
        'days': 14,
      },
      {
        'name': 'Last 30 days',
        'startDate': now.subtract(const Duration(days: 30)),
        'endDate': now,
        'days': 30,
      },
      {
        'name': 'Last 90 days',
        'startDate': now.subtract(const Duration(days: 90)),
        'endDate': now,
        'days': 90,
      },
    ];
  }
}

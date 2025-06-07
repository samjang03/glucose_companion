import 'package:glucose_companion/data/models/activity_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';

class MockRecordsService {
  // Статичні списки для зберігання записів
  static final List<InsulinRecord> _insulinRecords = [];
  static final List<CarbRecord> _carbRecords = [];
  static final List<ActivityRecord> _activityRecords = [];

  // Лічильники ID для унікальності
  static int _insulinIdCounter = 1;
  static int _carbIdCounter = 1;
  static int _activityIdCounter = 1;

  // Ініціалізація без демонстраційних даних
  static bool _isInitialized = false;

  void _initializeDemoData() {
    if (_isInitialized) return;

    // Списки вже порожні, просто позначаємо як ініціалізовані
    _isInitialized = true;
    print('MockRecordsService initialized - ready to accept new records');
  }

  // === INSULIN RECORDS ===

  Future<int> insertInsulin(InsulinRecord record) async {
    _initializeDemoData();

    final newRecord = record.copyWith(id: _insulinIdCounter++);
    _insulinRecords.add(newRecord);

    print('Insulin record added: ${newRecord.units}U ${newRecord.type}');
    return newRecord.id!;
  }

  Future<int> updateInsulin(InsulinRecord record) async {
    _initializeDemoData();

    final index = _insulinRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _insulinRecords[index] = record;
      print('Insulin record updated: ${record.units}U ${record.type}');
      return 1;
    }
    return 0;
  }

  Future<int> deleteInsulin(int id) async {
    _initializeDemoData();

    final initialLength = _insulinRecords.length;
    _insulinRecords.removeWhere((r) => r.id == id);
    final removedCount = initialLength - _insulinRecords.length;

    print('Insulin record deleted: $removedCount records removed');
    return removedCount;
  }

  Future<List<InsulinRecord>> getInsulinByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    _initializeDemoData();

    final records =
        _insulinRecords
            .where(
              (record) =>
                  record.userId == userId &&
                  record.timestamp.isAfter(
                    start.subtract(const Duration(seconds: 1)),
                  ) &&
                  record.timestamp.isBefore(end),
            )
            .toList();

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    print('Found ${records.length} insulin records for date range');
    return records;
  }

  // === CARB RECORDS ===

  Future<int> insertCarb(CarbRecord record) async {
    _initializeDemoData();

    final newRecord = record.copyWith(id: _carbIdCounter++);
    _carbRecords.add(newRecord);

    print('Carb record added: ${newRecord.grams}g ${newRecord.mealType}');
    return newRecord.id!;
  }

  Future<int> updateCarb(CarbRecord record) async {
    _initializeDemoData();

    final index = _carbRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _carbRecords[index] = record;
      print('Carb record updated: ${record.grams}g ${record.mealType}');
      return 1;
    }
    return 0;
  }

  Future<int> deleteCarb(int id) async {
    _initializeDemoData();

    final initialLength = _carbRecords.length;
    _carbRecords.removeWhere((r) => r.id == id);
    final removedCount = initialLength - _carbRecords.length;

    print('Carb record deleted: $removedCount records removed');
    return removedCount;
  }

  Future<List<CarbRecord>> getCarbsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    _initializeDemoData();

    final records =
        _carbRecords
            .where(
              (record) =>
                  record.userId == userId &&
                  record.timestamp.isAfter(
                    start.subtract(const Duration(seconds: 1)),
                  ) &&
                  record.timestamp.isBefore(end),
            )
            .toList();

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    print('Found ${records.length} carb records for date range');
    return records;
  }

  // === ACTIVITY RECORDS ===

  Future<int> insertActivity(ActivityRecord record) async {
    _initializeDemoData();

    final newRecord = record.copyWith(id: _activityIdCounter++);
    _activityRecords.add(newRecord);

    print('Activity record added: ${newRecord.activityType}');
    return newRecord.id!;
  }

  Future<int> updateActivity(ActivityRecord record) async {
    _initializeDemoData();

    final index = _activityRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _activityRecords[index] = record;
      print('Activity record updated: ${record.activityType}');
      return 1;
    }
    return 0;
  }

  Future<int> deleteActivity(int id) async {
    _initializeDemoData();

    final initialLength = _activityRecords.length;
    _activityRecords.removeWhere((r) => r.id == id);
    final removedCount = initialLength - _activityRecords.length;

    print('Activity record deleted: $removedCount records removed');
    return removedCount;
  }

  Future<List<ActivityRecord>> getActivitiesByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    _initializeDemoData();

    final records =
        _activityRecords
            .where(
              (record) =>
                  record.userId == userId &&
                  record.timestamp.isAfter(
                    start.subtract(const Duration(seconds: 1)),
                  ) &&
                  record.timestamp.isBefore(end),
            )
            .toList();

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    print('Found ${records.length} activity records for date range');
    return records;
  }

  // === UTILITY METHODS ===

  // Метод для очищення всіх записів (для тестування)
  void clearAllRecords() {
    _insulinRecords.clear();
    _carbRecords.clear();
    _activityRecords.clear();
    _insulinIdCounter = 1;
    _carbIdCounter = 1;
    _activityIdCounter = 1;
    _isInitialized = false;
    print('All records cleared');
  }

  // Метод для отримання статистики
  Map<String, int> getRecordsCount() {
    _initializeDemoData();

    return {
      'insulin': _insulinRecords.length,
      'carbs': _carbRecords.length,
      'activities': _activityRecords.length,
    };
  }
}

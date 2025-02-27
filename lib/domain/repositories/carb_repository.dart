import 'package:glucose_companion/data/models/carb_record.dart';

abstract class CarbRepository {
  Future<int> insert(CarbRecord record);
  Future<int> update(CarbRecord record);
  Future<int> delete(int id);
  Future<CarbRecord?> getById(int id);
  Future<List<CarbRecord>> getAll(String userId);
  Future<List<CarbRecord>> getByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  );
  Future<CarbRecord?> getLastRecord(String userId);
  Future<double> getTotalCarbsForDay(String userId, DateTime date);
}

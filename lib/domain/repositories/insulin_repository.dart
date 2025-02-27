import 'package:glucose_companion/data/models/insulin_record.dart';

abstract class InsulinRepository {
  Future<int> insert(InsulinRecord record);
  Future<int> update(InsulinRecord record);
  Future<int> delete(int id);
  Future<InsulinRecord?> getById(int id);
  Future<List<InsulinRecord>> getAll(String userId);
  Future<List<InsulinRecord>> getByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  );
  Future<InsulinRecord?> getLastRecord(String userId);
  Future<double> getTotalInsulinForDay(String userId, DateTime date);
}

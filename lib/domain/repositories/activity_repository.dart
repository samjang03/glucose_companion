import 'package:glucose_companion/data/models/activity_record.dart';

abstract class ActivityRepository {
  Future<int> insert(ActivityRecord record);
  Future<int> update(ActivityRecord record);
  Future<int> delete(int id);
  Future<ActivityRecord?> getById(int id);
  Future<List<ActivityRecord>> getAll(String userId);
  Future<List<ActivityRecord>> getByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  );
  Future<ActivityRecord?> getLastRecord(String userId);
}

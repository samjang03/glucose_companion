import 'package:glucose_companion/data/models/glucose_reading_db.dart';

abstract class GlucoseReadingRepository {
  Future<int> insert(GlucoseReadingDb reading);
  Future<int> update(GlucoseReadingDb reading);
  Future<int> delete(int id);
  Future<GlucoseReadingDb?> getById(int id);
  Future<List<GlucoseReadingDb>> getAll();
  Future<List<GlucoseReadingDb>> getByTimeRange(
    String userId,
    DateTime start,
    DateTime end,
  );
  Future<List<GlucoseReadingDb>> getLatestReadings(String userId, int limit);
  Future<GlucoseReadingDb?> getLatestReading(String userId);
  Future<void> insertBatch(List<GlucoseReadingDb> readings);
}

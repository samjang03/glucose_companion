import 'package:glucose_companion/data/models/glucose_reading.dart';

abstract class DexcomRepository {
  Future<void> authenticate(String username, String password);
  Future<GlucoseReading> getCurrentGlucoseReading();
  Future<List<GlucoseReading>> getGlucoseReadings({
    int minutes = 1440,
    int maxCount = 288,
  });
}

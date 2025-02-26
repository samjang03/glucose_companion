import 'package:glucose_companion/data/datasources/dexcom_api_client.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/domain/repositories/dexcom_repository.dart';

class DexcomRepositoryImpl implements DexcomRepository {
  final DexcomApiClient _apiClient;

  DexcomRepositoryImpl(this._apiClient);

  @override
  Future<void> authenticate(String username, String password) {
    return _apiClient.authenticate(username, password);
  }

  @override
  Future<GlucoseReading> getCurrentGlucoseReading() async {
    try {
      final reading = await _apiClient.getCurrentGlucoseReading();
      print('Repository received reading: $reading');
      return reading;
    } catch (e) {
      print('Repository error: $e');
      rethrow;
    }
  }

  @override
  Future<List<GlucoseReading>> getGlucoseReadings({
    int minutes = 1440,
    int maxCount = 288,
  }) {
    return _apiClient.getGlucoseReadings(minutes: minutes, maxCount: maxCount);
  }
}

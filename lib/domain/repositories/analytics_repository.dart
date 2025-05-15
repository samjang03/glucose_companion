// lib/domain/repositories/analytics_repository.dart
import 'package:glucose_companion/data/models/analytics_data.dart';

abstract class AnalyticsRepository {
  Future<GlucoseAnalyticsData> getAnalyticsData(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
}

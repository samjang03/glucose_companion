import 'package:glucose_companion/core/ml/glucose_predictor.dart';
import 'package:glucose_companion/data/models/activity_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';

abstract class PredictionRepository {
  Future<GlucosePrediction> predictGlucose({
    required List<GlucoseReading> recentReadings,
    required List<InsulinRecord> recentInsulin,
    required List<CarbRecord> recentCarbs,
    required List<ActivityRecord> recentActivity,
  });

  // Зберігає прогноз в БД для подальшої оцінки точності
  Future<int> savePrediction(
    String userId,
    GlucosePrediction prediction,
    int readingId,
  );

  // Отримує останній прогноз для користувача
  Future<GlucosePrediction?> getLatestPrediction(String userId);

  // Оновлює прогноз з фактичним значенням для оцінки точності
  Future<void> updatePredictionWithActual(int predictionId, double actualValue);
}

import 'package:glucose_companion/core/ml/glucose_predictor.dart';
import 'package:glucose_companion/data/datasources/local/database_helper.dart';
import 'package:glucose_companion/data/models/activity_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';
import 'package:glucose_companion/domain/repositories/prediction_repository.dart';

class PredictionRepositoryImpl implements PredictionRepository {
  final DatabaseHelper _databaseHelper;
  final GlucosePredictor _predictor;

  PredictionRepositoryImpl(this._databaseHelper, this._predictor);

  @override
  Future<GlucosePrediction> predictGlucose({
    required List<GlucoseReading> recentReadings,
    required List<InsulinRecord> recentInsulin,
    required List<CarbRecord> recentCarbs,
    required List<ActivityRecord> recentActivity,
  }) async {
    return _predictor.predictGlucose(
      recentReadings: recentReadings,
      recentInsulin: recentInsulin,
      recentCarbs: recentCarbs,
      recentActivity: recentActivity,
    );
  }

  @override
  Future<int> savePrediction(
    String userId,
    GlucosePrediction prediction,
    int readingId,
  ) async {
    final db = await _databaseHelper.database;

    // Перетворюємо enum в String для збереження
    String confidenceStr = prediction.confidence.toString().split('.').last;

    return await db.insert('predictions', {
      'user_id': userId,
      'reading_id': readingId,
      'predicted_value': prediction.predictedValue,
      'prediction_horizon': 60, // 60 хвилин
      'confidence_level': _confidenceLevelToDouble(prediction.confidence),
      'prediction_timestamp': prediction.timestamp.toIso8601String(),
      'target_timestamp': prediction.targetTimestamp.toIso8601String(),
    });
  }

  @override
  Future<GlucosePrediction?> getLatestPrediction(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'predictions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'prediction_timestamp DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return _mapToPrediction(maps.first);
    }
    return null;
  }

  @override
  Future<void> updatePredictionWithActual(
    int predictionId,
    double actualValue,
  ) async {
    final db = await _databaseHelper.database;

    // Розрахуємо метрику точності (MARD - Mean Absolute Relative Difference)
    final List<Map<String, dynamic>> maps = await db.query(
      'predictions',
      where: 'prediction_id = ?',
      whereArgs: [predictionId],
    );

    if (maps.isNotEmpty) {
      final predictedValue = maps.first['predicted_value'] as double;
      final mard = (actualValue - predictedValue).abs() / actualValue;

      await db.update(
        'predictions',
        {'actual_value': actualValue, 'accuracy_metric': mard},
        where: 'prediction_id = ?',
        whereArgs: [predictionId],
      );
    }
  }

  // Допоміжний метод для конвертації enum у double
  double _confidenceLevelToDouble(PredictionConfidence confidence) {
    switch (confidence) {
      case PredictionConfidence.low:
        return 0.3;
      case PredictionConfidence.medium:
        return 0.6;
      case PredictionConfidence.high:
        return 0.9;
      default:
        return 0.5;
    }
  }

  // Допоміжний метод для конвертації double у enum
  PredictionConfidence _doubleToConfidenceLevel(double value) {
    if (value < 0.5) {
      return PredictionConfidence.low;
    } else if (value < 0.8) {
      return PredictionConfidence.medium;
    } else {
      return PredictionConfidence.high;
    }
  }

  // Допоміжний метод для конвертації Map у GlucosePrediction
  GlucosePrediction _mapToPrediction(Map<String, dynamic> map) {
    return GlucosePrediction(
      predictedValue: map['predicted_value'],
      timestamp: DateTime.parse(map['prediction_timestamp']),
      targetTimestamp: DateTime.parse(map['target_timestamp']),
      confidence: _doubleToConfidenceLevel(map['confidence_level']),
    );
  }
}

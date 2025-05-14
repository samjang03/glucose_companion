import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/activity_record.dart';

enum PredictionConfidence { low, medium, high }

class GlucosePrediction {
  final double predictedValue;
  final DateTime timestamp;
  final DateTime targetTimestamp;
  final PredictionConfidence confidence;

  GlucosePrediction({
    required this.predictedValue,
    required this.timestamp,
    required this.targetTimestamp,
    required this.confidence,
  });
}

class GlucosePredictor {
  // В майбутньому тут буде завантаження моделі TFLite або іншої ML-бібліотеки
  // Наразі реалізуємо спрощену версію на основі правил

  /// Прогнозує рівень глюкози через 60 хвилин
  Future<GlucosePrediction> predictGlucose({
    required List<GlucoseReading> recentReadings,
    required List<InsulinRecord> recentInsulin,
    required List<CarbRecord> recentCarbs,
    required List<ActivityRecord> recentActivity,
  }) async {
    try {
      // Переконаємося що у нас є хоча б два вимірювання для розрахунку тренду
      if (recentReadings.length < 2) {
        throw Exception('Недостатньо даних для прогнозування');
      }

      // Відсортуємо дані за часом (найновіші спочатку)
      recentReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Отримуємо поточний рівень глюкози (останнє вимірювання)
      final currentGlucose = recentReadings.first.mmolL;
      final currentTimestamp = recentReadings.first.timestamp;

      // Обчислення швидкості зміни (ROC) глюкози в ммоль/л за хвилину
      double glucoseRateOfChange = 0;
      if (recentReadings.length >= 2) {
        final prevGlucose = recentReadings[1].mmolL;
        final timeDiffMinutes =
            currentTimestamp.difference(recentReadings[1].timestamp).inMinutes;
        if (timeDiffMinutes > 0) {
          glucoseRateOfChange =
              (currentGlucose - prevGlucose) / timeDiffMinutes;
        }
      }

      // Оцінка активного інсуліну (IOB)
      double insulinOnBoard = _calculateInsulInOnBoard(
        recentInsulin,
        currentTimestamp,
      );

      // Оцінка активних вуглеводів (COB)
      double carbsOnBoard = _calculateCarbsOnBoard(
        recentCarbs,
        currentTimestamp,
      );

      // Вплив фізичної активності (спрощено)
      double activityImpact = _calculateActivityImpact(
        recentActivity,
        currentTimestamp,
      );

      // Базове прогнозування на основі лінійного тренду
      double linearPrediction = currentGlucose + (glucoseRateOfChange * 60);

      // Вплив інсуліну (зниження)
      double insulinImpact =
          insulinOnBoard * 1.5; // ~1.5 ммоль/л на 1 од інсуліну

      // Вплив вуглеводів (підвищення)
      double carbsImpact = carbsOnBoard * 0.1; // ~0.1 ммоль/л на 1 г вуглеводів

      // Розрахунок кінцевого прогнозу
      double predictedValue =
          linearPrediction - insulinImpact + carbsImpact - activityImpact;

      // Обмеження прогнозу фізіологічними межами
      predictedValue = max(2.0, min(25.0, predictedValue));

      // Оцінка рівня впевненості в прогнозі
      PredictionConfidence confidence = _assessConfidence(
        recentReadings.length,
        recentInsulin,
        recentCarbs,
        glucoseRateOfChange,
      );

      // Створення об'єкту прогнозу
      return GlucosePrediction(
        predictedValue: predictedValue,
        timestamp: DateTime.now(),
        targetTimestamp: DateTime.now().add(const Duration(minutes: 60)),
        confidence: confidence,
      );
    } catch (e) {
      debugPrint('Помилка прогнозування: $e');
      rethrow;
    }
  }

  // Оцінка активного інсуліну
  double _calculateInsulInOnBoard(List<InsulinRecord> insulin, DateTime now) {
    double iob = 0.0;

    for (var record in insulin) {
      int minutesAgo = now.difference(record.timestamp).inMinutes;

      // Врахування тільки інсуліну за останні 5 годин
      if (minutesAgo <= 300) {
        // Простий експоненціальний розпад активності інсуліну
        double activity;
        // За перших 15 хвилин інсулін не активний
        if (minutesAgo < 15) {
          activity = 0.05;
        }
        // Пік активності 15-120 хвилин
        else if (minutesAgo < 120) {
          activity = 0.9;
        }
        // Поступове зниження активності
        else {
          activity = 0.9 * exp(-(minutesAgo - 120) / 120);
        }

        // Додаємо вклад цієї дози з урахуванням активності
        iob += record.units * activity;
      }
    }

    return iob;
  }

  // Оцінка активних вуглеводів
  double _calculateCarbsOnBoard(List<CarbRecord> carbs, DateTime now) {
    double cob = 0.0;

    for (var record in carbs) {
      int minutesAgo = now.difference(record.timestamp).inMinutes;

      // Врахування тільки вуглеводів за останні 4 години
      if (minutesAgo <= 240) {
        // Простий лінійний розпад активності вуглеводів
        double activity;

        // За перших 15-30 хвилин вуглеводи ще не всмоктуються повністю
        if (minutesAgo < 30) {
          activity = 0.8;
        }
        // Поступове зниження активності
        else {
          activity = max(0, 0.8 - (minutesAgo - 30) / 240);
        }

        // Додаємо вклад цієї порції з урахуванням активності
        cob += record.grams * activity;
      }
    }

    return cob;
  }

  // Вплив фізичної активності на глюкозу
  double _calculateActivityImpact(
    List<ActivityRecord> activities,
    DateTime now,
  ) {
    double impact = 0.0;

    // Мапа рівнів інтенсивності для різних типів активності
    Map<String, double> activityIntensity = {
      'Indoor climbing': 0.7,
      'Run': 0.9,
      'Strength training': 0.5,
      'Swim': 0.8,
      'Bike': 0.7,
      'Dancing': 0.6,
      'Stairclimber': 0.7,
      'Spinning': 0.8,
      'Walking': 0.4,
      'HIIT': 1.0,
      'Outdoor Bike': 0.8,
      'Walk': 0.3,
      'Aerobic Workout': 0.7,
      'Tennis': 0.6,
      'Workout': 0.5,
      'Hike': 0.6,
      'Zumba': 0.7,
      'Sport': 0.6,
      'Yoga': 0.3,
      'Swimming': 0.8,
      'Weights': 0.5,
      'Running': 0.9,
    };

    // Значення інтенсивності за замовчуванням
    const defaultIntensity = 0.5;

    for (var record in activities) {
      int minutesAgo = now.difference(record.timestamp).inMinutes;

      // Врахування тільки активності за останні 8 годин
      if (minutesAgo <= 480) {
        // Дія фізичної активності на глікемію поступово зменшується
        double effect;

        if (minutesAgo < 120) {
          effect = 1.0; // Повний ефект протягом 2 годин
        } else {
          effect = max(
            0,
            1.0 - (minutesAgo - 120) / 360,
          ); // Поступове затухання
        }

        // Отримання інтенсивності для типу активності
        double intensity =
            activityIntensity[record.activityType] ?? defaultIntensity;

        // Додавання впливу активності (базова одиниця - 1 ммоль/л за максимальної інтенсивності)
        impact += intensity * effect;
      }
    }

    return impact;
  }

  // Оцінка рівня впевненості в прогнозі
  PredictionConfidence _assessConfidence(
    int readingsCount,
    List<InsulinRecord> insulin,
    List<CarbRecord> carbs,
    double glucoseRateOfChange,
  ) {
    // Недостатньо даних - низька впевненість
    if (readingsCount < 5) {
      return PredictionConfidence.low;
    }

    // Нестабільний рівень глюкози
    if (glucoseRateOfChange.abs() > 0.1) {
      return PredictionConfidence.low;
    }

    // Наявність недавнього інсуліну/вуглеводів - середня впевненість
    bool recentInsulin = insulin.any(
      (record) => DateTime.now().difference(record.timestamp).inMinutes < 60,
    );
    bool recentCarbs = carbs.any(
      (record) => DateTime.now().difference(record.timestamp).inMinutes < 60,
    );

    if (recentInsulin || recentCarbs) {
      return PredictionConfidence.medium;
    }

    // Стабільна ситуація - висока впевненість
    return PredictionConfidence.high;
  }
}

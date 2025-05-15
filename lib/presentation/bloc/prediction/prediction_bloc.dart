import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/domain/repositories/dexcom_repository.dart';
import 'package:glucose_companion/presentation/bloc/prediction/prediction_event.dart';
import 'package:glucose_companion/presentation/bloc/prediction/prediction_state.dart';

class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  final DexcomRepository _dexcomRepository;

  PredictionBloc(this._dexcomRepository) : super(PredictionInitial()) {
    on<LoadPredictionEvent>(_onLoadPrediction);

    this.stream.listen((state) {
      print("PredictionBloc state changed to: $state");
    });
  }

  Future<void> _onLoadPrediction(
    LoadPredictionEvent event,
    Emitter<PredictionState> emit,
  ) async {
    print("Starting prediction calculation...");
    emit(PredictionLoading());
    try {
      // Отримуємо останні дані для прогнозування
      final glucoseReadings = await _dexcomRepository.getGlucoseReadings(
        minutes: 180, // Останні 3 години
        maxCount: 36, // По одному зчитуванню кожні 5 хвилин
      );

      if (glucoseReadings.isEmpty) {
        emit(const PredictionError('No glucose data available for prediction'));
        return;
      }

      // Сортуємо за часом, найновіші в кінці
      glucoseReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Базовий прогноз - просте продовження тренду
      // У реальному додатку тут буде складніший алгоритм на основі ML
      final latestReading = glucoseReadings.last;
      double predictedValue = _calculateSimplePrediction(glucoseReadings);

      // Обчислюємо рівень довіри (у справжній системі буде інша логіка)
      double confidenceLevel = _calculateConfidence(glucoseReadings);

      // Цільовий час прогнозування (60 хвилин вперед)
      final targetTime = latestReading.timestamp.add(
        const Duration(minutes: 60),
      );

      emit(
        PredictionLoaded(
          currentReading: latestReading,
          predictedValue: predictedValue,
          confidenceLevel: confidenceLevel,
          predictionTime: targetTime,
        ),
      );
      print('Emitted prediction: $predictedValue at time $targetTime');
    } catch (e) {
      emit(PredictionError(e.toString()));
      print('Prediction error: $e');
    }
  }

  // Просте лінійне прогнозування на основі останніх кількох показників
  double _calculateSimplePrediction(List<GlucoseReading> readings) {
    if (readings.length < 3) {
      return readings.last.mmolL; // Недостатньо даних для прогнозу
    }

    // Беремо останні 3 показники
    final last3 = readings.sublist(readings.length - 3);

    // Обчислюємо середню швидкість зміни (ммоль/л за 5 хвилин)
    double rateSum = 0;
    for (int i = 1; i < last3.length; i++) {
      rateSum += (last3[i].mmolL - last3[i - 1].mmolL);
    }
    double averageRate = rateSum / (last3.length - 1);

    // Прогнозуємо на 60 хвилин вперед (12 5-хвилинних інтервалів)
    double predicted = last3.last.mmolL + (averageRate * 12);

    // Обмежуємо фізіологічно можливими значеннями
    return predicted.clamp(2.0, 30.0);
  }

  // Спрощений розрахунок рівня довіри
  double _calculateConfidence(List<GlucoseReading> readings) {
    if (readings.length < 5) {
      return 0.5; // Середній рівень довіри при малій кількості даних
    }

    // Обчислюємо стабільність останніх показників
    final last5 = readings.sublist(readings.length - 5);
    double variance = 0;
    double mean = last5.map((r) => r.mmolL).reduce((a, b) => a + b) / 5;

    for (var reading in last5) {
      variance += (reading.mmolL - mean) * (reading.mmolL - mean);
    }
    variance /= 5;

    // Висока варіативність - низька довіра
    double confidence = 1.0 - (variance / 10).clamp(0.0, 0.9);

    return confidence;
  }
}

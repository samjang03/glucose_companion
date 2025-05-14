import 'package:equatable/equatable.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';

abstract class PredictionState extends Equatable {
  const PredictionState();

  @override
  List<Object?> get props => [];
}

class PredictionInitial extends PredictionState {}

class PredictionLoading extends PredictionState {}

class PredictionLoaded extends PredictionState {
  final GlucoseReading currentReading;
  final double predictedValue; // Прогнозований рівень глюкози (ммоль/л)
  final double confidenceLevel; // Рівень впевненості в прогнозі (0-1)
  final DateTime predictionTime; // Час, на який зроблено прогноз

  const PredictionLoaded({
    required this.currentReading,
    required this.predictedValue,
    required this.confidenceLevel,
    required this.predictionTime,
  });

  @override
  List<Object?> get props => [
    currentReading,
    predictedValue,
    confidenceLevel,
    predictionTime,
  ];
}

class PredictionError extends PredictionState {
  final String message;

  const PredictionError(this.message);

  @override
  List<Object> get props => [message];
}

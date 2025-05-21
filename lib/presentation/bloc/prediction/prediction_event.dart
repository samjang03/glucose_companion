import 'package:equatable/equatable.dart';

abstract class PredictionEvent extends Equatable {
  const PredictionEvent();

  @override
  List<Object> get props => [];
}

class LoadPredictionEvent extends PredictionEvent {
  // Можна додати параметри, якщо вони потрібні для прогнозування
  final int horizonMinutes;

  const LoadPredictionEvent({this.horizonMinutes = 60});

  @override
  List<Object> get props => [horizonMinutes];
}

class ClearPredictionEvent extends PredictionEvent {
  // Подія для очищення прогнозу
}

class SetUserIdEvent extends PredictionEvent {
  final String userId;

  const SetUserIdEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

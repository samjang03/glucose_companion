import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class LoadCurrentGlucoseEvent extends HomeEvent {}

class LoadGlucoseHistoryEvent extends HomeEvent {
  final int hours;

  const LoadGlucoseHistoryEvent({this.hours = 3});

  @override
  List<Object> get props => [hours];
}

class RefreshGlucoseDataEvent extends HomeEvent {}

class RecordInsulinEvent extends HomeEvent {
  final double units;
  final String insulinType;
  final String? notes;

  const RecordInsulinEvent({
    required this.units,
    required this.insulinType,
    this.notes,
  });

  @override
  List<Object> get props => [units, insulinType, notes ?? ''];
}

class RecordCarbsEvent extends HomeEvent {
  final double grams;
  final String? foodType;
  final String? notes;

  const RecordCarbsEvent({required this.grams, this.foodType, this.notes});

  @override
  List<Object> get props => [grams, foodType ?? '', notes ?? ''];
}

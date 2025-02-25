import 'package:equatable/equatable.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class CurrentGlucoseLoading extends HomeState {}

class CurrentGlucoseLoaded extends HomeState {
  final GlucoseReading currentReading;

  const CurrentGlucoseLoaded(this.currentReading);

  @override
  List<Object> get props => [currentReading];
}

class GlucoseHistoryLoading extends HomeState {}

class GlucoseHistoryLoaded extends HomeState {
  final List<GlucoseReading> readings;

  const GlucoseHistoryLoaded(this.readings);

  @override
  List<Object> get props => [readings];
}

class HomeLoadingFailure extends HomeState {
  final String message;

  const HomeLoadingFailure(this.message);

  @override
  List<Object> get props => [message];
}

class InsulinRecorded extends HomeState {}

class CarbsRecorded extends HomeState {}

class RecordingFailure extends HomeState {
  final String message;

  const RecordingFailure(this.message);

  @override
  List<Object> get props => [message];
}

// lib/presentation/bloc/analytics/analytics_state.dart
import 'package:equatable/equatable.dart';
import 'package:glucose_companion/data/models/analytics_data.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final GlucoseAnalyticsData data;
  final int days;

  const AnalyticsLoaded(this.data, this.days);

  @override
  List<Object?> get props => [data, days];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}

// lib/presentation/bloc/alerts/alerts_state.dart
import 'package:equatable/equatable.dart';
import 'package:glucose_companion/data/models/alert.dart';

abstract class AlertsState extends Equatable {
  const AlertsState();

  @override
  List<Object?> get props => [];
}

class AlertsInitial extends AlertsState {}

class AlertsLoading extends AlertsState {}

class AlertsLoaded extends AlertsState {
  final List<Alert> alerts;
  final bool activeOnly;

  const AlertsLoaded({required this.alerts, this.activeOnly = false});

  @override
  List<Object?> get props => [alerts, activeOnly];
}

class AlertUpdated extends AlertsState {}

class AlertError extends AlertsState {
  final String message;

  const AlertError(this.message);

  @override
  List<Object?> get props => [message];
}

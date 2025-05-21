// lib/presentation/bloc/alerts/alerts_event.dart
import 'package:equatable/equatable.dart';
import 'package:glucose_companion/data/models/alert.dart';

abstract class AlertsEvent extends Equatable {
  const AlertsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAlertsEvent extends AlertsEvent {
  final String userId;
  final bool activeOnly;

  const LoadAlertsEvent({required this.userId, this.activeOnly = false});

  @override
  List<Object?> get props => [userId, activeOnly];
}

class AcknowledgeAlertEvent extends AlertsEvent {
  final int alertId;

  const AcknowledgeAlertEvent(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

class DismissAlertEvent extends AlertsEvent {
  final int alertId;

  const DismissAlertEvent(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

class DeleteAlertEvent extends AlertsEvent {
  final int alertId;

  const DeleteAlertEvent(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

class CreateAlertEvent extends AlertsEvent {
  final Alert alert;

  const CreateAlertEvent(this.alert);

  @override
  List<Object?> get props => [alert];
}

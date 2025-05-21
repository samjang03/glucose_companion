// lib/presentation/bloc/alerts/alerts_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/domain/repositories/alert_repository.dart';
import 'package:glucose_companion/presentation/bloc/alerts/alerts_event.dart';
import 'package:glucose_companion/presentation/bloc/alerts/alerts_state.dart';

class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  final AlertRepository _alertRepository;

  AlertsBloc(this._alertRepository) : super(AlertsInitial()) {
    on<LoadAlertsEvent>(_onLoadAlerts);
    on<AcknowledgeAlertEvent>(_onAcknowledgeAlert);
    on<DismissAlertEvent>(_onDismissAlert);
    on<DeleteAlertEvent>(_onDeleteAlert);
    on<CreateAlertEvent>(_onCreateAlert);
  }

  Future<void> _onLoadAlerts(
    LoadAlertsEvent event,
    Emitter<AlertsState> emit,
  ) async {
    emit(AlertsLoading());
    try {
      final alerts =
          event.activeOnly
              ? await _alertRepository.getActive(event.userId)
              : await _alertRepository.getAll(event.userId);
      emit(AlertsLoaded(alerts: alerts, activeOnly: event.activeOnly));
    } catch (e) {
      emit(AlertError('Failed to load alerts: $e'));
    }
  }

  Future<void> _onAcknowledgeAlert(
    AcknowledgeAlertEvent event,
    Emitter<AlertsState> emit,
  ) async {
    try {
      await _alertRepository.acknowledge(event.alertId);
      emit(AlertUpdated());

      // Reload alerts with the same filter
      if (state is AlertsLoaded) {
        final loadedState = state as AlertsLoaded;
        add(
          LoadAlertsEvent(
            userId: loadedState.alerts.first.userId,
            activeOnly: loadedState.activeOnly,
          ),
        );
      }
    } catch (e) {
      emit(AlertError('Failed to acknowledge alert: $e'));
    }
  }

  Future<void> _onDismissAlert(
    DismissAlertEvent event,
    Emitter<AlertsState> emit,
  ) async {
    try {
      await _alertRepository.dismiss(event.alertId);
      emit(AlertUpdated());

      // Reload alerts with the same filter
      if (state is AlertsLoaded) {
        final loadedState = state as AlertsLoaded;
        add(
          LoadAlertsEvent(
            userId: loadedState.alerts.first.userId,
            activeOnly: loadedState.activeOnly,
          ),
        );
      }
    } catch (e) {
      emit(AlertError('Failed to dismiss alert: $e'));
    }
  }

  Future<void> _onDeleteAlert(
    DeleteAlertEvent event,
    Emitter<AlertsState> emit,
  ) async {
    try {
      await _alertRepository.delete(event.alertId);
      emit(AlertUpdated());

      // Reload alerts with the same filter
      if (state is AlertsLoaded) {
        final loadedState = state as AlertsLoaded;
        add(
          LoadAlertsEvent(
            userId: loadedState.alerts.first.userId,
            activeOnly: loadedState.activeOnly,
          ),
        );
      }
    } catch (e) {
      emit(AlertError('Failed to delete alert: $e'));
    }
  }

  Future<void> _onCreateAlert(
    CreateAlertEvent event,
    Emitter<AlertsState> emit,
  ) async {
    try {
      await _alertRepository.insert(event.alert);
      emit(AlertUpdated());

      // Reload alerts with the same filter
      if (state is AlertsLoaded) {
        final loadedState = state as AlertsLoaded;
        add(
          LoadAlertsEvent(
            userId: loadedState.alerts.first.userId,
            activeOnly: loadedState.activeOnly,
          ),
        );
      }
    } catch (e) {
      emit(AlertError('Failed to create alert: $e'));
    }
  }
}

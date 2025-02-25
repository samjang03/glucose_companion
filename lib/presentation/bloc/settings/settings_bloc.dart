import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/data/models/user_settings.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_event.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_state.dart';
import 'package:glucose_companion/services/settings_service.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService;

  SettingsBloc(this._settingsService) : super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<SaveSettingsEvent>(_onSaveSettings);
    on<UpdateGlucoseUnitsEvent>(_onUpdateGlucoseUnits);
    on<UpdateThresholdsEvent>(_onUpdateThresholds);
    on<UpdateDexcomRegionEvent>(_onUpdateDexcomRegion);
    on<UpdateRefreshIntervalEvent>(_onUpdateRefreshInterval);
    on<UpdateAlertSettingsEvent>(_onUpdateAlertSettings);
    on<UpdateThemeEvent>(_onUpdateTheme);
    on<UpdateUserInfoEvent>(_onUpdateUserInfo);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final settings = await _settingsService.getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> _onSaveSettings(
    SaveSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final success = await _settingsService.saveSettings(event.settings);
      if (success) {
        emit(SettingsSaved(event.settings));
        emit(SettingsLoaded(event.settings));
      } else {
        emit(const SettingsError('Failed to save settings'));
      }
    } catch (e) {
      emit(SettingsError('Error saving settings: $e'));
    }
  }

  Future<void> _onUpdateGlucoseUnits(
    UpdateGlucoseUnitsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newSettings = currentSettings.copyWith(glucoseUnits: event.units);

      add(SaveSettingsEvent(newSettings));
    }
  }

  Future<void> _onUpdateThresholds(
    UpdateThresholdsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newSettings = currentSettings.copyWith(
        lowThreshold: event.lowThreshold,
        highThreshold: event.highThreshold,
        urgentLowThreshold: event.urgentLowThreshold,
        urgentHighThreshold: event.urgentHighThreshold,
      );

      add(SaveSettingsEvent(newSettings));
    }
  }

  Future<void> _onUpdateDexcomRegion(
    UpdateDexcomRegionEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newSettings = currentSettings.copyWith(dexcomRegion: event.region);

      add(SaveSettingsEvent(newSettings));
    }
  }

  Future<void> _onUpdateRefreshInterval(
    UpdateRefreshIntervalEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newSettings = currentSettings.copyWith(
        autoRefreshInterval: event.interval,
      );

      add(SaveSettingsEvent(newSettings));
    }
  }

  Future<void> _onUpdateAlertSettings(
    UpdateAlertSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newSettings = currentSettings.copyWith(
        alertsEnabled: event.alertsEnabled,
        predictionAlertsEnabled: event.predictionAlertsEnabled,
        vibrateOnAlert: event.vibrateOnAlert,
        soundOnAlert: event.soundOnAlert,
      );

      add(SaveSettingsEvent(newSettings));
    }
  }

  Future<void> _onUpdateTheme(
    UpdateThemeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newSettings = currentSettings.copyWith(theme: event.theme);

      add(SaveSettingsEvent(newSettings));
    }
  }

  Future<void> _onUpdateUserInfo(
    UpdateUserInfoEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newSettings = currentSettings.copyWith(
        userId: event.userId,
        userEmail: event.userEmail,
      );

      add(SaveSettingsEvent(newSettings));
    }
  }
}

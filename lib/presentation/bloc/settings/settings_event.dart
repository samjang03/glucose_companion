import 'package:equatable/equatable.dart';
import 'package:glucose_companion/data/models/user_settings.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}

class SaveSettingsEvent extends SettingsEvent {
  final UserSettings settings;

  const SaveSettingsEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

class UpdateGlucoseUnitsEvent extends SettingsEvent {
  final String units;

  const UpdateGlucoseUnitsEvent(this.units);

  @override
  List<Object?> get props => [units];
}

class UpdateThresholdsEvent extends SettingsEvent {
  final double? lowThreshold;
  final double? highThreshold;
  final double? urgentLowThreshold;
  final double? urgentHighThreshold;

  const UpdateThresholdsEvent({
    this.lowThreshold,
    this.highThreshold,
    this.urgentLowThreshold,
    this.urgentHighThreshold,
  });

  @override
  List<Object?> get props => [
    lowThreshold,
    highThreshold,
    urgentLowThreshold,
    urgentHighThreshold,
  ];
}

class UpdateDexcomRegionEvent extends SettingsEvent {
  final String region;

  const UpdateDexcomRegionEvent(this.region);

  @override
  List<Object?> get props => [region];
}

class UpdateRefreshIntervalEvent extends SettingsEvent {
  final int interval;

  const UpdateRefreshIntervalEvent(this.interval);

  @override
  List<Object?> get props => [interval];
}

class UpdateAlertSettingsEvent extends SettingsEvent {
  final bool? alertsEnabled;
  final bool? predictionAlertsEnabled;
  final bool? vibrateOnAlert;
  final bool? soundOnAlert;

  const UpdateAlertSettingsEvent({
    this.alertsEnabled,
    this.predictionAlertsEnabled,
    this.vibrateOnAlert,
    this.soundOnAlert,
  });

  @override
  List<Object?> get props => [
    alertsEnabled,
    predictionAlertsEnabled,
    vibrateOnAlert,
    soundOnAlert,
  ];
}

class UpdateThemeEvent extends SettingsEvent {
  final String theme;

  const UpdateThemeEvent(this.theme);

  @override
  List<Object?> get props => [theme];
}

class UpdateUserInfoEvent extends SettingsEvent {
  final String? userId;
  final String? userEmail;

  const UpdateUserInfoEvent({this.userId, this.userEmail});

  @override
  List<Object?> get props => [userId, userEmail];
}

import 'package:equatable/equatable.dart';
import 'package:glucose_companion/data/models/user_settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final UserSettings settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsSaved extends SettingsState {
  final UserSettings settings;

  const SettingsSaved(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// НОВІ СТАНИ ДЛЯ PDF ЕКСПОРТУ
class ReportExporting extends SettingsState {
  final String message;

  const ReportExporting(this.message);

  @override
  List<Object?> get props => [message];
}

class ReportExported extends SettingsState {
  final String filePath;
  final String message;

  const ReportExported({required this.filePath, required this.message});

  @override
  List<Object?> get props => [filePath, message];
}

class ReportPreviewing extends SettingsState {}

class ReportSharing extends SettingsState {}

class ReportExportError extends SettingsState {
  final String message;

  const ReportExportError(this.message);

  @override
  List<Object?> get props => [message];
}

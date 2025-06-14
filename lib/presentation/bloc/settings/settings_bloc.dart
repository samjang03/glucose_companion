import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/data/models/user_settings.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_event.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_state.dart';
import 'package:glucose_companion/services/settings_service.dart';
import 'package:glucose_companion/services/pdf_export_service.dart';
import 'package:glucose_companion/services/report_data_service.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService;
  final PDFExportService _pdfExportService;
  final ReportDataService _reportDataService;

  SettingsBloc(
    this._settingsService,
    this._pdfExportService,
    this._reportDataService,
  ) : super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<SaveSettingsEvent>(_onSaveSettings);
    on<UpdateGlucoseUnitsEvent>(_onUpdateGlucoseUnits);
    on<UpdateThresholdsEvent>(_onUpdateThresholds);
    on<UpdateDexcomRegionEvent>(_onUpdateDexcomRegion);
    on<UpdateRefreshIntervalEvent>(_onUpdateRefreshInterval);
    on<UpdateAlertSettingsEvent>(_onUpdateAlertSettings);
    on<UpdateThemeEvent>(_onUpdateTheme);
    on<UpdateUserInfoEvent>(_onUpdateUserInfo);

    // Нові обробники для PDF експорту
    on<ExportReportEvent>(_onExportReport);
    on<PreviewReportEvent>(_onPreviewReport);
    on<ShareReportEvent>(_onShareReport);
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

  // НОВІ ОБРОБНИКИ ДЛЯ PDF ЕКСПОРТУ
  Future<void> _onExportReport(
    ExportReportEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final settings = (state as SettingsLoaded).settings;
    emit(const ReportExporting('Generating report...'));

    try {
      // Валідація параметрів
      if (!_reportDataService.validateReportParameters(
        startDate: event.startDate,
        endDate: event.endDate,
        userId: settings.userId,
      )) {
        emit(
          const ReportExportError(
            'Invalid report parameters. Please check the date range and try again.',
          ),
        );
        emit(SettingsLoaded(settings));
        return;
      }

      emit(const ReportExporting('Collecting data...'));

      // Генеруємо дані для звіту
      final reportData = await _reportDataService.generateDemoReportData(
        userId: settings.userId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(const ReportExporting('Creating PDF...'));

      // Генеруємо PDF файл
      final filePath = await _pdfExportService.generateGlucoseReport(
        reportData: reportData,
        settings: settings,
        userId: settings.userId,
      );

      emit(
        ReportExported(
          filePath: filePath,
          message: 'Report successfully generated!',
        ),
      );

      // Повертаємося до нормального стану
      await Future.delayed(const Duration(seconds: 2));
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(ReportExportError('Failed to generate report: $e'));
      emit(SettingsLoaded(settings));
    }
  }

  Future<void> _onPreviewReport(
    PreviewReportEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final settings = (state as SettingsLoaded).settings;
    emit(ReportPreviewing());

    try {
      // Валідація параметрів
      if (!_reportDataService.validateReportParameters(
        startDate: event.startDate,
        endDate: event.endDate,
        userId: settings.userId,
      )) {
        emit(
          const ReportExportError(
            'Invalid report parameters. Please check the date range and try again.',
          ),
        );
        emit(SettingsLoaded(settings));
        return;
      }

      // Генеруємо дані для звіту
      final reportData = await _reportDataService.generateDemoReportData(
        userId: settings.userId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      // Генеруємо PDF як bytes
      final pdfBytes = await _pdfExportService.generateReportBytes(
        reportData: reportData,
        settings: settings,
        userId: settings.userId,
      );

      // Показуємо попередній перегляд
      await _pdfExportService.previewReport(pdfBytes);

      // Повертаємося до нормального стану
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(ReportExportError('Failed to preview report: $e'));
      emit(SettingsLoaded(settings));
    }
  }

  Future<void> _onShareReport(
    ShareReportEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final settings = (state as SettingsLoaded).settings;
    emit(ReportSharing());

    try {
      await _pdfExportService.shareReport(event.filePath);
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(ReportExportError('Failed to share report: $e'));
      emit(SettingsLoaded(settings));
    }
  }
}

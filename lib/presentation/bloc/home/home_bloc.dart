import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/data/models/activity_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';
import 'package:glucose_companion/domain/repositories/dexcom_repository.dart';
import 'package:glucose_companion/presentation/bloc/home/home_event.dart';
import 'package:glucose_companion/presentation/bloc/home/home_state.dart';
import 'package:glucose_companion/services/alert_service.dart';
import 'package:glucose_companion/services/mock_records_service.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_bloc.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_state.dart';
import 'package:glucose_companion/data/models/user_settings.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DexcomRepository _dexcomRepository;
  final MockRecordsService _mockRecordsService;
  final AlertService _alertService;
  final SettingsBloc _settingsBloc;
  Timer? _autoRefreshTimer;

  String _currentUserId = 'default_user'; // Буде оновлено при вході в систему

  HomeBloc(
    this._dexcomRepository,
    this._mockRecordsService,
    this._alertService,
    this._settingsBloc,
  ) : super(HomeInitial()) {
    on<LoadCurrentGlucoseEvent>(_onLoadCurrentGlucose);
    on<LoadGlucoseHistoryEvent>(_onLoadGlucoseHistory);
    on<RefreshGlucoseDataEvent>(_onRefreshGlucoseData);
    on<RecordInsulinEvent>(_onRecordInsulin);
    on<RecordCarbsEvent>(_onRecordCarbs);
    on<RecordActivityEvent>(_onRecordActivity);
    on<LoadDailyRecordsEvent>(_onLoadDailyRecords);
    on<SetUserIdEvent>(_onSetUserId);
    on<UpdateInsulinRecordEvent>(_onUpdateInsulinRecord);
    on<UpdateCarbRecordEvent>(_onUpdateCarbRecord);
    on<UpdateActivityRecordEvent>(_onUpdateActivityRecord);
    on<DeleteRecordEvent>(_onDeleteRecord);

    // Автоматичне оновлення даних кожні 5 хвилин
    _startAutoRefresh();
  }

  void _onSetUserId(SetUserIdEvent event, Emitter<HomeState> emit) {
    _currentUserId = event.userId;
  }

  Future<void> _onLoadCurrentGlucose(
    LoadCurrentGlucoseEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(CurrentGlucoseLoading());
    try {
      final reading = await _dexcomRepository.getCurrentGlucoseReading();
      emit(CurrentGlucoseLoaded(reading));

      // Отримуємо налаштування для перевірки сповіщень
      final settingsState = _settingsBloc.state;
      if (settingsState is SettingsLoaded &&
          settingsState.settings.alertsEnabled) {
        // Перевіряємо показник глюкози і створюємо сповіщення, якщо потрібно
        _alertService.checkGlucoseReading(
          reading,
          _currentUserId,
          settingsState.settings,
        );
      }
    } catch (e) {
      emit(HomeLoadingFailure(e.toString()));
    }
  }

  Future<void> _onLoadGlucoseHistory(
    LoadGlucoseHistoryEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(GlucoseHistoryLoading());
    try {
      // Перетворюємо години в хвилини для API
      final minutes = event.hours * 60;

      // Обчислюємо max_count як кількість 5-хвилинних інтервалів
      final maxCount = (minutes / 5).ceil();

      final readings = await _dexcomRepository.getGlucoseReadings(
        minutes: minutes,
        maxCount: maxCount,
      );
      emit(GlucoseHistoryLoaded(readings));
    } catch (e) {
      emit(HomeLoadingFailure(e.toString()));
    }
  }

  Future<void> _onRefreshGlucoseData(
    RefreshGlucoseDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // Спочатку оновлюємо поточне значення
      add(LoadCurrentGlucoseEvent());

      // Потім оновлюємо історію
      add(const LoadGlucoseHistoryEvent(hours: 3));

      // Завантажуємо дані для поточного дня
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(HomeLoadingFailure(e.toString()));
    }
  }

  Future<void> _onRecordInsulin(
    RecordInsulinEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      print('Recording insulin: ${event.units}U ${event.insulinType}');

      final insulinRecord = InsulinRecord(
        userId: _currentUserId,
        timestamp: DateTime.now(),
        units: event.units,
        type: event.insulinType,
        notes: event.notes,
      );

      final id = await _mockRecordsService.insertInsulin(insulinRecord);
      print('Insulin record saved with ID: $id');

      emit(InsulinRecorded());

      // Автоматично завантажуємо оновлені записи
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      print('Error recording insulin: $e');
      emit(RecordingFailure('Failed to record insulin: $e'));
    }
  }

  Future<void> _onRecordCarbs(
    RecordCarbsEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      print('Recording carbs: ${event.grams}g ${event.foodType ?? 'no type'}');

      final carbRecord = CarbRecord(
        userId: _currentUserId,
        timestamp: DateTime.now(),
        grams: event.grams,
        mealType: event.foodType,
        notes: event.notes,
      );

      final id = await _mockRecordsService.insertCarb(carbRecord);
      print('Carb record saved with ID: $id');

      emit(CarbsRecorded());

      // Автоматично завантажуємо оновлені записи
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      print('Error recording carbs: $e');
      emit(RecordingFailure('Failed to record carbs: $e'));
    }
  }

  Future<void> _onRecordActivity(
    RecordActivityEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      print('Recording activity: ${event.activityType}');

      final activityRecord = ActivityRecord(
        userId: _currentUserId,
        timestamp: DateTime.now(),
        activityType: event.activityType,
        notes: event.notes,
      );

      final id = await _mockRecordsService.insertActivity(activityRecord);
      print('Activity record saved with ID: $id');

      emit(ActivityRecorded());

      // Автоматично завантажуємо оновлені записи
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      print('Error recording activity: $e');
      emit(RecordingFailure('Failed to record activity: $e'));
    }
  }

  Future<void> _onLoadDailyRecords(
    LoadDailyRecordsEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      print('Loading daily records for ${event.date}');

      final startOfDay = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print('Date range: $startOfDay to $endOfDay');

      final insulinRecords = await _mockRecordsService.getInsulinByDateRange(
        _currentUserId,
        startOfDay,
        endOfDay,
      );
      print('Loaded ${insulinRecords.length} insulin records');

      final carbRecords = await _mockRecordsService.getCarbsByDateRange(
        _currentUserId,
        startOfDay,
        endOfDay,
      );
      print('Loaded ${carbRecords.length} carb records');

      final activityRecords = await _mockRecordsService
          .getActivitiesByDateRange(_currentUserId, startOfDay, endOfDay);
      print('Loaded ${activityRecords.length} activity records');

      emit(DailyRecordsLoaded(insulinRecords, carbRecords, activityRecords));
      print('Daily records loaded successfully');
    } catch (e) {
      print('Error loading daily records: $e');
      emit(HomeLoadingFailure('Error loading records: $e'));
    }
  }

  Future<void> _onUpdateInsulinRecord(
    UpdateInsulinRecordEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _mockRecordsService.updateInsulin(event.record);
      emit(InsulinRecorded());

      // Автоматично завантажуємо оновлені записи
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(RecordingFailure('Failed to update insulin: $e'));
    }
  }

  Future<void> _onUpdateCarbRecord(
    UpdateCarbRecordEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _mockRecordsService.updateCarb(event.record);
      emit(CarbsRecorded());

      // Автоматично завантажуємо оновлені записи
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(RecordingFailure('Failed to update carbs: $e'));
    }
  }

  Future<void> _onUpdateActivityRecord(
    UpdateActivityRecordEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _mockRecordsService.updateActivity(event.record);
      emit(ActivityRecorded());

      // Автоматично завантажуємо оновлені записи
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(RecordingFailure('Failed to update activity: $e'));
    }
  }

  Future<void> _onDeleteRecord(
    DeleteRecordEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (event.recordType == 'insulin') {
        await _mockRecordsService.deleteInsulin(event.recordId);
      } else if (event.recordType == 'carbs') {
        await _mockRecordsService.deleteCarb(event.recordId);
      } else if (event.recordType == 'activity') {
        await _mockRecordsService.deleteActivity(event.recordId);
      }

      // Автоматично завантажуємо оновлені записи
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(RecordingFailure('Failed to delete record: $e'));
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => add(RefreshGlucoseDataEvent()),
    );
  }

  @override
  Future<void> close() {
    _autoRefreshTimer?.cancel();
    return super.close();
  }
}

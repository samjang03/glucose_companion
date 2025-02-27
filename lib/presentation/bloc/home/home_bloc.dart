import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/data/models/activity_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';
import 'package:glucose_companion/domain/repositories/activity_repository.dart';
import 'package:glucose_companion/domain/repositories/carb_repository.dart';
import 'package:glucose_companion/domain/repositories/dexcom_repository.dart';
import 'package:glucose_companion/domain/repositories/insulin_repository.dart';
import 'package:glucose_companion/presentation/bloc/home/home_event.dart';
import 'package:glucose_companion/presentation/bloc/home/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DexcomRepository _dexcomRepository;
  final InsulinRepository _insulinRepository;
  final CarbRepository _carbRepository;
  final ActivityRepository _activityRepository;
  Timer? _autoRefreshTimer;

  String _currentUserId = 'default_user'; // Буде оновлено при вході в систему

  HomeBloc(
    this._dexcomRepository,
    this._insulinRepository,
    this._carbRepository,
    this._activityRepository,
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
      final insulinRecord = InsulinRecord(
        userId: _currentUserId,
        timestamp: DateTime.now(),
        units: event.units,
        type: event.insulinType,
        notes: event.notes,
      );

      await _insulinRepository.insert(insulinRecord);
      emit(InsulinRecorded());

      // Оновлюємо дані для поточного дня
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(RecordingFailure(e.toString()));
    }
  }

  Future<void> _onRecordCarbs(
    RecordCarbsEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final carbRecord = CarbRecord(
        userId: _currentUserId,
        timestamp: DateTime.now(),
        grams: event.grams,
        mealType: event.foodType,
        notes: event.notes,
      );

      await _carbRepository.insert(carbRecord);
      emit(CarbsRecorded());

      // Оновлюємо дані для поточного дня
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(RecordingFailure(e.toString()));
    }
  }

  Future<void> _onLoadDailyRecords(
    LoadDailyRecordsEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final startOfDay = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final insulinRecords = await _insulinRepository.getByDateRange(
        _currentUserId,
        startOfDay,
        endOfDay,
      );

      final carbRecords = await _carbRepository.getByDateRange(
        _currentUserId,
        startOfDay,
        endOfDay,
      );

      final activityRecords = await _activityRepository.getByDateRange(
        _currentUserId,
        startOfDay,
        endOfDay,
      );

      emit(DailyRecordsLoaded(insulinRecords, carbRecords, activityRecords));
    } catch (e) {
      emit(HomeLoadingFailure(e.toString()));
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

  Future<void> _onUpdateInsulinRecord(
    UpdateInsulinRecordEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _insulinRepository.update(event.record);
      emit(InsulinRecorded());

      // Оновлюємо дані для поточного дня
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(RecordingFailure(e.toString()));
    }
  }

  Future<void> _onUpdateCarbRecord(
    UpdateCarbRecordEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _carbRepository.update(event.record);
      emit(CarbsRecorded());

      // Оновлюємо дані для поточного дня
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(RecordingFailure(e.toString()));
    }
  }

  Future<void> _onUpdateActivityRecord(
    UpdateActivityRecordEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _activityRepository.update(event.record);
      emit(ActivityRecorded());

      // Оновлюємо дані для поточного дня
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(RecordingFailure(e.toString()));
    }
  }

  Future<void> _onDeleteRecord(
    DeleteRecordEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (event.recordType == 'insulin') {
        await _insulinRepository.delete(event.recordId);
      } else if (event.recordType == 'carbs') {
        await _carbRepository.delete(event.recordId);
      } else if (event.recordType == 'activity') {
        await _activityRepository.delete(event.recordId);
      }

      // Оновлюємо дані для поточного дня
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(RecordingFailure(e.toString()));
    }
  }

  Future<void> _onRecordActivity(
    RecordActivityEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final activityRecord = ActivityRecord(
        userId: _currentUserId,
        timestamp: DateTime.now(),
        activityType: event.activityType,
        notes: event.notes,
      );

      await _activityRepository.insert(activityRecord);
      emit(ActivityRecorded());

      // Оновлюємо дані для поточного дня
      add(LoadDailyRecordsEvent(DateTime.now()));
    } catch (e) {
      emit(RecordingFailure(e.toString()));
    }
  }
}

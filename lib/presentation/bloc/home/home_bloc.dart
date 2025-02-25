import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/domain/repositories/dexcom_repository.dart';
import 'package:glucose_companion/presentation/bloc/home/home_event.dart';
import 'package:glucose_companion/presentation/bloc/home/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DexcomRepository _dexcomRepository;
  Timer? _autoRefreshTimer;

  HomeBloc(this._dexcomRepository) : super(HomeInitial()) {
    on<LoadCurrentGlucoseEvent>(_onLoadCurrentGlucose);
    on<LoadGlucoseHistoryEvent>(_onLoadGlucoseHistory);
    on<RefreshGlucoseDataEvent>(_onRefreshGlucoseData);
    on<RecordInsulinEvent>(_onRecordInsulin);
    on<RecordCarbsEvent>(_onRecordCarbs);

    // Автоматичне оновлення даних кожні 5 хвилин
    _startAutoRefresh();
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
    } catch (e) {
      emit(HomeLoadingFailure(e.toString()));
    }
  }

  Future<void> _onRecordInsulin(
    RecordInsulinEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // Тут буде код для запису інсуліну в базу даних
      // В наступних етапах ми реалізуємо цю функціональність
      emit(InsulinRecorded());
    } catch (e) {
      emit(RecordingFailure(e.toString()));
    }
  }

  Future<void> _onRecordCarbs(
    RecordCarbsEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // Тут буде код для запису вуглеводів в базу даних
      // В наступних етапах ми реалізуємо цю функціональність
      emit(CarbsRecorded());
    } catch (e) {
      emit(RecordingFailure(e.toString()));
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

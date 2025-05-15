// lib/presentation/bloc/analytics/analytics_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/data/models/analytics_data.dart';
import 'package:glucose_companion/domain/repositories/analytics_repository.dart';
import 'package:glucose_companion/presentation/bloc/analytics/analytics_event.dart';
import 'package:glucose_companion/presentation/bloc/analytics/analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository _analyticsRepository;
  String _currentUserId = 'default_user'; // Буде оновлено при вході

  AnalyticsBloc(this._analyticsRepository) : super(AnalyticsInitial()) {
    on<LoadAnalyticsEvent>(_onLoadAnalytics);
  }

  // Метод для оновлення ID користувача
  void updateUserId(String userId) {
    _currentUserId = userId;
  }

  Future<void> _onLoadAnalytics(
    LoadAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: event.days));

      final data = await _analyticsRepository.getAnalyticsData(
        _currentUserId,
        startDate,
        endDate,
      );

      emit(AnalyticsLoaded(data, event.days));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }
}

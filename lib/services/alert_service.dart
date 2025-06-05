// lib/services/alert_service.dart
import 'dart:async';
import 'package:glucose_companion/data/models/alert.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/user_settings.dart';
import 'package:glucose_companion/domain/repositories/alert_repository.dart';

class AlertService {
  final AlertRepository _alertRepository;

  // Зберігаємо історію для реалістичної логіки
  final List<double> _glucoseHistory = [];
  DateTime? _lastAlertTime;
  String? _lastAlertType;
  double? _lastPredictionValue;

  // Мінімальні інтервали між сповіщеннями різних типів (у хвилинах)
  static const Map<String, int> _alertCooldowns = {
    'urgent_low': 15, // Критично низька - найчастіше
    'low': 20, // Низька
    'urgent_high': 15, // Критично висока
    'high': 25, // Висока
    'rapid_fall': 30, // Швидке падіння
    'rapid_rise': 30, // Швидке зростання
    'prediction_low': 45, // Прогноз низької - рідше
    'prediction_high': 45, // Прогноз високої
    'data_gap': 60, // Відсутність даних
  };

  AlertService(this._alertRepository);

  // Перевірка показника глюкози з реалістичною логікою
  Future<void> checkGlucoseReading(
    GlucoseReading reading,
    String userId,
    UserSettings settings,
  ) async {
    if (!settings.alertsEnabled) return;

    final timestamp = DateTime.now();

    // Додаємо до історії (тримаємо останні 12 показників = 1 година)
    _glucoseHistory.add(reading.mmolL);
    if (_glucoseHistory.length > 12) {
      _glucoseHistory.removeAt(0);
    }

    // Валідація на фізіологічну можливість
    if (!_isPhysiologicallyValid(reading.mmolL)) {
      return;
    }

    // Перевіряємо, чи не генеруємо сповіщення занадто часто
    if (_shouldSkipAlert(timestamp)) {
      return;
    }

    // Критичні стани мають найвищий пріоритет
    if (reading.mmolL < settings.urgentLowThreshold) {
      await _createAndProcessAlert(
        userId: userId,
        type: 'urgent_low',
        value: reading.mmolL,
        message: 'Критично низька глюкоза',
        severity: 'critical',
        timestamp: timestamp,
      );
    } else if (reading.mmolL > settings.urgentHighThreshold) {
      await _createAndProcessAlert(
        userId: userId,
        type: 'urgent_high',
        value: reading.mmolL,
        message: 'Критично висока глюкоза',
        severity: 'critical',
        timestamp: timestamp,
      );
    }
    // Звичайні пороги
    else if (reading.mmolL < settings.lowThreshold) {
      await _createAndProcessAlert(
        userId: userId,
        type: 'low',
        value: reading.mmolL,
        message: 'Низька глюкоза',
        severity: 'warning',
        timestamp: timestamp,
      );
    } else if (reading.mmolL > settings.highThreshold) {
      await _createAndProcessAlert(
        userId: userId,
        type: 'high',
        value: reading.mmolL,
        message: 'Висока глюкоза',
        severity: 'warning',
        timestamp: timestamp,
      );
    }

    // Перевірка трендів тільки якщо не в критичному стані
    if (reading.mmolL >= settings.urgentLowThreshold &&
        reading.mmolL <= settings.urgentHighThreshold) {
      await _checkTrendAlerts(reading, userId, settings, timestamp);
    }
  }

  // Перевірка трендів для попередження
  Future<void> _checkTrendAlerts(
    GlucoseReading reading,
    String userId,
    UserSettings settings,
    DateTime timestamp,
  ) async {
    // Швидке падіння - попереджаємо тільки якщо є ризик гіпоглікемії
    if ((reading.trend == 6 ||
            reading.trend == 7) && // SingleDown або DoubleDown
        reading.mmolL < 6.0 && // Тільки якщо вже не дуже високо
        reading.mmolL > settings.lowThreshold) {
      // Але ще не низько

      await _createAndProcessAlert(
        userId: userId,
        type: 'rapid_fall',
        value: reading.mmolL,
        message: 'Глюкоза швидко падає',
        severity: 'warning',
        timestamp: timestamp,
      );
    }

    // Швидке зростання - попереджаємо тільки якщо є ризик гіперглікемії
    if ((reading.trend == 1 || reading.trend == 2) && // DoubleUp або SingleUp
        reading.mmolL > 7.0 && // Тільки якщо вже підвищена
        reading.mmolL < settings.highThreshold) {
      // Але ще не висока

      await _createAndProcessAlert(
        userId: userId,
        type: 'rapid_rise',
        value: reading.mmolL,
        message: 'Глюкоза швидко зростає',
        severity: 'warning',
        timestamp: timestamp,
      );
    }
  }

  // Перевірка прогнозу з реалістичною логікою
  Future<void> checkPrediction(
    double predictedValue,
    String userId,
    UserSettings settings,
    DateTime targetTimestamp,
    double confidenceLevel,
  ) async {
    if (!settings.predictionAlertsEnabled || !settings.alertsEnabled) return;

    // Прогнози створюємо тільки з достатньою впевненістю
    if (confidenceLevel < 0.7) return;

    final timestamp = DateTime.now();

    // Перевіряємо, чи змінився прогноз суттєво
    if (_lastPredictionValue != null) {
      final predictionChange = (predictedValue - _lastPredictionValue!).abs();
      if (predictionChange < 1.5) {
        // Якщо прогноз не змінився суттєво, не генеруємо нове сповіщення
        return;
      }
    }

    // Прогнози генеруємо рідше
    if (_shouldSkipAlert(timestamp, alertType: 'prediction')) {
      return;
    }

    // Перевіряємо тільки значущі відхилення від норми
    if (predictedValue < settings.lowThreshold) {
      await _createAndProcessAlert(
        userId: userId,
        type: 'prediction_low',
        value: predictedValue,
        message:
            'Прогнозується низька глюкоза о ${_formatTime(targetTimestamp)}',
        severity: 'info',
        timestamp: timestamp,
      );
      _lastPredictionValue = predictedValue;
    } else if (predictedValue > settings.highThreshold) {
      await _createAndProcessAlert(
        userId: userId,
        type: 'prediction_high',
        value: predictedValue,
        message:
            'Прогнозується висока глюкоза о ${_formatTime(targetTimestamp)}',
        severity: 'info',
        timestamp: timestamp,
      );
      _lastPredictionValue = predictedValue;
    }
  }

  // Перевірка відсутності даних
  Future<void> checkDataGap(String userId, DateTime lastReading) async {
    final now = DateTime.now();
    final differenceMinutes = now.difference(lastReading).inMinutes;

    // Сповіщення про відсутність даних тільки після 25 хвилин
    if (differenceMinutes >= 25) {
      // Перевіряємо, чи не генерували вже таке сповіщення
      if (_shouldSkipAlert(now, alertType: 'data_gap')) {
        return;
      }

      await _createAndProcessAlert(
        userId: userId,
        type: 'data_gap',
        value: null,
        message: 'Відсутні дані глюкози протягом $differenceMinutes хвилин',
        severity: differenceMinutes > 60 ? 'critical' : 'warning',
        timestamp: now,
      );
    }
  }

  // Валідація фізіологічної можливості
  bool _isPhysiologicallyValid(double glucoseValue) {
    // Перевіряємо, чи значення в розумних межах
    if (glucoseValue < 1.0 || glucoseValue > 30.0) {
      return false;
    }

    // Перевіряємо швидкість зміни відносно попереднього значення
    if (_glucoseHistory.isNotEmpty) {
      final lastValue = _glucoseHistory.last;
      final change = (glucoseValue - lastValue).abs();

      // Максимальна зміна за 5 хвилин не може перевищувати 2.0 ммоль/л
      if (change > 2.0) {
        return false;
      }
    }

    return true;
  }

  // Перевірка, чи слід пропустити сповіщення
  bool _shouldSkipAlert(DateTime timestamp, {String? alertType}) {
    if (_lastAlertTime == null) return false;

    final timeSinceLastAlert = timestamp.difference(_lastAlertTime!).inMinutes;

    // Для прогнозів - особливий інтервал
    if (alertType == 'prediction') {
      return timeSinceLastAlert < 45;
    }

    // Для data_gap - особливий інтервал
    if (alertType == 'data_gap') {
      return timeSinceLastAlert < 60;
    }

    // Загальний інтервал для звичайних сповіщень
    return timeSinceLastAlert < 15;
  }

  // Створення та обробка сповіщення
  Future<int> _createAndProcessAlert({
    required String userId,
    required String type,
    required double? value,
    required String message,
    required String severity,
    required DateTime timestamp,
  }) async {
    // Перевіряємо cooldown для конкретного типу сповіщення
    if (_lastAlertTime != null && _lastAlertType != null) {
      final cooldown = _alertCooldowns[type] ?? 20;
      final timeSinceLastAlert =
          timestamp.difference(_lastAlertTime!).inMinutes;

      if (_lastAlertType == type && timeSinceLastAlert < cooldown) {
        return -1; // Пропускаємо
      }
    }

    final alert = Alert(
      userId: userId,
      type: type,
      timestamp: timestamp,
      readingId: null,
      value: value,
      message: message,
      severity: severity,
      status: 'pending',
    );

    _lastAlertTime = timestamp;
    _lastAlertType = type;

    return await _alertRepository.insert(alert);
  }

  // Форматування часу для повідомлень
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Генерація реалістичних тестових сповіщень для демонстрації
  Future<void> generateRealisticDemoAlerts(String userId) async {
    final now = DateTime.now();

    // Очищуємо старі тестові сповіщення (необов'язково для демо)
    // await _clearOldAlerts(userId);

    // Створюємо логічну історію сповіщень за останні години

    // 3 години тому - сповіщення про швидке зростання після їжі
    await _createAlert(
      userId: userId,
      type: 'rapid_rise',
      value: 8.2,
      message: 'Глюкоза швидко зростає',
      severity: 'warning',
      timestamp: now.subtract(const Duration(hours: 3)),
    );

    // 2.5 години тому - досягнення високого рівня
    await _createAlert(
      userId: userId,
      type: 'high',
      value: 11.4,
      message: 'Висока глюкоза',
      severity: 'warning',
      timestamp: now.subtract(const Duration(minutes: 150)),
    );

    // 1.5 години тому - швидке падіння (можливо після корекції інсуліном)
    await _createAlert(
      userId: userId,
      type: 'rapid_fall',
      value: 7.8,
      message: 'Глюкоза швидко падає',
      severity: 'warning',
      timestamp: now.subtract(const Duration(minutes: 90)),
    );

    // 45 хвилин тому - прогноз низької глюкози
    await _createAlert(
      userId: userId,
      type: 'prediction_low',
      value: 3.2,
      message:
          'Прогнозується низька глюкоза о ${_formatTime(now.add(const Duration(minutes: 15)))}',
      severity: 'info',
      timestamp: now.subtract(const Duration(minutes: 45)),
    );

    // 30 хвилин тому - відсутність даних (технічна проблема)
    await _createAlert(
      userId: userId,
      type: 'data_gap',
      value: null,
      message: 'Відсутні дані глюкози протягом 27 хвилин',
      severity: 'warning',
      timestamp: now.subtract(const Duration(minutes: 30)),
    );

    // 8 хвилин тому - досягнення низького рівня (підтвердження прогнозу)
    await _createAlert(
      userId: userId,
      type: 'low',
      value: 3.6,
      message: 'Низька глюкоза',
      severity: 'warning',
      timestamp: now.subtract(const Duration(minutes: 8)),
    );

    // 3 хвилини тому - новий прогноз (після коригуючих дій)
    await _createAlert(
      userId: userId,
      type: 'prediction_low',
      value: 3.4,
      message:
          'Прогнозується низька глюкоза о ${_formatTime(now.add(const Duration(minutes: 57)))}',
      severity: 'info',
      timestamp: now.subtract(const Duration(minutes: 3)),
    );
  }

  // Допоміжний метод для створення сповіщення без перевірок (для демо)
  Future<int> _createAlert({
    required String userId,
    required String type,
    required double? value,
    required String message,
    required String severity,
    required DateTime timestamp,
  }) async {
    final alert = Alert(
      userId: userId,
      type: type,
      timestamp: timestamp,
      readingId: null,
      value: value,
      message: message,
      severity: severity,
      status: 'pending',
    );

    return await _alertRepository.insert(alert);
  }
}

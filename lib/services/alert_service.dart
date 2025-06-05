// lib/services/alert_service.dart
import 'dart:async';
import 'package:glucose_companion/data/models/alert.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/user_settings.dart';
import 'package:glucose_companion/domain/repositories/alert_repository.dart';

class AlertService {
  final AlertRepository _alertRepository;

  // Зберігаємо останні значення глюкози для логічної перевірки
  double? _lastGlucoseValue;
  DateTime? _lastAlertTime;
  String? _lastAlertType;

  AlertService(this._alertRepository);

  // Check glucose reading against thresholds and create alerts if needed
  Future<void> checkGlucoseReading(
    GlucoseReading reading,
    String userId,
    UserSettings settings,
  ) async {
    final timestamp = DateTime.now();

    // Логічна перевірка: не можна мати різкі зміни за короткий час
    if (_lastGlucoseValue != null) {
      final timeDiff =
          timestamp.difference(_lastAlertTime ?? timestamp).inMinutes;
      final glucoseDiff = (reading.mmolL - _lastGlucoseValue!).abs();

      // Якщо за останні 10 хвилин різниця більше 3 ммоль/л - ігноруємо як нереалістичну
      if (timeDiff < 10 && glucoseDiff > 3.0) {
        return;
      }
    }

    // Не генеруємо сповіщення занадто часто для одного типу
    if (_lastAlertTime != null &&
        timestamp.difference(_lastAlertTime!).inMinutes < 15) {
      return;
    }

    // Check for urgent low
    if (reading.mmolL < settings.urgentLowThreshold) {
      await _createAlert(
        userId: userId,
        type: 'urgent_low',
        readingId: null,
        value: reading.mmolL,
        message: 'Критично низька глюкоза',
        severity: 'critical',
        timestamp: timestamp,
      );
      _updateLastAlert('urgent_low', reading.mmolL, timestamp);
    }
    // Check for low
    else if (reading.mmolL < settings.lowThreshold) {
      await _createAlert(
        userId: userId,
        type: 'low',
        readingId: null,
        value: reading.mmolL,
        message: 'Низька глюкоза',
        severity: 'warning',
        timestamp: timestamp,
      );
      _updateLastAlert('low', reading.mmolL, timestamp);
    }
    // Check for urgent high
    else if (reading.mmolL > settings.urgentHighThreshold) {
      await _createAlert(
        userId: userId,
        type: 'urgent_high',
        readingId: null,
        value: reading.mmolL,
        message: 'Критично висока глюкоза',
        severity: 'critical',
        timestamp: timestamp,
      );
      _updateLastAlert('urgent_high', reading.mmolL, timestamp);
    }
    // Check for high
    else if (reading.mmolL > settings.highThreshold) {
      await _createAlert(
        userId: userId,
        type: 'high',
        readingId: null,
        value: reading.mmolL,
        message: 'Висока глюкоза',
        severity: 'warning',
        timestamp: timestamp,
      );
      _updateLastAlert('high', reading.mmolL, timestamp);
    }

    // Check trend for fast dropping (тільки якщо поточне значення не критично низьке)
    if (reading.trend == 6 || reading.trend == 7) {
      if (reading.mmolL > 4.0) {
        // Тільки якщо не в критичному діапазоні
        await _createAlert(
          userId: userId,
          type: 'rapid_fall',
          readingId: null,
          value: reading.mmolL,
          message: 'Глюкоза швидко падає',
          severity: 'warning',
          timestamp: timestamp,
        );
        _updateLastAlert('rapid_fall', reading.mmolL, timestamp);
      }
    }

    // Check trend for fast rising (тільки якщо поточне значення не критично високе)
    if (reading.trend == 1 || reading.trend == 2) {
      if (reading.mmolL < 12.0) {
        // Тільки якщо не в критичному діапазоні
        await _createAlert(
          userId: userId,
          type: 'rapid_rise',
          readingId: null,
          value: reading.mmolL,
          message: 'Глюкоза швидко зростає',
          severity: 'warning',
          timestamp: timestamp,
        );
        _updateLastAlert('rapid_rise', reading.mmolL, timestamp);
      }
    }
  }

  // Check a prediction and create alert if needed
  Future<void> checkPrediction(
    double predictedValue,
    String userId,
    UserSettings settings,
    DateTime targetTimestamp,
    double confidenceLevel,
  ) async {
    // Only create prediction alerts if enabled and with decent confidence
    if (!settings.predictionAlertsEnabled || confidenceLevel < 0.6) {
      return;
    }

    final timestamp = DateTime.now();

    // Прогнози створюємо рідше - раз на 30 хвилин
    if (_lastAlertTime != null &&
        _lastAlertType?.startsWith('prediction') == true &&
        timestamp.difference(_lastAlertTime!).inMinutes < 30) {
      return;
    }

    // Check for predicted lows
    if (predictedValue < settings.lowThreshold) {
      await _createAlert(
        userId: userId,
        type: 'prediction_low',
        readingId: null,
        value: predictedValue,
        message:
            'Прогнозується низька глюкоза о ${_formatTime(targetTimestamp)}',
        severity: 'info',
        timestamp: timestamp,
      );
      _updateLastAlert('prediction_low', predictedValue, timestamp);
    }
    // Check for predicted highs
    else if (predictedValue > settings.highThreshold) {
      await _createAlert(
        userId: userId,
        type: 'prediction_high',
        readingId: null,
        value: predictedValue,
        message:
            'Прогнозується висока глюкоза о ${_formatTime(targetTimestamp)}',
        severity: 'info',
        timestamp: timestamp,
      );
      _updateLastAlert('prediction_high', predictedValue, timestamp);
    }
  }

  // Check for absence of data
  Future<void> checkDataGap(String userId, DateTime lastReading) async {
    final now = DateTime.now();
    final differenceMinutes = now.difference(lastReading).inMinutes;

    // Alert after 25 minutes of no data
    if (differenceMinutes >= 25) {
      await _createAlert(
        userId: userId,
        type: 'data_gap',
        readingId: null,
        value: null,
        message: 'Відсутні дані глюкози протягом $differenceMinutes хвилин',
        severity: differenceMinutes > 60 ? 'critical' : 'warning',
        timestamp: now,
      );
      _updateLastAlert('data_gap', null, now);
    }
  }

  void _updateLastAlert(String type, double? value, DateTime time) {
    _lastAlertType = type;
    _lastGlucoseValue = value;
    _lastAlertTime = time;
  }

  // Helper method to create an alert
  Future<int> _createAlert({
    required String userId,
    required String type,
    required int? readingId,
    required double? value,
    required String message,
    required String severity,
    required DateTime timestamp,
  }) async {
    final alert = Alert(
      userId: userId,
      type: type,
      timestamp: timestamp,
      readingId: readingId,
      value: value,
      message: message,
      severity: severity,
      status: 'pending',
    );

    return await _alertRepository.insert(alert);
  }

  // Format time for messages
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Генерує реалістичні тестові сповіщення для демонстрації
  Future<void> generateRealisticTestAlerts(String userId) async {
    final now = DateTime.now();

    // Створюємо логічну послідовність сповіщень

    // 1. Раннє сповіщення про високу глюкозу (2 години тому)
    await _createAlert(
      userId: userId,
      type: 'high',
      readingId: null,
      value: 11.2,
      message: 'Висока глюкоза',
      severity: 'warning',
      timestamp: now.subtract(const Duration(hours: 2)),
    );

    // 2. Сповіщення про швидке падіння (1.5 години тому)
    await _createAlert(
      userId: userId,
      type: 'rapid_fall',
      readingId: null,
      value: 8.1,
      message: 'Глюкоза швидко падає',
      severity: 'warning',
      timestamp: now.subtract(const Duration(minutes: 90)),
    );

    // 3. Прогнозне сповіщення про низьку глюкозу (45 хвилин тому)
    await _createAlert(
      userId: userId,
      type: 'prediction_low',
      readingId: null,
      value: 3.5,
      message:
          'Прогнозується низька глюкоза о ${_formatTime(now.add(const Duration(minutes: 15)))}',
      severity: 'info',
      timestamp: now.subtract(const Duration(minutes: 45)),
    );

    // 4. Сповіщення про відсутність даних (30 хвилин тому)
    await _createAlert(
      userId: userId,
      type: 'data_gap',
      readingId: null,
      value: null,
      message: 'Відсутні дані глюкози протягом 27 хвилин',
      severity: 'warning',
      timestamp: now.subtract(const Duration(minutes: 30)),
    );

    // 5. Актуальне сповіщення про низьку глюкозу (5 хвилин тому)
    await _createAlert(
      userId: userId,
      type: 'low',
      readingId: null,
      value: 3.7,
      message: 'Низька глюкоза',
      severity: 'warning',
      timestamp: now.subtract(const Duration(minutes: 5)),
    );
  }

  // Додатковий метод для очищення старих сповіщень
  Future<void> cleanupOldAlerts(String userId) async {
    // Логіка очищення сповіщень старше 24 годин
    // Реалізація буде залежати від репозиторію
  }
}

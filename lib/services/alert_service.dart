// lib/services/alert_service.dart
import 'dart:async';
import 'package:glucose_companion/data/models/alert.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/user_settings.dart';
import 'package:glucose_companion/domain/repositories/alert_repository.dart';

class AlertService {
  final AlertRepository _alertRepository;

  AlertService(this._alertRepository);

  // Check glucose reading against thresholds and create alerts if needed
  Future<void> checkGlucoseReading(
    GlucoseReading reading,
    String userId,
    UserSettings settings,
  ) async {
    final timestamp = DateTime.now();

    // Check for urgent low
    if (reading.mmolL < settings.urgentLowThreshold) {
      await _createAlert(
        userId: userId,
        type: 'urgent_low',
        readingId: null, // Replace with actual reading ID if available
        value: reading.mmolL,
        message: 'Urgent Low Glucose Alert',
        severity: 'critical',
        timestamp: timestamp,
      );
    }
    // Check for low
    else if (reading.mmolL < settings.lowThreshold) {
      await _createAlert(
        userId: userId,
        type: 'low',
        readingId: null,
        value: reading.mmolL,
        message: 'Low Glucose Alert',
        severity: 'warning',
        timestamp: timestamp,
      );
    }
    // Check for urgent high
    else if (reading.mmolL > settings.urgentHighThreshold) {
      await _createAlert(
        userId: userId,
        type: 'urgent_high',
        readingId: null,
        value: reading.mmolL,
        message: 'Urgent High Glucose Alert',
        severity: 'critical',
        timestamp: timestamp,
      );
    }
    // Check for high
    else if (reading.mmolL > settings.highThreshold) {
      await _createAlert(
        userId: userId,
        type: 'high',
        readingId: null,
        value: reading.mmolL,
        message: 'High Glucose Alert',
        severity: 'warning',
        timestamp: timestamp,
      );
    }

    // Check trend for fast dropping
    if (reading.trend == 6 || reading.trend == 7) {
      // SingleDown or DoubleDown
      await _createAlert(
        userId: userId,
        type: 'rapid_fall',
        readingId: null,
        value: reading.mmolL,
        message: 'Glucose Falling Rapidly',
        severity: 'warning',
        timestamp: timestamp,
      );
    }

    // Check trend for fast rising
    if (reading.trend == 1 || reading.trend == 2) {
      // DoubleUp or SingleUp
      await _createAlert(
        userId: userId,
        type: 'rapid_rise',
        readingId: null,
        value: reading.mmolL,
        message: 'Glucose Rising Rapidly',
        severity: 'warning',
        timestamp: timestamp,
      );
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
    if (!settings.predictionAlertsEnabled || confidenceLevel < 0.5) {
      return;
    }

    final timestamp = DateTime.now();

    // Check for predicted lows
    if (predictedValue < settings.lowThreshold) {
      await _createAlert(
        userId: userId,
        type: 'prediction_low',
        readingId: null,
        value: predictedValue,
        message: 'Predicted Low Glucose at ${_formatTime(targetTimestamp)}',
        severity: 'info',
        timestamp: timestamp,
      );
    }
    // Check for predicted highs
    else if (predictedValue > settings.highThreshold) {
      await _createAlert(
        userId: userId,
        type: 'prediction_high',
        readingId: null,
        value: predictedValue,
        message: 'Predicted High Glucose at ${_formatTime(targetTimestamp)}',
        severity: 'info',
        timestamp: timestamp,
      );
    }
  }

  // Check for absence of data
  Future<void> checkDataGap(String userId, DateTime lastReading) async {
    final now = DateTime.now();
    final differenceMinutes = now.difference(lastReading).inMinutes;

    // Alert after 20 minutes of no data
    if (differenceMinutes >= 20) {
      await _createAlert(
        userId: userId,
        type: 'data_gap',
        readingId: null,
        value: null,
        message: 'No glucose data for ${differenceMinutes} minutes',
        severity: differenceMinutes > 60 ? 'critical' : 'warning',
        timestamp: now,
      );
    }
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

  // Генерує тестові сповіщення для демонстрації
  Future<void> generateTestAlerts(String userId) async {
    final now = DateTime.now();

    // Створюємо різні типи сповіщень
    await _createAlert(
      userId: userId,
      type: 'urgent_low',
      readingId: null,
      value: 2.8,
      message: 'TEST: Urgent Low Glucose Alert',
      severity: 'critical',
      timestamp: now.subtract(const Duration(minutes: 5)),
    );

    await _createAlert(
      userId: userId,
      type: 'high',
      readingId: null,
      value: 11.5,
      message: 'TEST: High Glucose Alert',
      severity: 'warning',
      timestamp: now.subtract(const Duration(minutes: 10)),
    );

    await _createAlert(
      userId: userId,
      type: 'prediction_low',
      readingId: null,
      value: 3.5,
      message:
          'TEST: Predicted Low Glucose at ${_formatTime(now.add(const Duration(minutes: 30)))}',
      severity: 'info',
      timestamp: now,
    );

    await _createAlert(
      userId: userId,
      type: 'rapid_fall',
      readingId: null,
      value: 5.8,
      message: 'TEST: Glucose Falling Rapidly',
      severity: 'warning',
      timestamp: now.subtract(const Duration(minutes: 15)),
    );

    await _createAlert(
      userId: userId,
      type: 'data_gap',
      readingId: null,
      value: null,
      message: 'TEST: No glucose data for 25 minutes',
      severity: 'warning',
      timestamp: now.subtract(const Duration(minutes: 20)),
    );
  }
}

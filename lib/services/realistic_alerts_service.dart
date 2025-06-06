// lib/services/realistic_alerts_service.dart
import 'dart:math';
import 'package:glucose_companion/data/models/alert.dart';

class RealisticAlertsService {
  static List<Alert> generateRealisticAlerts() {
    final List<Alert> alerts = [];
    final now = DateTime.now();
    final random = Random();

    // Сценарій 1: Ранкова гіперглікемія з поступовим зниженням
    _addMorningHyperScenario(alerts, now);

    // Сценарій 2: Пізня гіпоглікемія з прогнозом
    _addEveningHypoScenario(alerts, now);

    // Сценарій 3: Швидке зростання після їжі
    _addPostMealRiseScenario(alerts, now);

    // Рідкісні технічні сповіщення
    if (random.nextDouble() < 0.3) {
      _addTechnicalAlert(alerts, now);
    }

    // Сортуємо за часом (найновіші спочатку)
    alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return alerts;
  }

  static void _addMorningHyperScenario(List<Alert> alerts, DateTime now) {
    // Ранкова гіперглікемія о 7:30
    final morningTime = DateTime(now.year, now.month, now.day, 7, 30);

    alerts.add(
      Alert(
        userId: 'default_user',
        type: 'high_glucose',
        timestamp: morningTime,
        value: 12.4,
        message: 'High glucose detected',
        severity: 'warning',
        status: 'acknowledged',
        acknowledgedAt: morningTime.add(const Duration(minutes: 5)),
      ),
    );

    // Через 25 хвилин - швидке падіння
    alerts.add(
      Alert(
        userId: 'default_user',
        type: 'rapid_fall',
        timestamp: morningTime.add(const Duration(minutes: 25)),
        value: 8.9,
        message: 'Glucose falling rapidly',
        severity: 'warning',
        status: 'acknowledged',
        acknowledgedAt: morningTime.add(const Duration(minutes: 30)),
      ),
    );
  }

  static void _addEveningHypoScenario(List<Alert> alerts, DateTime now) {
    // Вечірня гіпоглікемія о 19:45
    final eveningTime = DateTime(now.year, now.month, now.day, 19, 45);

    // Спочатку швидке падіння
    alerts.add(
      Alert(
        userId: 'default_user',
        type: 'rapid_fall',
        timestamp: eveningTime.subtract(const Duration(minutes: 15)),
        value: 5.2,
        message: 'Glucose falling rapidly',
        severity: 'warning',
        status: 'acknowledged',
        acknowledgedAt: eveningTime.subtract(const Duration(minutes: 10)),
      ),
    );

    // Потім низька глюкоза
    alerts.add(
      Alert(
        userId: 'default_user',
        type: 'low_glucose',
        timestamp: eveningTime,
        value: 3.6,
        message: 'Low glucose alert',
        severity: 'warning',
        status: 'acknowledged',
        acknowledgedAt: eveningTime.add(const Duration(minutes: 2)),
      ),
    );

    // Прогноз на годину вперед - низька глюкоза (генерується за 60 хв до події)
    final predictionTime = eveningTime.add(const Duration(hours: 1));
    alerts.add(
      Alert(
        userId: 'default_user',
        type: 'prediction_low',
        timestamp: eveningTime, // Генерується в момент виявлення тренду
        value: 3.2,
        message:
            'Predicted low glucose at ${predictionTime.hour}:${predictionTime.minute.toString().padLeft(2, '0')}',
        severity: 'warning',
        status: 'pending',
      ),
    );
  }

  static void _addPostMealRiseScenario(List<Alert> alerts, DateTime now) {
    // Після обіду о 13:20 - швидке зростання
    final lunchTime = DateTime(now.year, now.month, now.day, 13, 20);

    alerts.add(
      Alert(
        userId: 'default_user',
        type: 'rapid_rise',
        timestamp: lunchTime,
        value: 8.7,
        message: 'Glucose rising rapidly',
        severity: 'warning',
        status: 'acknowledged',
        acknowledgedAt: lunchTime.add(const Duration(minutes: 3)),
      ),
    );

    // Через 35 хвилин - висока глюкоза
    alerts.add(
      Alert(
        userId: 'default_user',
        type: 'high_glucose',
        timestamp: lunchTime.add(const Duration(minutes: 35)),
        value: 11.8,
        message: 'High glucose alert',
        severity: 'warning',
        status: 'acknowledged',
        acknowledgedAt: lunchTime.add(const Duration(minutes: 40)),
      ),
    );

    // Прогноз на годину - ще вища глюкоза (генерується за 60 хв до події)
    final predictionTime = lunchTime.add(const Duration(hours: 1, minutes: 35));
    alerts.add(
      Alert(
        userId: 'default_user',
        type: 'prediction_high',
        timestamp: lunchTime.add(
          const Duration(minutes: 35),
        ), // За 60 хв до прогнозованої події
        value: 13.1,
        message:
            'Predicted high glucose at ${predictionTime.hour}:${predictionTime.minute.toString().padLeft(2, '0')}',
        severity: 'warning',
        status: 'pending',
      ),
    );
  }

  static void _addTechnicalAlert(List<Alert> alerts, DateTime now) {
    // Технічне сповіщення про втрату зв'язку 2 години тому
    final techTime = now.subtract(const Duration(hours: 2, minutes: 15));

    alerts.add(
      Alert(
        userId: 'default_user',
        type: 'data_gap',
        timestamp: techTime,
        value: null,
        message: 'No glucose data for 20 minutes',
        severity: 'info',
        status: 'dismissed',
      ),
    );
  }
}

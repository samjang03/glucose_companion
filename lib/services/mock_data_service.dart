// lib/services/mock_data_service.dart
import 'dart:math';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/activity_record.dart';

class MockDataService {
  final Random _random = Random();

  // Генерувати реалістичні дані глюкози для демонстрації
  List<GlucoseReading> generateRealisticDemoData() {
    final List<GlucoseReading> readings = [];
    final now = DateTime.now();

    // Створюємо сценарій для останніх 4 годин, що демонструє реальний день
    // Scenario: Обід -> підвищення -> корекція -> нормалізація -> перекус -> поточний стан

    final scenarioPoints = [
      // 4 години тому - стабільний рівень до обіду
      {'time': -240, 'glucose': 6.8, 'trend': 'Flat'},
      {'time': -235, 'glucose': 6.9, 'trend': 'Flat'},
      {'time': -230, 'glucose': 7.0, 'trend': 'Flat'},
      {'time': -225, 'glucose': 7.1, 'trend': 'Rising slightly'},

      // 3.5 години тому - обід і підвищення
      {'time': -220, 'glucose': 7.2, 'trend': 'Rising slightly'},
      {'time': -215, 'glucose': 7.5, 'trend': 'Rising'},
      {'time': -210, 'glucose': 8.1, 'trend': 'Rising'},
      {'time': -205, 'glucose': 8.9, 'trend': 'Rising'},
      {'time': -200, 'glucose': 9.8, 'trend': 'Rising'},
      {'time': -195, 'glucose': 10.7, 'trend': 'Rising'},
      {
        'time': -190,
        'glucose': 11.4,
        'trend': 'Rising slightly',
      }, // Тут було high alert
      // 3 години тому - піковий рівень
      {'time': -185, 'glucose': 11.8, 'trend': 'Rising slightly'},
      {'time': -180, 'glucose': 11.9, 'trend': 'Flat'}, // Тут rapid_rise alert
      {'time': -175, 'glucose': 11.7, 'trend': 'Falling slightly'},
      {'time': -170, 'glucose': 11.3, 'trend': 'Falling slightly'},

      // 2.5 години тому - корекція інсуліном
      {'time': -165, 'glucose': 10.8, 'trend': 'Falling'},
      {'time': -160, 'glucose': 10.1, 'trend': 'Falling'},
      {'time': -155, 'glucose': 9.2, 'trend': 'Falling'},
      {'time': -150, 'glucose': 8.4, 'trend': 'Falling'}, // High alert тут
      // 2 години тому - швидке падіння
      {'time': -145, 'glucose': 7.6, 'trend': 'Falling'},
      {'time': -140, 'glucose': 6.9, 'trend': 'Falling'},
      {'time': -135, 'glucose': 6.3, 'trend': 'Falling'},
      {'time': -130, 'glucose': 5.8, 'trend': 'Falling'},
      {'time': -125, 'glucose': 5.4, 'trend': 'Falling'},
      {'time': -120, 'glucose': 5.1, 'trend': 'Falling'},

      // 1.5 години тому - стабілізація
      {'time': -115, 'glucose': 4.9, 'trend': 'Falling slightly'},
      {'time': -110, 'glucose': 4.8, 'trend': 'Falling slightly'},
      {'time': -105, 'glucose': 4.7, 'trend': 'Falling slightly'},
      {'time': -100, 'glucose': 4.6, 'trend': 'Falling slightly'},
      {'time': -95, 'glucose': 4.5, 'trend': 'Falling slightly'},
      {'time': -90, 'glucose': 4.4, 'trend': 'Flat'}, // Rapid fall alert тут
      // 1 година тому - подальше падіння до низького рівня
      {'time': -85, 'glucose': 4.3, 'trend': 'Falling slightly'},
      {'time': -80, 'glucose': 4.1, 'trend': 'Falling slightly'},
      {'time': -75, 'glucose': 3.9, 'trend': 'Falling slightly'},
      {'time': -70, 'glucose': 3.7, 'trend': 'Falling slightly'},
      {'time': -65, 'glucose': 3.6, 'trend': 'Falling slightly'},
      {'time': -60, 'glucose': 3.5, 'trend': 'Flat'},

      // 45 хвилин тому - низький рівень і коригуючі дії
      {'time': -55, 'glucose': 3.4, 'trend': 'Falling slightly'},
      {'time': -50, 'glucose': 3.3, 'trend': 'Flat'},
      {'time': -45, 'glucose': 3.3, 'trend': 'Flat'}, // Prediction alert тут
      {'time': -40, 'glucose': 3.4, 'trend': 'Rising slightly'},
      {
        'time': -35,
        'glucose': 3.6,
        'trend': 'Rising slightly',
      }, // Data gap period почався
      // 30 хвилин тому - gap в даних (технічна проблема)
      // Пропуск даних на 25 хвилин

      // 8 хвилин тому - відновлення даних
      {'time': -8, 'glucose': 3.7, 'trend': 'Rising slightly'}, // Low alert тут
      {'time': -5, 'glucose': 3.8, 'trend': 'Rising slightly'},
      {
        'time': -3,
        'glucose': 3.9,
        'trend': 'Rising slightly',
      }, // Prediction alert тут
      // Поточний момент
      {'time': 0, 'glucose': 4.1, 'trend': 'Rising slightly'},
    ];

    for (var point in scenarioPoints) {
      final timeMinutes = point['time'] as int;
      final glucose = point['glucose'] as double;
      final trendStr = point['trend'] as String;

      final timestamp = now.add(Duration(minutes: timeMinutes));

      // Конвертуємо тренд в числовий код
      final trendValue = _getTrendValue(trendStr);
      final trendArrow = _getTrendArrow(trendStr);

      final mgDlValue = glucose * 18.0;

      final reading = GlucoseReading(
        value: mgDlValue,
        mmolL: glucose,
        trend: trendValue,
        trendDirection: trendStr,
        trendArrow: trendArrow,
        timestamp: timestamp,
        json: {
          'Value': mgDlValue,
          'WT': 'Date(${timestamp.millisecondsSinceEpoch})',
          'Trend': trendStr,
        },
      );

      readings.add(reading);
    }

    return readings;
  }

  // Генерувати тестові дані глюкози за вказаний період (оригінальний метод)
  List<GlucoseReading> generateMockGlucoseData(int days, String userId) {
    final List<GlucoseReading> readings = [];
    final now = DateTime.now();

    // Створюємо паттерни для більш реалістичних даних
    final List<double> dailyPattern = [
      7.8, 7.6, 7.3, 7.0, 6.8, 6.5, // Ніч 0:00-6:00
      7.2, 8.5, 9.2, 8.4, 7.8, 7.2, // Ранок 6:00-12:00
      9.0, 10.2, 9.5, 8.3, 7.5, 7.0, // День 12:00-18:00
      8.2, 9.0, 8.5, 8.0, 7.9, 7.8, // Вечір 18:00-24:00
    ];

    final dayVariability = 0.3;

    for (int d = days - 1; d >= 0; d--) {
      for (int h = 0; h < 24; h++) {
        for (int m = 0; m < 60; m += 5) {
          if (d == 0 && h > now.hour ||
              (d == 0 && h == now.hour && m > now.minute)) {
            continue;
          }

          final readingTime = DateTime(now.year, now.month, now.day - d, h, m);

          double baseValue = dailyPattern[h];
          double dayFactor =
              1.0 + (dayVariability * (_random.nextDouble() * 2 - 1));
          double value =
              baseValue * dayFactor + (_random.nextDouble() * 0.6 - 0.3);

          // Постпрандіальні піки
          if ((h == 13 || h == 19) && m <= 30) {
            value += _random.nextDouble() * 2.0;
          }

          // Рідкісні гіпоглікемії (2% випадків)
          if (_random.nextInt(100) < 2) {
            value = 3.5 + (_random.nextDouble() * 0.5);
          }

          // Рідкісні гіперглікемії (7% випадків)
          if (_random.nextInt(100) < 7) {
            value = 11.0 + (_random.nextDouble() * 3.0);
          }

          // Обмежуємо фізіологічними межами
          value = max(2.8, min(20.0, value));

          // Визначаємо реалістичний тренд
          String trendDirection = 'Flat';
          String trendArrow = '→';
          int trendValue = 4;

          if (readings.isNotEmpty) {
            final prevValue = readings.last.mmolL;
            final diff = value - prevValue;

            // Обмежуємо швидкість зміни фізіологічними межами
            if (diff.abs() > 1.0) {
              // Якщо зміна занадто велика, робимо її більш плавною
              value = prevValue + (diff > 0 ? 0.8 : -0.8);
            }

            final adjustedDiff = value - prevValue;

            if (adjustedDiff > 0.4) {
              trendDirection = 'Rising';
              trendArrow = '↑';
              trendValue = 2;
            } else if (adjustedDiff > 0.15) {
              trendDirection = 'Rising slightly';
              trendArrow = '↗';
              trendValue = 3;
            } else if (adjustedDiff < -0.4) {
              trendDirection = 'Falling';
              trendArrow = '↓';
              trendValue = 6;
            } else if (adjustedDiff < -0.15) {
              trendDirection = 'Falling slightly';
              trendArrow = '↘';
              trendValue = 5;
            }
          }

          final mgDlValue = value * 18.0;

          final reading = GlucoseReading(
            value: mgDlValue,
            mmolL: value,
            trend: trendValue,
            trendDirection: trendDirection,
            trendArrow: trendArrow,
            timestamp: readingTime,
            json: {
              'Value': mgDlValue,
              'WT': 'Date(${readingTime.millisecondsSinceEpoch})',
              'Trend': trendDirection,
            },
          );

          readings.add(reading);
        }
      }
    }

    return readings;
  }

  // Допоміжні методи для трендів
  int _getTrendValue(String trendDirection) {
    switch (trendDirection) {
      case 'Rising rapidly':
        return 1;
      case 'Rising':
        return 2;
      case 'Rising slightly':
        return 3;
      case 'Flat':
        return 4;
      case 'Falling slightly':
        return 5;
      case 'Falling':
        return 6;
      case 'Falling rapidly':
        return 7;
      default:
        return 4;
    }
  }

  String _getTrendArrow(String trendDirection) {
    switch (trendDirection) {
      case 'Rising rapidly':
        return '↑↑';
      case 'Rising':
        return '↑';
      case 'Rising slightly':
        return '↗';
      case 'Flat':
        return '→';
      case 'Falling slightly':
        return '↘';
      case 'Falling':
        return '↓';
      case 'Falling rapidly':
        return '↓↓';
      default:
        return '→';
    }
  }

  // Генерувати реалістичні записи інсуліну для демо
  List<InsulinRecord> generateRealisticDemoInsulin(String userId) {
    final List<InsulinRecord> records = [];
    final now = DateTime.now();

    // Логічні записи відповідно до сценарію глюкози
    // Базальний інсулін вранці
    records.add(
      InsulinRecord(
        id: 1,
        userId: userId,
        timestamp: now.subtract(const Duration(hours: 4, minutes: 30)),
        units: 12.0,
        type: 'Basal',
        notes: 'Ранковий базальний',
      ),
    );

    // Болюс на обід (що спричинив підвищення)
    records.add(
      InsulinRecord(
        id: 2,
        userId: userId,
        timestamp: now.subtract(const Duration(hours: 3, minutes: 45)),
        units: 4.5,
        type: 'Bolus',
        notes: 'Обід',
      ),
    );

    // Корекційний болюс через 1.5 години після обіду
    records.add(
      InsulinRecord(
        id: 3,
        userId: userId,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 15)),
        units: 2.0,
        type: 'Bolus',
        notes: 'Корекція',
      ),
    );

    return records;
  }

  // Генерувати реалістичні записи вуглеводів для демо
  List<CarbRecord> generateRealisticDemoCarbs(String userId) {
    final List<CarbRecord> records = [];
    final now = DateTime.now();

    // Сніданок
    records.add(
      CarbRecord(
        id: 1,
        userId: userId,
        timestamp: now.subtract(const Duration(hours: 5, minutes: 25)),
        grams: 45.0,
        mealType: 'Breakfast',
        notes: 'Вівсянка з фруктами',
      ),
    );

    // Обід (що спричинив підвищення)
    records.add(
      CarbRecord(
        id: 2,
        userId: userId,
        timestamp: now.subtract(const Duration(hours: 3, minutes: 43)),
        grams: 65.0,
        mealType: 'Lunch',
        notes: 'Паста з овочами',
      ),
    );

    // Перекус під час гіпоглікемії
    records.add(
      CarbRecord(
        id: 3,
        userId: userId,
        timestamp: now.subtract(const Duration(minutes: 25)),
        grams: 15.0,
        mealType: 'Snack',
        notes: 'Цукерки для корекції',
      ),
    );

    return records;
  }

  // Генерувати реалістичні записи активності для демо
  List<ActivityRecord> generateRealisticDemoActivity(String userId) {
    final List<ActivityRecord> records = [];
    final now = DateTime.now();

    // Ранкова прогулянка
    records.add(
      ActivityRecord(
        id: 1,
        userId: userId,
        timestamp: now.subtract(const Duration(hours: 6)),
        activityType: 'Walking',
        notes: 'Ранкова прогулянка',
      ),
    );

    // Спортзал після роботи (вчора)
    records.add(
      ActivityRecord(
        id: 2,
        userId: userId,
        timestamp: now.subtract(const Duration(hours: 20)),
        activityType: 'Strength training',
        notes: 'Тренування в спортзалі',
      ),
    );

    return records;
  }

  // Оригінальні методи генерації (залишаємо для сумісності)
  List<InsulinRecord> generateMockInsulinRecords(int days, String userId) {
    final List<InsulinRecord> records = [];
    final now = DateTime.now();

    final mealTimes = [
      {'hour': 7, 'minute': 30, 'bolus': true, 'baseUnits': 4.0},
      {'hour': 12, 'minute': 30, 'bolus': true, 'baseUnits': 5.0},
      {'hour': 18, 'minute': 0, 'bolus': true, 'baseUnits': 6.0},
      {'hour': 22, 'minute': 0, 'bolus': false, 'baseUnits': 12.0},
    ];

    for (int d = days - 1; d >= 0; d--) {
      for (var mealTime in mealTimes) {
        if (_random.nextDouble() < 0.1) continue;

        final hour = mealTime['hour'] as int;
        final minute = mealTime['minute'] as int;
        final isBolus = mealTime['bolus'] as bool;
        final baseUnits = mealTime['baseUnits'] as double;

        if (d == 0 &&
            (hour > now.hour || (hour == now.hour && minute > now.minute))) {
          continue;
        }

        final variation = (_random.nextDouble() * 0.4) - 0.2;
        final units = baseUnits * (1 + variation);

        final timestamp = DateTime(
          now.year,
          now.month,
          now.day - d,
          hour,
          minute,
        );

        records.add(
          InsulinRecord(
            id: records.length + 1,
            userId: userId,
            timestamp: timestamp,
            units: units,
            type: isBolus ? 'Bolus' : 'Basal',
            notes: isBolus ? ['Сніданок', 'Обід', 'Вечеря'][hour ~/ 6] : null,
          ),
        );
      }
    }

    return records;
  }

  List<CarbRecord> generateMockCarbRecords(int days, String userId) {
    final List<CarbRecord> records = [];
    final now = DateTime.now();

    final mealTimes = [
      {'hour': 7, 'minute': 25, 'type': 'Breakfast', 'baseGrams': 45.0},
      {'hour': 12, 'minute': 25, 'type': 'Lunch', 'baseGrams': 60.0},
      {'hour': 17, 'minute': 55, 'type': 'Dinner', 'baseGrams': 70.0},
      {'hour': 15, 'minute': 0, 'type': 'Snack', 'baseGrams': 20.0},
    ];

    for (int d = days - 1; d >= 0; d--) {
      for (var mealTime in mealTimes) {
        if (_random.nextDouble() < 0.15) continue;

        final hour = mealTime['hour'] as int;
        final minute = mealTime['minute'] as int;
        final type = mealTime['type'] as String;
        final baseGrams = mealTime['baseGrams'] as double;

        if (d == 0 &&
            (hour > now.hour || (hour == now.hour && minute > now.minute))) {
          continue;
        }

        final variation = (_random.nextDouble() * 0.5) - 0.25;
        final grams = baseGrams * (1 + variation);

        final timestamp = DateTime(
          now.year,
          now.month,
          now.day - d,
          hour,
          minute,
        );

        records.add(
          CarbRecord(
            id: records.length + 1,
            userId: userId,
            timestamp: timestamp,
            grams: grams,
            mealType: type,
            notes: null,
          ),
        );
      }
    }

    return records;
  }

  List<ActivityRecord> generateMockActivityRecords(int days, String userId) {
    final List<ActivityRecord> records = [];
    final now = DateTime.now();

    final activities = [
      'Прогулянка',
      'Біг',
      'Велосипед',
      'Плавання',
      'Йога',
      'Силові вправи',
      'HIIT',
    ];

    int activitiesCount = (days / 2).ceil() + _random.nextInt(days ~/ 3);

    for (int i = 0; i < activitiesCount; i++) {
      final day = _random.nextInt(days);
      if (day == 0 && now.hour < 10) continue;

      final hour = 7 + _random.nextInt(13);
      final minute = _random.nextInt(12) * 5;
      final activityType = activities[_random.nextInt(activities.length)];

      final timestamp = DateTime(
        now.year,
        now.month,
        now.day - day,
        hour,
        minute,
      );

      records.add(
        ActivityRecord(
          id: records.length + 1,
          userId: userId,
          timestamp: timestamp,
          activityType: activityType,
          notes: null,
        ),
      );
    }

    return records;
  }

  // Генерувати статистику на основі показників глюкози
  Map<String, dynamic> generateStatistics(List<GlucoseReading> readings) {
    if (readings.isEmpty) {
      return {
        'average': 0.0,
        'timeInRange': 0.0,
        'timeAboveRange': 0.0,
        'timeBelowRange': 0.0,
        'standardDeviation': 0.0,
        'estimatedA1c': 0.0,
        'gmi': 0.0,
        'cv': 0.0,
      };
    }

    double sum = 0.0;
    for (var reading in readings) {
      sum += reading.mmolL;
    }
    final average = sum / readings.length;

    double squaredDiffSum = 0.0;
    for (var reading in readings) {
      final diff = reading.mmolL - average;
      squaredDiffSum += diff * diff;
    }
    final standardDeviation = sqrt(squaredDiffSum / readings.length);

    int inRange = 0;
    int aboveRange = 0;
    int belowRange = 0;

    for (var reading in readings) {
      if (reading.mmolL >= 3.9 && reading.mmolL <= 10.0) {
        inRange++;
      } else if (reading.mmolL > 10.0) {
        aboveRange++;
      } else {
        belowRange++;
      }
    }

    final timeInRange = inRange / readings.length * 100;
    final timeAboveRange = aboveRange / readings.length * 100;
    final timeBelowRange = belowRange / readings.length * 100;

    final averageMgdl = average * 18.0;
    final gmi = 3.31 + (0.02392 * averageMgdl);
    final cv = (standardDeviation / average) * 100;
    final estimatedA1c = (average + 2.59) / 1.59;

    return {
      'average': average,
      'timeInRange': timeInRange,
      'timeAboveRange': timeAboveRange,
      'timeBelowRange': timeBelowRange,
      'standardDeviation': standardDeviation,
      'estimatedA1c': estimatedA1c,
      'gmi': gmi,
      'cv': cv,
    };
  }

  // Аналіз паттернів глікемії
  List<Map<String, dynamic>> analyzePatterns(List<GlucoseReading> readings) {
    final patterns = <Map<String, dynamic>>[];

    if (readings.length < 288) {
      return patterns;
    }

    bool hasNightHyperglycemia = false;
    int nightHighCount = 0;
    int nightTotalCount = 0;

    bool hasPostprandialHyperglycemia = false;
    int postprandialHighCount = 0;
    int postprandialTotalCount = 0;

    bool hasMorningHypoglycemia = false;
    int morningLowCount = 0;
    int morningTotalCount = 0;

    for (var reading in readings) {
      if (reading.timestamp.hour >= 0 && reading.timestamp.hour < 6) {
        nightTotalCount++;
        if (reading.mmolL > 10.0) {
          nightHighCount++;
        }
      }

      if ((reading.timestamp.hour == 7 && reading.timestamp.minute >= 30) ||
          (reading.timestamp.hour == 8 && reading.timestamp.minute <= 30) ||
          (reading.timestamp.hour == 12 && reading.timestamp.minute >= 30) ||
          (reading.timestamp.hour == 13 && reading.timestamp.minute <= 30) ||
          (reading.timestamp.hour == 18 && reading.timestamp.minute >= 30) ||
          (reading.timestamp.hour == 19 && reading.timestamp.minute <= 30)) {
        postprandialTotalCount++;
        if (reading.mmolL > 10.0) {
          postprandialHighCount++;
        }
      }

      if (reading.timestamp.hour >= 6 && reading.timestamp.hour < 10) {
        morningTotalCount++;
        if (reading.mmolL < 3.9) {
          morningLowCount++;
        }
      }
    }

    if (nightTotalCount > 0 && (nightHighCount / nightTotalCount) > 0.3) {
      patterns.add({
        'type': 'nighttime_highs',
        'title': 'Нічна гіперглікемія',
        'description': 'Підвищені рівні глюкози вночі між 00:00 та 06:00',
        'severity': 'moderate',
        'percentage': (nightHighCount / nightTotalCount) * 100,
      });
    }

    if (postprandialTotalCount > 0 &&
        (postprandialHighCount / postprandialTotalCount) > 0.4) {
      patterns.add({
        'type': 'postprandial_highs',
        'title': 'Постпрандіальна гіперглікемія',
        'description': 'Підвищені рівні глюкози після прийомів їжі',
        'severity': 'moderate',
        'percentage': (postprandialHighCount / postprandialTotalCount) * 100,
      });
    }

    if (morningTotalCount > 0 && (morningLowCount / morningTotalCount) > 0.15) {
      patterns.add({
        'type': 'morning_lows',
        'title': 'Ранкова гіпоглікемія',
        'description': 'Низькі рівні глюкози вранці',
        'severity': 'high',
        'percentage': (morningLowCount / morningTotalCount) * 100,
      });
    }

    return patterns;
  }
}

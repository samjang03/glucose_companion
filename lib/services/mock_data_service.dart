// lib/services/mock_data_service.dart
import 'dart:math';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/activity_record.dart';

class MockDataService {
  final Random _random = Random();

  // Генерувати тестові дані глюкози за вказаний період
  List<GlucoseReading> generateMockGlucoseData(int days, String userId) {
    final List<GlucoseReading> readings = [];
    final now = DateTime.now();

    // Створюємо паттерни для більш реалістичних даних
    // Базовий рівень глюкози який змінюється протягом дня
    final List<double> dailyPattern = [
      7.8, 7.6, 7.3, 7.0, 6.8, 6.5, // Ніч 0:00-6:00
      7.2, 8.5, 9.2, 8.4, 7.8, 7.2, // Ранок 6:00-12:00
      9.0, 10.2, 9.5, 8.3, 7.5, 7.0, // День 12:00-18:00
      8.2, 9.0, 8.5, 8.0, 7.9, 7.8, // Вечір 18:00-24:00
    ];

    // Коефіцієнт варіабельності для різних днів
    final dayVariability = 0.3;

    // Генеруємо дані кожні 5 хвилин для вказаної кількості днів
    for (int d = days - 1; d >= 0; d--) {
      for (int h = 0; h < 24; h++) {
        for (int m = 0; m < 60; m += 5) {
          // Якщо останній день, генеруємо тільки до поточного часу
          if (d == 0 && h > now.hour ||
              (d == 0 && h == now.hour && m > now.minute)) {
            continue;
          }

          final readingTime = DateTime(now.year, now.month, now.day - d, h, m);

          // Базове значення з щоденного патерну
          double baseValue = dailyPattern[h];

          // Додаємо варіабельність для поточного дня
          double dayFactor =
              1.0 + (dayVariability * (_random.nextDouble() * 2 - 1));

          // Додаємо невеликі випадкові коливання для кожного вимірювання
          double value =
              baseValue * dayFactor + (_random.nextDouble() * 0.6 - 0.3);

          // Якщо після обіду або вечері, іноді додаємо "піки"
          if ((h == 13 || h == 19) && m <= 30) {
            value += _random.nextDouble() * 2.0;
          }

          // Іноді додаємо низькі значення (гіпоглікемії)
          if (_random.nextInt(100) < 2) {
            value = 3.5 + (_random.nextDouble() * 0.5);
          }

          // Іноді додаємо високі значення (гіперглікемії)
          if (_random.nextInt(100) < 7) {
            value = 11.0 + (_random.nextDouble() * 3.0);
          }

          // Обмежуємо фізіологічно можливим діапазоном
          value = max(2.8, min(20.0, value));

          // Визначаємо тренд на основі попереднього значення
          String trendDirection = 'Flat';
          String trendArrow = '→';
          int trendValue = 4;

          if (readings.isNotEmpty) {
            final prevValue = readings.last.mmolL;
            final diff = value - prevValue;

            if (diff > 0.5) {
              trendDirection = 'Rising';
              trendArrow = '↑';
              trendValue = 2;
            } else if (diff > 0.2) {
              trendDirection = 'Rising slightly';
              trendArrow = '↗';
              trendValue = 3;
            } else if (diff < -0.5) {
              trendDirection = 'Falling';
              trendArrow = '↓';
              trendValue = 6;
            } else if (diff < -0.2) {
              trendDirection = 'Falling slightly';
              trendArrow = '↘';
              trendValue = 5;
            }
          }

          // Створюємо читання
          final mgDlValue = value * 18.0; // Конвертуємо в mg/dL

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

  // Генерувати тестові записи інсуліну
  List<InsulinRecord> generateMockInsulinRecords(int days, String userId) {
    final List<InsulinRecord> records = [];
    final now = DateTime.now();

    // Типовий режим прийому інсуліну протягом дня
    final mealTimes = [
      {'hour': 7, 'minute': 30, 'bolus': true, 'baseUnits': 4.0}, // Сніданок
      {'hour': 12, 'minute': 30, 'bolus': true, 'baseUnits': 5.0}, // Обід
      {'hour': 18, 'minute': 0, 'bolus': true, 'baseUnits': 6.0}, // Вечеря
      {
        'hour': 22,
        'minute': 0,
        'bolus': false,
        'baseUnits': 12.0,
      }, // Базальний на ніч
    ];

    for (int d = days - 1; d >= 0; d--) {
      // Пропускаємо деякі дози випадковим чином
      final skipChance = _random.nextDouble();

      for (var mealTime in mealTimes) {
        // 10% шанс пропустити запис
        if (_random.nextDouble() < 0.1) continue;

        final hour = mealTime['hour'] as int;
        final minute = mealTime['minute'] as int;
        final isBolus = mealTime['bolus'] as bool;
        final baseUnits = mealTime['baseUnits'] as double;

        // Якщо останній день, перевіряємо поточний час
        if (d == 0 &&
            (hour > now.hour || (hour == now.hour && minute > now.minute))) {
          continue;
        }

        // Варіюємо дозу
        final variation = (_random.nextDouble() * 0.4) - 0.2; // ±20%
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
            notes: isBolus ? ['Breakfast', 'Lunch', 'Dinner'][hour ~/ 6] : null,
          ),
        );
      }
    }

    return records;
  }

  // Генерувати тестові записи вуглеводів
  List<CarbRecord> generateMockCarbRecords(int days, String userId) {
    final List<CarbRecord> records = [];
    final now = DateTime.now();

    // Типові прийоми їжі
    final mealTimes = [
      {'hour': 7, 'minute': 25, 'type': 'Breakfast', 'baseGrams': 45.0},
      {'hour': 12, 'minute': 25, 'type': 'Lunch', 'baseGrams': 60.0},
      {'hour': 17, 'minute': 55, 'type': 'Dinner', 'baseGrams': 70.0},
      {'hour': 15, 'minute': 0, 'type': 'Snack', 'baseGrams': 20.0},
    ];

    for (int d = days - 1; d >= 0; d--) {
      for (var mealTime in mealTimes) {
        // 15% шанс пропустити запис їжі
        if (_random.nextDouble() < 0.15) continue;

        final hour = mealTime['hour'] as int;
        final minute = mealTime['minute'] as int;
        final type = mealTime['type'] as String;
        final baseGrams = mealTime['baseGrams'] as double;

        // Якщо останній день, перевіряємо поточний час
        if (d == 0 &&
            (hour > now.hour || (hour == now.hour && minute > now.minute))) {
          continue;
        }

        // Варіюємо кількість вуглеводів
        final variation = (_random.nextDouble() * 0.5) - 0.25; // ±25%
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

  // Генерувати тестові записи активності
  List<ActivityRecord> generateMockActivityRecords(int days, String userId) {
    final List<ActivityRecord> records = [];
    final now = DateTime.now();

    // Типові варіанти активності
    final activities = [
      'Walking',
      'Running',
      'Cycling',
      'Swimming',
      'Yoga',
      'Strength training',
      'HIIT',
    ];

    // В середньому одне заняття кожні 2 дні
    int activitiesCount = (days / 2).ceil() + _random.nextInt(days ~/ 3);

    for (int i = 0; i < activitiesCount; i++) {
      final day = _random.nextInt(days);
      if (day == 0 && now.hour < 10)
        continue; // Пропускаємо ранок поточного дня

      // Типово активність відбувається від 7 ранку до 8 вечора
      final hour = 7 + _random.nextInt(13);
      final minute = _random.nextInt(12) * 5; // 5-хвилинні інтервали

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

    // Розрахунок середнього значення
    double sum = 0.0;
    for (var reading in readings) {
      sum += reading.mmolL;
    }
    final average = sum / readings.length;

    // Розрахунок стандартного відхилення
    double squaredDiffSum = 0.0;
    for (var reading in readings) {
      final diff = reading.mmolL - average;
      squaredDiffSum += diff * diff;
    }
    final standardDeviation = sqrt(squaredDiffSum / readings.length);

    // Розрахунок часу в діапазоні (3.9-10.0 ммоль/л)
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

    // Розрахунок GMI (Glucose Management Indicator)
    // Формула: GMI (%) = 3.31 + 0.02392 × [середня глюкоза в mg/dL]
    final averageMgdl = average * 18.0;
    final gmi = 3.31 + (0.02392 * averageMgdl);

    // Розрахунок коефіцієнта варіації (CV)
    final cv = (standardDeviation / average) * 100;

    // Розрахунок оціночного A1c
    // Приблизна формула: A1c (%) = (average mmol/L + 2.59) / 1.59
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

    // Якщо недостатньо даних, повертаємо порожній список
    if (readings.length < 288) {
      // Менше 1 дня даних
      return patterns;
    }

    // Аналіз нічної гіперглікемії
    bool hasNightHyperglycemia = false;
    int nightHighCount = 0;
    int nightTotalCount = 0;

    // Аналіз постпрандіальної гіперглікемії
    bool hasPostprandialHyperglycemia = false;
    int postprandialHighCount = 0;
    int postprandialTotalCount = 0;

    // Аналіз ранкової гіпоглікемії
    bool hasMorningHypoglycemia = false;
    int morningLowCount = 0;
    int morningTotalCount = 0;

    // Групуємо за часом доби
    for (var reading in readings) {
      // Нічний час (00:00-06:00)
      if (reading.timestamp.hour >= 0 && reading.timestamp.hour < 6) {
        nightTotalCount++;
        if (reading.mmolL > 10.0) {
          nightHighCount++;
        }
      }

      // Після прийому їжі (припускаємо після 7:00-8:00, 12:00-13:00, 18:00-19:00)
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

      // Ранковий час (06:00-10:00)
      if (reading.timestamp.hour >= 6 && reading.timestamp.hour < 10) {
        morningTotalCount++;
        if (reading.mmolL < 3.9) {
          morningLowCount++;
        }
      }
    }

    // Визначаємо паттерни
    if (nightTotalCount > 0 && (nightHighCount / nightTotalCount) > 0.3) {
      hasNightHyperglycemia = true;
      patterns.add({
        'type': 'nighttime_highs',
        'title': 'Nighttime Highs',
        'description': 'Pattern of high glucose levels between 00:00 and 06:00',
        'severity': 'moderate',
        'percentage': (nightHighCount / nightTotalCount) * 100,
      });
    }

    if (postprandialTotalCount > 0 &&
        (postprandialHighCount / postprandialTotalCount) > 0.4) {
      hasPostprandialHyperglycemia = true;
      patterns.add({
        'type': 'postprandial_highs',
        'title': 'Postprandial Highs',
        'description': 'Pattern of high glucose levels after meals',
        'severity': 'moderate',
        'percentage': (postprandialHighCount / postprandialTotalCount) * 100,
      });
    }

    if (morningTotalCount > 0 && (morningLowCount / morningTotalCount) > 0.15) {
      hasMorningHypoglycemia = true;
      patterns.add({
        'type': 'morning_lows',
        'title': 'Morning Hypoglycemia',
        'description': 'Pattern of low glucose levels in the morning',
        'severity': 'high',
        'percentage': (morningLowCount / morningTotalCount) * 100,
      });
    }

    // Додаємо найкращий день, якщо є достатньо даних
    if (readings.length >= 288) {
      // Хоча б один повний день
      // Групуємо за днями
      final Map<String, List<GlucoseReading>> dayReadings = {};

      for (var reading in readings) {
        final day =
            '${reading.timestamp.year}-${reading.timestamp.month}-${reading.timestamp.day}';
        if (!dayReadings.containsKey(day)) {
          dayReadings[day] = [];
        }
        dayReadings[day]!.add(reading);
      }

      // Знаходимо день з найкращим TIR
      String bestDay = '';
      double bestTIR = 0.0;

      dayReadings.forEach((day, dayData) {
        // Пропускаємо неповні дні
        if (dayData.length < 144) {
          // Принаймні 12 годин даних
          return;
        }

        int inRange = 0;
        for (var reading in dayData) {
          if (reading.mmolL >= 3.9 && reading.mmolL <= 10.0) {
            inRange++;
          }
        }

        final tir = inRange / dayData.length * 100;
        if (tir > bestTIR) {
          bestTIR = tir;
          bestDay = day;
        }
      });

      if (bestDay.isNotEmpty && bestTIR > 80) {
        final parts = bestDay.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        patterns.add({
          'type': 'best_day',
          'title': 'Best Day',
          'description':
              'Your best glucose day was ${date.day}/${date.month}/${date.year}',
          'severity': 'positive',
          'percentage': bestTIR,
        });
      }
    }

    return patterns;
  }
}

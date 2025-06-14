import 'dart:math' as math;
import '../../data/models/glucose_reading.dart';
import '../../data/models/insulin_record.dart';
import '../../data/models/carb_record.dart';

class PatternAnalyzer {
  static List<Map<String, dynamic>> analyzeAdvancedPatterns(
    List<GlucoseReading> readings,
    List<InsulinRecord> insulinRecords,
    List<CarbRecord> carbRecords,
  ) {
    final patterns = <Map<String, dynamic>>[];

    // Analyze nighttime patterns
    patterns.addAll(_analyzeNighttimePatterns(readings));

    // Analyze meal-related patterns
    patterns.addAll(_analyzeMealPatterns(readings, carbRecords));

    // Analyze insulin effectiveness patterns
    patterns.addAll(_analyzeInsulinPatterns(readings, insulinRecords));

    // Find best and worst days
    patterns.addAll(_analyzeDayQuality(readings));

    return patterns;
  }

  static List<Map<String, dynamic>> _analyzeNighttimePatterns(
    List<GlucoseReading> readings,
  ) {
    final patterns = <Map<String, dynamic>>[];

    // Group readings by night (22:00 - 06:00)
    final nightReadings =
        readings.where((reading) {
          final hour = reading.timestamp.hour;
          return hour >= 22 || hour < 6;
        }).toList();

    if (nightReadings.length < 50) return patterns; // Not enough data

    // Calculate percentage of high readings at night
    final highNightReadings = nightReadings.where((r) => r.mmolL > 10.0).length;
    final highPercentage = (highNightReadings / nightReadings.length) * 100;

    if (highPercentage > 30) {
      patterns.add({
        'type': 'nighttime_highs',
        'title': 'Nighttime Highs',
        'description': 'Pattern of significant highs between 22:00 and 06:00',
        'severity': 'moderate',
        'percentage': highPercentage,
        'recommendation': 'Consider adjusting basal insulin or bedtime snack',
      });
    }

    return patterns;
  }

  static List<Map<String, dynamic>> _analyzeMealPatterns(
    List<GlucoseReading> readings,
    List<CarbRecord> carbRecords,
  ) {
    final patterns = <Map<String, dynamic>>[];

    // Analyze post-meal spikes (within 2 hours after carb intake)
    int postMealSpikes = 0;
    int totalMealPeriods = 0;

    for (var carbRecord in carbRecords) {
      final postMealReadings =
          readings.where((reading) {
            final timeDiff = reading.timestamp.difference(carbRecord.timestamp);
            return timeDiff.inMinutes >= 0 && timeDiff.inMinutes <= 120;
          }).toList();

      if (postMealReadings.isNotEmpty) {
        totalMealPeriods++;
        final maxPostMeal = postMealReadings
            .map((r) => r.mmolL)
            .reduce(math.max);
        if (maxPostMeal > 10.0) {
          postMealSpikes++;
        }
      }
    }

    if (totalMealPeriods > 5) {
      final spikePercentage = (postMealSpikes / totalMealPeriods) * 100;
      if (spikePercentage > 40) {
        patterns.add({
          'type': 'postprandial_highs',
          'title': 'Post-meal Highs',
          'description': 'Frequent glucose spikes after meals',
          'severity': 'moderate',
          'percentage': spikePercentage,
          'recommendation':
              'Consider adjusting meal-time insulin or carb counting',
        });
      }
    }

    return patterns;
  }

  static List<Map<String, dynamic>> _analyzeInsulinPatterns(
    List<GlucoseReading> readings,
    List<InsulinRecord> insulinRecords,
  ) {
    final patterns = <Map<String, dynamic>>[];

    // Analyze insulin effectiveness (glucose drop within 2-4 hours after bolus)
    int effectiveInsulin = 0;
    int totalBolusEvents = 0;

    final bolusRecords =
        insulinRecords.where((r) => r.type == 'Bolus').toList();

    for (var insulinRecord in bolusRecords) {
      final preInsulinReading =
          readings
              .where((r) => r.timestamp.isBefore(insulinRecord.timestamp))
              .lastOrNull;

      final postInsulinReadings =
          readings.where((reading) {
            final timeDiff = reading.timestamp.difference(
              insulinRecord.timestamp,
            );
            return timeDiff.inMinutes >= 120 && timeDiff.inMinutes <= 240;
          }).toList();

      if (preInsulinReading != null && postInsulinReadings.isNotEmpty) {
        totalBolusEvents++;
        final avgPostInsulin =
            postInsulinReadings.map((r) => r.mmolL).reduce((a, b) => a + b) /
            postInsulinReadings.length;

        if (avgPostInsulin < preInsulinReading.mmolL) {
          effectiveInsulin++;
        }
      }
    }

    if (totalBolusEvents > 5) {
      final effectivenessPercentage =
          (effectiveInsulin / totalBolusEvents) * 100;
      if (effectivenessPercentage < 60) {
        patterns.add({
          'type': 'insulin_effectiveness',
          'title': 'Insulin Effectiveness',
          'description': 'Lower than expected insulin effectiveness',
          'severity': 'high',
          'percentage': effectivenessPercentage,
          'recommendation':
              'Consider reviewing insulin-to-carb ratios with healthcare provider',
        });
      }
    }

    return patterns;
  }

  static List<Map<String, dynamic>> _analyzeDayQuality(
    List<GlucoseReading> readings,
  ) {
    final patterns = <Map<String, dynamic>>[];

    // Group by days and calculate TIR for each day
    final Map<String, List<GlucoseReading>> dailyReadings = {};

    for (var reading in readings) {
      final dayKey =
          '${reading.timestamp.year}-${reading.timestamp.month}-${reading.timestamp.day}';
      if (!dailyReadings.containsKey(dayKey)) {
        dailyReadings[dayKey] = [];
      }
      dailyReadings[dayKey]!.add(reading);
    }

    String? bestDay;
    double bestTIR = 0.0;
    String? worstDay;
    double worstTIR = 100.0;

    for (var entry in dailyReadings.entries) {
      if (entry.value.length < 144) continue; // Need at least 12 hours of data

      final inRange =
          entry.value.where((r) => r.mmolL >= 3.9 && r.mmolL <= 10.0).length;
      final tir = (inRange / entry.value.length) * 100;

      if (tir > bestTIR) {
        bestTIR = tir;
        bestDay = entry.key;
      }

      if (tir < worstTIR) {
        worstTIR = tir;
        worstDay = entry.key;
      }
    }

    if (bestDay != null && bestTIR > 80) {
      final parts = bestDay.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      patterns.add({
        'type': 'best_day',
        'title': 'Best Glucose Day',
        'description':
            'Your best glucose day was ${date.day}/${date.month}/${date.year}',
        'severity': 'positive',
        'percentage': bestTIR,
        'date': bestDay,
      });
    }

    if (worstDay != null && worstTIR < 50) {
      patterns.add({
        'type': 'challenging_day',
        'title': 'Challenging Day',
        'description': 'Consider reviewing what happened on $worstDay',
        'severity': 'high',
        'percentage': worstTIR,
        'date': worstDay,
      });
    }

    return patterns;
  }
}

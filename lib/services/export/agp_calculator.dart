import 'dart:math' as math;
import '../../data/models/glucose_reading.dart';

class AGPCalculator {
  static Map<String, List<double>> calculateAGP(List<GlucoseReading> readings) {
    // Group readings by time of day (5-minute intervals)
    final Map<int, List<double>> timeSlots = {};

    // Initialize time slots (288 slots for 24 hours * 12 intervals per hour)
    for (int i = 0; i < 288; i++) {
      timeSlots[i] = [];
    }

    // Group readings by time slot
    for (var reading in readings) {
      final timeSlot =
          (reading.timestamp.hour * 12) + (reading.timestamp.minute ~/ 5);
      timeSlots[timeSlot]?.add(reading.mmolL);
    }

    // Calculate percentiles for each time slot
    final Map<String, List<double>> agpData = {
      '5th': [],
      '25th': [],
      '50th': [],
      '75th': [],
      '95th': [],
    };

    for (int i = 0; i < 288; i++) {
      final values = timeSlots[i]!;
      if (values.isNotEmpty) {
        values.sort();
        agpData['5th']!.add(_calculatePercentile(values, 5));
        agpData['25th']!.add(_calculatePercentile(values, 25));
        agpData['50th']!.add(_calculatePercentile(values, 50));
        agpData['75th']!.add(_calculatePercentile(values, 75));
        agpData['95th']!.add(_calculatePercentile(values, 95));
      } else {
        // Fill with previous value or default
        final defaultValue = i > 0 ? agpData['50th']![i - 1] : 7.0;
        agpData['5th']!.add(defaultValue - 1.0);
        agpData['25th']!.add(defaultValue - 0.5);
        agpData['50th']!.add(defaultValue);
        agpData['75th']!.add(defaultValue + 0.5);
        agpData['95th']!.add(defaultValue + 1.0);
      }
    }

    return agpData;
  }

  static double _calculatePercentile(
    List<double> sortedValues,
    int percentile,
  ) {
    if (sortedValues.isEmpty) return 0.0;

    final index = (percentile / 100.0) * (sortedValues.length - 1);
    final lower = index.floor();
    final upper = index.ceil();

    if (lower == upper) {
      return sortedValues[lower];
    }

    final weight = index - lower;
    return sortedValues[lower] * (1 - weight) + sortedValues[upper] * weight;
  }
}

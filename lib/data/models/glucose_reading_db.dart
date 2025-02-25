import 'package:glucose_companion/data/models/glucose_reading.dart';

class GlucoseReadingDb {
  final int? readingId;
  final String userId;
  final DateTime timestamp;
  final double value;
  final double mmolL;
  final int? trend;
  final String? trendDescription;
  final String? trendArrow;
  final bool isValid;
  final String source;
  final String? rawData;

  GlucoseReadingDb({
    this.readingId,
    required this.userId,
    required this.timestamp,
    required this.value,
    required this.mmolL,
    this.trend,
    this.trendDescription,
    this.trendArrow,
    this.isValid = true,
    this.source = 'CGM',
    this.rawData,
  });

  factory GlucoseReadingDb.fromDexcom(GlucoseReading reading, String userId) {
    return GlucoseReadingDb(
      userId: userId,
      timestamp: reading.timestamp,
      value: reading.value,
      mmolL: reading.mmolL,
      trend: reading.trend,
      trendDescription: reading.trendDirection,
      trendArrow: reading.trendArrow,
      isValid: true,
      source: 'CGM',
      rawData: reading.json.toString(),
    );
  }

  factory GlucoseReadingDb.fromMap(Map<String, dynamic> map) {
    return GlucoseReadingDb(
      readingId: map['reading_id'],
      userId: map['user_id'],
      timestamp: DateTime.parse(map['timestamp']),
      value: map['value'],
      mmolL: map['mmol_l'],
      trend: map['trend'],
      trendDescription: map['trend_description'],
      trendArrow: map['trend_arrow'],
      isValid: map['is_valid'] == 1,
      source: map['source'],
      rawData: map['raw_data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (readingId != null) 'reading_id': readingId,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'mmol_l': mmolL,
      'trend': trend,
      'trend_description': trendDescription,
      'trend_arrow': trendArrow,
      'is_valid': isValid ? 1 : 0,
      'source': source,
      'raw_data': rawData,
    };
  }
}

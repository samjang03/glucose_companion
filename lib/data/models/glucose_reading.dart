import 'package:equatable/equatable.dart';

class GlucoseReading extends Equatable {
  final double value; // значення в mg/dL
  final double mmolL; // значення в mmol/L
  final int trend; // тренд зміни
  final String trendDirection; // напрямок тренду
  final String trendArrow; // стрілка тренду
  final DateTime timestamp; // час вимірювання

  const GlucoseReading({
    required this.value,
    required this.mmolL,
    required this.trend,
    required this.trendDirection,
    required this.trendArrow,
    required this.timestamp,
  });

  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    // Обробка дати з формату "Date(1740300691000)"
    final wtString = json['WT'] as String;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      int.parse(wtString.replaceAll('Date(', '').replaceAll(')', '')),
    );

    // Обробка значення глюкози
    final value = (json['Value'] as num).toDouble();

    return GlucoseReading(
      value: value,
      mmolL: value * 0.0555, // конвертація mg/dL в mmol/L
      trend: _getTrendValue(json['Trend'] as String),
      trendDirection: _getTrendDirection(json['Trend'] as String),
      trendArrow: _getTrendArrow(json['Trend'] as String),
      timestamp: timestamp,
    );
  }

  static int _getTrendValue(String trend) {
    switch (trend) {
      case 'DoubleUp':
        return 1;
      case 'SingleUp':
        return 2;
      case 'FortyFiveUp':
        return 3;
      case 'Flat':
        return 4;
      case 'FortyFiveDown':
        return 5;
      case 'SingleDown':
        return 6;
      case 'DoubleDown':
        return 7;
      case 'NotComputable':
        return 8;
      case 'RateOutOfRange':
        return 9;
      default:
        return 0;
    }
  }

  static String _getTrendDirection(String trend) {
    switch (trend) {
      case 'DoubleUp':
        return 'Rising rapidly';
      case 'SingleUp':
        return 'Rising';
      case 'FortyFiveUp':
        return 'Rising slightly';
      case 'Flat':
        return 'Stable';
      case 'FortyFiveDown':
        return 'Falling slightly';
      case 'SingleDown':
        return 'Falling';
      case 'DoubleDown':
        return 'Falling rapidly';
      case 'NotComputable':
        return 'Unable to determine trend';
      case 'RateOutOfRange':
        return 'Rate out of range';
      default:
        return 'No trend';
    }
  }

  static String _getTrendArrow(String trend) {
    switch (trend) {
      case 'DoubleUp':
        return '↑↑';
      case 'SingleUp':
        return '↑';
      case 'FortyFiveUp':
        return '↗';
      case 'Flat':
        return '→';
      case 'FortyFiveDown':
        return '↘';
      case 'SingleDown':
        return '↓';
      case 'DoubleDown':
        return '↓↓';
      case 'NotComputable':
        return '?';
      case 'RateOutOfRange':
        return '-';
      default:
        return '';
    }
  }

  @override
  List<Object?> get props => [
    value,
    mmolL,
    trend,
    trendDirection,
    trendArrow,
    timestamp,
  ];
}

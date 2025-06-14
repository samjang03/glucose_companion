// lib/data/models/user_settings.dart
class UserSettings {
  // Одиниці вимірювання
  final String glucoseUnits; // 'mmol_L' або 'mg_dL'

  // Порогові значення (автоматично адаптуються до одиниць)
  final double lowThreshold;
  final double highThreshold;
  final double urgentLowThreshold;
  final double urgentHighThreshold;

  // Налаштування Dexcom
  final String dexcomRegion; // 'us', 'ous', 'jp'

  // Налаштування оновлення
  final int autoRefreshInterval; // в хвилинах

  // Налаштування сповіщень
  final bool alertsEnabled;
  final bool predictionAlertsEnabled;
  final bool vibrateOnAlert;
  final bool soundOnAlert;

  // Тема оформлення
  final String theme; // 'light', 'dark', 'system'

  // Користувацькі дані
  final String userId;
  final String userEmail;

  const UserSettings({
    this.glucoseUnits = 'mmol_L',
    this.lowThreshold = 3.9,
    this.highThreshold = 10.0,
    this.urgentLowThreshold = 3.0,
    this.urgentHighThreshold = 13.9,
    this.dexcomRegion = 'ous',
    this.autoRefreshInterval = 5,
    this.alertsEnabled = true,
    this.predictionAlertsEnabled = true,
    this.vibrateOnAlert = true,
    this.soundOnAlert = true,
    this.theme = 'system',
    this.userId = '',
    this.userEmail = '',
  });

  // ✨ Метод для конвертації одиниць вимірювання з автоматичною конвертацією порогів ✨
  UserSettings convertToUnits(String newUnits) {
    if (newUnits == glucoseUnits)
      return this; // Якщо одиниці однакові, повертаємо без змін

    // Коефіцієнт конвертації
    final double conversionFactor = newUnits == 'mg_dL' ? 18.0 : (1.0 / 18.0);

    return copyWith(
      glucoseUnits: newUnits,
      lowThreshold: double.parse(
        (lowThreshold * conversionFactor).toStringAsFixed(
          newUnits == 'mg_dL' ? 0 : 1,
        ),
      ),
      highThreshold: double.parse(
        (highThreshold * conversionFactor).toStringAsFixed(
          newUnits == 'mg_dL' ? 0 : 1,
        ),
      ),
      urgentLowThreshold: double.parse(
        (urgentLowThreshold * conversionFactor).toStringAsFixed(
          newUnits == 'mg_dL' ? 0 : 1,
        ),
      ),
      urgentHighThreshold: double.parse(
        (urgentHighThreshold * conversionFactor).toStringAsFixed(
          newUnits == 'mg_dL' ? 0 : 1,
        ),
      ),
    );
  }

  // ✨ Метод для отримання правильних мінімальних та максимальних значень для слайдерів ✨
  Map<String, double> getThresholdLimits() {
    if (glucoseUnits == 'mg_dL') {
      return {
        'lowMin': 50.0,
        'lowMax': 90.0,
        'highMin': 140.0,
        'highMax': 270.0,
        'urgentLowMin': 30.0,
        'urgentLowMax': 70.0,
        'urgentHighMin': 220.0,
        'urgentHighMax': 360.0,
      };
    } else {
      return {
        'lowMin': 3.0,
        'lowMax': 5.0,
        'highMin': 8.0,
        'highMax': 15.0,
        'urgentLowMin': 2.0,
        'urgentLowMax': 4.0,
        'urgentHighMin': 12.0,
        'urgentHighMax': 20.0,
      };
    }
  }

  // ✨ Метод для форматування значень глюкози ✨
  String formatGlucoseValue(double value) {
    if (glucoseUnits == 'mg_dL') {
      return '${value.round()} mg/dL';
    } else {
      return '${value.toStringAsFixed(1)} mmol/L';
    }
  }

  String get glucoseUnitsDisplay {
    return glucoseUnits == 'mmol_L' ? 'mmol/L' : 'mg/dL';
  }

  // Конвертація в Map для збереження
  Map<String, dynamic> toMap() {
    return {
      'glucoseUnits': glucoseUnits,
      'lowThreshold': lowThreshold,
      'highThreshold': highThreshold,
      'urgentLowThreshold': urgentLowThreshold,
      'urgentHighThreshold': urgentHighThreshold,
      'dexcomRegion': dexcomRegion,
      'autoRefreshInterval': autoRefreshInterval,
      'alertsEnabled': alertsEnabled,
      'predictionAlertsEnabled': predictionAlertsEnabled,
      'vibrateOnAlert': vibrateOnAlert,
      'soundOnAlert': soundOnAlert,
      'theme': theme,
      'userId': userId,
      'userEmail': userEmail,
    };
  }

  // Створення об'єкта з Map
  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      glucoseUnits: map['glucoseUnits'] ?? 'mmol_L',
      lowThreshold: map['lowThreshold']?.toDouble() ?? 3.9,
      highThreshold: map['highThreshold']?.toDouble() ?? 10.0,
      urgentLowThreshold: map['urgentLowThreshold']?.toDouble() ?? 3.0,
      urgentHighThreshold: map['urgentHighThreshold']?.toDouble() ?? 13.9,
      dexcomRegion: map['dexcomRegion'] ?? 'ous',
      autoRefreshInterval: map['autoRefreshInterval'] ?? 5,
      alertsEnabled: map['alertsEnabled'] ?? true,
      predictionAlertsEnabled: map['predictionAlertsEnabled'] ?? true,
      vibrateOnAlert: map['vibrateOnAlert'] ?? true,
      soundOnAlert: map['soundOnAlert'] ?? true,
      theme: map['theme'] ?? 'system',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
    );
  }

  // Копіювання з можливістю зміни окремих параметрів
  UserSettings copyWith({
    String? glucoseUnits,
    double? lowThreshold,
    double? highThreshold,
    double? urgentLowThreshold,
    double? urgentHighThreshold,
    String? dexcomRegion,
    int? autoRefreshInterval,
    bool? alertsEnabled,
    bool? predictionAlertsEnabled,
    bool? vibrateOnAlert,
    bool? soundOnAlert,
    String? theme,
    String? userId,
    String? userEmail,
  }) {
    return UserSettings(
      glucoseUnits: glucoseUnits ?? this.glucoseUnits,
      lowThreshold: lowThreshold ?? this.lowThreshold,
      highThreshold: highThreshold ?? this.highThreshold,
      urgentLowThreshold: urgentLowThreshold ?? this.urgentLowThreshold,
      urgentHighThreshold: urgentHighThreshold ?? this.urgentHighThreshold,
      dexcomRegion: dexcomRegion ?? this.dexcomRegion,
      autoRefreshInterval: autoRefreshInterval ?? this.autoRefreshInterval,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      predictionAlertsEnabled:
          predictionAlertsEnabled ?? this.predictionAlertsEnabled,
      vibrateOnAlert: vibrateOnAlert ?? this.vibrateOnAlert,
      soundOnAlert: soundOnAlert ?? this.soundOnAlert,
      theme: theme ?? this.theme,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  @override
  String toString() {
    return 'UserSettings(glucoseUnits: $glucoseUnits, lowThreshold: $lowThreshold, '
        'highThreshold: $highThreshold)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserSettings &&
        other.glucoseUnits == glucoseUnits &&
        other.lowThreshold == lowThreshold &&
        other.highThreshold == highThreshold &&
        other.urgentLowThreshold == urgentLowThreshold &&
        other.urgentHighThreshold == urgentHighThreshold &&
        other.dexcomRegion == dexcomRegion &&
        other.autoRefreshInterval == autoRefreshInterval &&
        other.alertsEnabled == alertsEnabled &&
        other.predictionAlertsEnabled == predictionAlertsEnabled &&
        other.vibrateOnAlert == vibrateOnAlert &&
        other.soundOnAlert == soundOnAlert &&
        other.theme == theme &&
        other.userId == userId &&
        other.userEmail == userEmail;
  }

  @override
  int get hashCode {
    return Object.hash(
      glucoseUnits,
      lowThreshold,
      highThreshold,
      urgentLowThreshold,
      urgentHighThreshold,
      dexcomRegion,
      autoRefreshInterval,
      alertsEnabled,
      predictionAlertsEnabled,
      vibrateOnAlert,
      soundOnAlert,
      theme,
      userId,
      userEmail,
    );
  }
}

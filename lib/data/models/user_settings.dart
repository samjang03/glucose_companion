class UserSettings {
  // Одиниці вимірювання
  final String glucoseUnits; // 'mmol_L' або 'mg_dL'

  // Порогові значення для mmol/L
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
      lowThreshold: map['lowThreshold'] ?? 3.9,
      highThreshold: map['highThreshold'] ?? 10.0,
      urgentLowThreshold: map['urgentLowThreshold'] ?? 3.0,
      urgentHighThreshold: map['urgentHighThreshold'] ?? 13.9,
      dexcomRegion: map['dexcomRegion'] ?? 'ous',
      autoRefreshInterval: 5,
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
      autoRefreshInterval: 5,
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

  // Конвертація порогових значень в залежності від одиниць вимірювання
  double convertThreshold(double threshold, String toUnits) {
    if (toUnits == glucoseUnits) return threshold;

    if (toUnits == 'mg_dL') {
      // Конвертуємо з mmol/L в mg/dL
      return threshold * 18.0;
    } else {
      // Конвертуємо з mg/dL в mmol/L
      return threshold / 18.0;
    }
  }
}

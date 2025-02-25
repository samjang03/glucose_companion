import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glucose_companion/data/models/user_settings.dart';

class SettingsService {
  static const String _settingsKey = 'user_settings';

  // Метод для отримання налаштувань
  Future<UserSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_settingsKey)) {
      // Повертаємо налаштування за замовчуванням
      return const UserSettings();
    }

    try {
      final jsonString = prefs.getString(_settingsKey);
      final Map<String, dynamic> map = jsonDecode(jsonString!);
      return UserSettings.fromMap(map);
    } catch (e) {
      print('Error loading settings: $e');
      // У випадку помилки повертаємо налаштування за замовчуванням
      return const UserSettings();
    }
  }

  // Метод для збереження налаштувань
  Future<bool> saveSettings(UserSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toMap());
      return await prefs.setString(_settingsKey, jsonString);
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }

  // Метод для збереження окремого параметра
  Future<bool> updateSetting(String key, dynamic value) async {
    try {
      final settings = await getSettings();
      final Map<String, dynamic> map = settings.toMap();
      map[key] = value;

      return await saveSettings(UserSettings.fromMap(map));
    } catch (e) {
      print('Error updating setting: $e');
      return false;
    }
  }

  // Метод для конвертації значень глюкози
  double convertGlucoseValue(double value, String fromUnits, String toUnits) {
    if (fromUnits == toUnits) return value;

    if (toUnits == 'mg_dL') {
      // Конвертуємо з mmol/L в mg/dL
      return value * 18.0;
    } else {
      // Конвертуємо з mg/dL в mmol/L
      return value / 18.0;
    }
  }
}

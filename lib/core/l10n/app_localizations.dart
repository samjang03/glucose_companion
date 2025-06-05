// lib/core/l10n/app_localizations.dart
class AppLocalizations {
  static const Map<String, String> _ukrainianStrings = {
    // Загальні
    'app_name': 'SweetSight',
    'loading': 'Завантаження...',
    'error': 'Помилка',
    'cancel': 'Скасувати',
    'save': 'Зберегти',
    'edit': 'Редагувати',
    'delete': 'Видалити',
    'confirm': 'Підтвердити',
    'ok': 'ОК',
    'yes': 'Так',
    'no': 'Ні',
    'refresh': 'Оновити',
    'export': 'Експорт',
    'add': 'Додати',
    'update': 'Оновити',

    // Навігація
    'overview': 'Огляд',
    'analytics': 'Аналітика',
    'alerts': 'Сповіщення',
    'settings': 'Налаштування',

    // Головний екран
    'current_glucose': 'Поточна глюкоза',
    'glucose_trend': 'Тренд глюкози',
    'glucose_prediction': 'Прогноз глюкози',
    'todays_records': 'Записи за сьогодні',
    'statistics': 'Статистика',
    'last_update': 'Останнє оновлення:',
    'no_data_available': 'Дані відсутні',
    'in_1_hour_at': 'Через 1 годину, о',

    // Тренди глюкози
    'stable': 'Стабільно',
    'rising': 'Зростає',
    'falling': 'Падає',
    'rising_rapidly': 'Швидко зростає',
    'falling_rapidly': 'Швидко падає',
    'rising_slightly': 'Злегка зростає',
    'falling_slightly': 'Злегка падає',

    // Записи
    'record_insulin': 'Записати інсулін',
    'record_carbs': 'Записати вуглеводи',
    'record_activity': 'Записати активність',
    'add_data': 'Додати дані',
    'insulin_type': 'Тип інсуліну',
    'units': 'Одиниці',
    'carbs': 'Вуглеводи',
    'meal_type': 'Тип прийому їжі',
    'activity_type': 'Тип активності',
    'notes': 'Нотатки',
    'notes_optional': 'Нотатки (необов\'язково)',
    'bolus': 'Болюс',
    'basal': 'Базальний',
    'breakfast': 'Сніданок',
    'lunch': 'Обід',
    'dinner': 'Вечеря',
    'snack': 'Перекус',
    'u_bolus': 'О Болюс',
    'g_carbs': 'г Вуглеводи',
    'time': 'Час:',
    'meal': 'Прийом їжі:',
    'note': 'Нотатка:',

    // Статистика
    'average_glucose': 'Середня глюкоза',
    'time_in_range': 'Час у діапазоні',
    'time_above_range': 'Час вище діапазону',
    'time_below_range': 'Час нижче діапазону',
    'standard_deviation': 'Стандартне відхилення',
    'glucose_management_indicator': 'Індикатор управління глюкозою',
    'coefficient_of_variation': 'Коефіцієнт варіації',

    // Сповіщення
    'active_alerts': 'Активні сповіщення',
    'alert_history': 'Історія сповіщень',
    'urgent_low_glucose_alert': 'Критично низька глюкоза',
    'low_glucose_alert': 'Низька глюкоза',
    'high_glucose_alert': 'Висока глюкоза',
    'urgent_high_glucose_alert': 'Критично висока глюкоза',
    'glucose_falling_rapidly': 'Глюкоза швидко падає',
    'glucose_rising_rapidly': 'Глюкоза швидко зростає',
    'predicted_low_glucose_at': 'Прогнозується низька глюкоза о',
    'predicted_high_glucose_at': 'Прогнозується висока глюкоза о',
    'no_glucose_data_for': 'Відсутні дані глюкози протягом',
    'minutes': 'хвилин',
    'acknowledged': 'Підтверджено',
    'dismissed': 'Відхилено',
    'acknowledge': 'Підтвердити',
    'dismiss': 'Відхилити',
    'glucose': 'Глюкоза:',

    // Налаштування
    'measurement_units': 'Одиниці вимірювання',
    'glucose_thresholds': 'Пороги глюкози',
    'dexcom_settings': 'Налаштування Dexcom',
    'alerts_notifications': 'Сповіщення та повідомлення',
    'appearance': 'Зовнішній вигляд',
    'profile': 'Профіль',
    'low_glucose_threshold': 'Поріг низької глюкози',
    'high_glucose_threshold': 'Поріг високої глюкози',
    'urgent_low_threshold': 'Поріг критично низької глюкози',
    'urgent_high_threshold': 'Поріг критично високої глюкози',
    'below_this_value_considered_low':
        'Нижче цього значення вважається низьким',
    'above_this_value_considered_high':
        'Вище цього значення вважається високим',
    'critical_low_level_requires_immediate_action':
        'Критично низький рівень, потребує негайної дії',
    'critical_high_level_requires_attention':
        'Критично високий рівень, потребує уваги',
    'dexcom_region': 'Регіон Dexcom',
    'select_your_dexcom_account_region':
        'Оберіть регіон вашого облікового запису Dexcom',
    'united_states': 'Сполучені Штати',
    'outside_us': 'Поза межами США',
    'japan': 'Японія',
    'enable_alerts': 'Увімкнути сповіщення',
    'get_notified_for_critical_glucose_levels':
        'Отримувати сповіщення про критичні рівні глюкози',
    'prediction_alerts': 'Прогнозні сповіщення',
    'alert_when_glucose_predicted_out_of_range':
        'Сповіщення, коли глюкоза прогнозується поза діапазоном',
    'vibration': 'Вібрація',
    'vibrate_on_alert': 'Вібрувати при сповіщенні',
    'sound': 'Звук',
    'play_sound_on_alert': 'Відтворювати звук при сповіщенні',
    'light_theme': 'Світла тема',
    'dark_theme': 'Темна тема',
    'system_default': 'Системна за замовчуванням',
    'user_id': 'ID користувача',
    'email': 'Електронна пошта',
    'not_set': 'Не встановлено',
    'clear_all_data': 'Очистити всі дані',

    // Прогнозування
    'no_prediction_available': 'Прогноз недоступний',
    'get_prediction': 'Отримати прогноз',
    'try_again': 'Спробувати знову',

    // Помилки та валідація
    'please_enter_insulin_units': 'Будь ласка, введіть одиниці інсуліну',
    'please_enter_valid_number': 'Будь ласка, введіть коректне число',
    'units_must_be_greater_than_zero': 'Одиниці мають бути більше нуля',
    'please_enter_carb_amount': 'Будь ласка, введіть кількість вуглеводів',
    'carbs_must_be_greater_than_zero': 'Вуглеводи мають бути більше нуля',
    'record_saved_successfully': 'Запис успішно збережено',
    'confirm_delete': 'Підтвердити видалення',
    'are_you_sure_delete_record': 'Ви впевнені, що хочете видалити цей запис?',
    'are_you_sure_clear_all_data':
        'Ви впевнені, що хочете очистити всі ваші дані? Цю дію неможливо скасувати.',
    'all_data_has_been_cleared': 'Всі дані було очищено',
    'no_records_for_today':
        'Немає записів за сьогодні. Використовуйте кнопку + для додавання інсуліну, вуглеводів або активності.',

    // Логін
    'login_to_dexcom': 'Вхід до Dexcom',
    'username': 'Ім\'я користувача',
    'password': 'Пароль',
    'enter_your_dexcom_username': 'Введіть ваше ім\'я користувача Dexcom',
    'enter_your_dexcom_password': 'Введіть ваш пароль Dexcom',
    'login': 'Увійти',
    'logout': 'Вийти',
    'please_enter_both_username_and_password':
        'Будь ласка, введіть як ім\'я користувача, так і пароль',
    'success_current_glucose': 'Успішно! Поточна глюкоза:',
    'session_expired_login_again':
        'Ваша сесія закінчилася. Будь ласка, увійдіть знову.',
    'refresh_data': 'Оновити дані',

    // Аналітика
    'overview': 'Огляд',
    'patterns': 'Патерни',
    'agp': 'AGP',
    'days': 'днів',
    '7_days': '7 Днів',
    '14_days': '14 Днів',
    '30_days': '30 Днів',
    'days_overview': 'Огляд за {} днів',
    'glucose_metrics': 'Показники глюкози',
    'time_in_range_detailed': 'Час у діапазоні',
    'very_low': 'Дуже низько (<3.0 ммоль/л)',
    'low': 'Низько (3.0-3.9 ммоль/л)',
    'in_range': 'У діапазоні (3.9-10.0 ммоль/л)',
    'high': 'Високо (10.0-13.9 ммоль/л)',
    'very_high': 'Дуже високо (>13.9 ммоль/л)',
    'daily_average_patterns': 'Щоденні середні патерни',
    'ambulatory_glucose_profile': 'Амбулаторний профіль глюкози (AGP)',
    'based_on_days_of_data': 'На основі {} днів даних',
    'agp_description':
        'AGP — це зведення значень глюкози з періоду звіту, з медіаною (50%) та іншими перцентилями, показаними так, ніби вони відбулися за один день.',
    'daily_profiles': 'Щоденні профілі',
    'no_significant_patterns_detected': 'Значущих патернів не виявлено',
    'no_data': 'Немає даних',

    // AGP легенда
    'legend': 'Легенда:',
    'median': '50% (Медіана)',
    'middle_value': 'Середнє значення',
    'interquartile_range': 'Міжквартильний діапазон',
    '90_percent_of_readings': '90% вимірювань',
    'target_range': 'Цільовий діапазон',

    // Експорт
    'export_data': 'Експорт даних',
    'export_glucose_data': 'Експорт даних глюкози',
    'export_period': 'Період експорту',
    'last_7_days': 'Останні 7 днів',
    'last_14_days': 'Останні 14 днів',
    'last_30_days': 'Останні 30 днів',
    'export_format': 'Формат експорту',
    'csv_format': 'CSV файл',
    'excel_format': 'Excel файл',
    'pdf_report': 'PDF звіт',
    'export_successful': 'Експорт успішний',
    'export_failed': 'Помилка експорту',
    'data_exported_successfully': 'Дані успішно експортовано',
    'failed_to_export_data': 'Не вдалося експортувати дані',
  };

  static String get(String key) {
    return _ukrainianStrings[key] ?? key;
  }

  static String getWithParam(String key, String param) {
    final template = _ukrainianStrings[key] ?? key;
    return template.replaceAll('{}', param);
  }

  // Методи для зручності
  static String get appName => get('app_name');
  static String get overview => get('overview');
  static String get analytics => get('analytics');
  static String get alerts => get('alerts');
  static String get settings => get('settings');
  static String get currentGlucose => get('current_glucose');
  static String get glucoseTrend => get('glucose_trend');
  static String get glucosePrediction => get('glucose_prediction');
  static String get todaysRecords => get('todays_records');
  static String get statistics => get('statistics');
  static String get lastUpdate => get('last_update');
  static String get noDataAvailable => get('no_data_available');
  static String get addData => get('add_data');
  static String get recordInsulin => get('record_insulin');
  static String get recordCarbs => get('record_carbs');
  static String get recordActivity => get('record_activity');
  static String get stable => get('stable');
  static String get export => get('export');
  static String get refresh => get('refresh');
  static String get add => get('add');
  static String get edit => get('edit');
  static String get delete => get('delete');
  static String get cancel => get('cancel');
  static String get save => get('save');
  static String get update => get('update');
  static String get loading => get('loading');
  static String get error => get('error');
  static String get ok => get('ok');
  static String get tryAgain => get('try_again');
  static String get noPredictionAvailable => get('no_prediction_available');
  static String get getPrediction => get('get_prediction');
  static String get in1HourAt => get('in_1_hour_at');
  static String get glucose => get('glucose');
  static String get time => get('time');
  static String get activeAlerts => get('active_alerts');
  static String get alertHistory => get('alert_history');
  static String get acknowledge => get('acknowledge');
  static String get dismiss => get('dismiss');
  static String get acknowledged => get('acknowledged');
  static String get dismissed => get('dismissed');
  static String get minutes => get('minutes');
}

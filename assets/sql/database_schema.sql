-- База даних для мобільного додатку аналізу рівня глюкози на основі машинного навчання
-- SQLite з шифруванням (SQLCipher)

-- Таблиця користувачів
CREATE TABLE users (
    user_id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL, -- зберігається bcrypt хеш
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Налаштування користувача
CREATE TABLE user_settings (
    settings_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    glucose_units TEXT NOT NULL DEFAULT 'mmol_L', -- 'mmol_L' або 'mg_dL'
    high_threshold REAL NOT NULL DEFAULT 10.0,
    low_threshold REAL NOT NULL DEFAULT 3.9,
    urgent_high_threshold REAL NOT NULL DEFAULT 13.9,
    urgent_low_threshold REAL NOT NULL DEFAULT 3.0,
    notification_settings TEXT NOT NULL, -- JSON з детальними налаштуваннями сповіщень
    theme TEXT NOT NULL DEFAULT 'system', -- 'light', 'dark', 'system'
    language TEXT NOT NULL DEFAULT 'uk', -- 'uk', 'en'
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Показники глюкози з Dexcom G6
CREATE TABLE glucose_readings (
    reading_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    value REAL NOT NULL, -- значення в mg/dL
    mmol_l REAL NOT NULL, -- значення в ммоль/л
    trend INTEGER, -- числовий код тренду згідно з Dexcom API
    trend_description TEXT, -- текстовий опис тренду
    trend_arrow TEXT, -- символ стрілки тренду
    is_valid BOOLEAN NOT NULL DEFAULT TRUE, -- чи валідні дані
    source TEXT NOT NULL DEFAULT 'CGM', -- 'CGM' або 'MANUAL'
    raw_data TEXT, -- JSON з повною відповіддю API
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE(user_id, timestamp)
);

-- Дози інсуліну (вводяться користувачем)
CREATE TABLE insulin_records (
    record_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    value REAL NOT NULL, -- кількість одиниць інсуліну
    type TEXT NOT NULL, -- 'bolus' або 'basal'
    iob_value REAL, -- розрахунковий показник активного інсуліну
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Прийоми вуглеводів (вводяться користувачем)
CREATE TABLE carb_records (
    record_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    value INTEGER NOT NULL, -- грами вуглеводів
    meal_type TEXT, -- тип прийому їжі: 'breakfast', 'lunch', 'dinner', 'snack'
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Фізична активність (вводиться користувачем або зі смарт-годинника)
CREATE TABLE activity_records (
    record_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Прогнози рівня глюкози
CREATE TABLE predictions (
    prediction_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    reading_id INTEGER NOT NULL, -- ID показника глюкози, на основі якого зроблено прогноз
    predicted_value REAL NOT NULL, -- прогнозоване значення глюкози
    prediction_horizon INTEGER NOT NULL, -- горизонт прогнозу у хвилинах (зазвичай 60)
    confidence_level REAL, -- рівень довіри до прогнозу (0-1)
    prediction_timestamp TIMESTAMP NOT NULL, -- коли було зроблено прогноз
    target_timestamp TIMESTAMP NOT NULL, -- на який момент зроблено прогноз
    actual_value REAL, -- фактичне значення (заповнюється пізніше)
    accuracy_metric REAL, -- метрика точності прогнозу
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (reading_id) REFERENCES glucose_readings(reading_id) ON DELETE CASCADE
);

-- Ознаки для ML-моделі
CREATE TABLE ml_features (
    feature_id INTEGER PRIMARY KEY AUTOINCREMENT,
    reading_id INTEGER NOT NULL,
    feature_name TEXT NOT NULL, -- назва ознаки
    value REAL NOT NULL, -- значення ознаки
    timestamp TIMESTAMP NOT NULL, -- коли була розрахована ознака
    is_valid BOOLEAN NOT NULL DEFAULT TRUE,
    calculation_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reading_id) REFERENCES glucose_readings(reading_id) ON DELETE CASCADE
);

-- Параметри ML-моделі
CREATE TABLE model_parameters (
    param_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    parameter_type TEXT NOT NULL, -- тип параметра
    parameter_name TEXT NOT NULL, -- назва параметра
    value TEXT NOT NULL, -- значення у форматі JSON
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Сповіщення
CREATE TABLE alerts (
    alert_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL, -- тип сповіщення
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reading_id INTEGER, -- пов'язане вимірювання глюкози
    value REAL, -- значення, що викликало сповіщення
    message TEXT NOT NULL, -- текст сповіщення
    severity TEXT NOT NULL, -- 'info', 'warning', 'critical'
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'acknowledged', 'dismissed'
    acknowledged_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (reading_id) REFERENCES glucose_readings(reading_id) ON DELETE SET NULL
);

-- Щоденна статистика
CREATE TABLE daily_statistics (
    stat_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    date DATE NOT NULL,
    average_glucose REAL,
    standard_deviation REAL,
    time_in_range REAL, -- відсоток часу в діапазоні
    time_above_range REAL, -- відсоток часу вище діапазону
    time_below_range REAL, -- відсоток часу нижче діапазону
    gmi REAL, -- Glucose Management Indicator
    hypo_events INTEGER, -- кількість гіпоглікемічних подій
    hyper_events INTEGER, -- кількість гіперглікемічних подій
    total_insulin REAL, -- загальна кількість інсуліну
    total_carbs INTEGER, -- загальна кількість вуглеводів
    calculated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE(user_id, date)
);

-- Аналіз патернів
CREATE TABLE pattern_analysis (
    pattern_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    pattern_type TEXT NOT NULL, -- тип паттерну
    confidence_level REAL, -- рівень достовірності (0-1)
    description TEXT NOT NULL, -- опис паттерну
    recommendations TEXT, -- рекомендації на основі паттерну
    ml_insights TEXT, -- JSON з деталями від ML
    hypo_risk_factors TEXT, -- JSON з факторами ризику гіпоглікемії
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Налаштування пристроїв
CREATE TABLE device_settings (
    setting_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    device_type TEXT NOT NULL, -- 'CGM', 'PUMP', 'SMARTWATCH'
    device_id TEXT, -- ідентифікатор пристрою
    settings TEXT, -- JSON з налаштуваннями
    last_sync TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Журнал синхронізації
CREATE TABLE sync_log (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    operation_type TEXT NOT NULL,
    records_processed INTEGER,
    status TEXT NOT NULL,
    error_details TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Журнал подій додатку
CREATE TABLE app_logs (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    level TEXT NOT NULL, -- 'debug', 'info', 'warning', 'error', 'critical'
    component TEXT NOT NULL, -- компонент додатку
    message TEXT NOT NULL,
    context TEXT, -- JSON з додатковими даними
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Експортовані звіти
CREATE TABLE exported_reports (
    report_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    report_type TEXT NOT NULL, -- тип звіту
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    format TEXT NOT NULL, -- 'PDF', 'CSV', 'EXCEL'
    file_path TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Індекси для оптимізації запитів

-- Індекси для glucose_readings
CREATE INDEX idx_glucose_user_time ON glucose_readings(user_id, timestamp);
CREATE INDEX idx_glucose_time ON glucose_readings(timestamp);
CREATE INDEX idx_glucose_value ON glucose_readings(value);

-- Індекси для insulin_records
CREATE INDEX idx_insulin_user_time ON insulin_records(user_id, timestamp);
CREATE INDEX idx_insulin_time ON insulin_records(timestamp);
CREATE INDEX idx_insulin_type ON insulin_records(type);

-- Індекси для carb_records
CREATE INDEX idx_carbs_user_time ON carb_records(user_id, timestamp);
CREATE INDEX idx_carbs_time ON carb_records(timestamp);

-- Індекси для predictions
CREATE INDEX idx_pred_user_target ON predictions(user_id, target_timestamp);
CREATE INDEX idx_pred_reading ON predictions(reading_id);
CREATE INDEX idx_pred_accuracy ON predictions(accuracy_metric);

-- Індекси для ml_features
CREATE INDEX idx_feature_reading ON ml_features(reading_id);
CREATE INDEX idx_feature_name ON ml_features(feature_name);

-- Індекси для activity_records
CREATE INDEX idx_activity_user_time ON activity_records(user_id, timestamp);
CREATE INDEX idx_activity_type ON activity_records(activity_type);

-- Індекси для daily_statistics
CREATE INDEX idx_stats_user_date ON daily_statistics(user_id, date);
CREATE INDEX idx_stats_tir ON daily_statistics(time_in_range);

-- Індекси для alerts
CREATE INDEX idx_alerts_user_status ON alerts(user_id, status);
CREATE INDEX idx_alerts_type ON alerts(type);
CREATE INDEX idx_alerts_severity ON alerts(severity);

-- Індекси для app_logs
CREATE INDEX idx_logs_level ON app_logs(level);
CREATE INDEX idx_logs_component ON app_logs(component);
CREATE INDEX idx_logs_timestamp ON app_logs(timestamp);

-- Додаткові індекси для оптимізації аналітичних запитів
CREATE INDEX idx_glucose_valid ON glucose_readings(is_valid);
CREATE INDEX idx_params_active ON model_parameters(is_active);
CREATE INDEX idx_patterns_type ON pattern_analysis(pattern_type);
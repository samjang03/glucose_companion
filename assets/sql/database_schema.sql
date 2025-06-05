CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    description TEXT
);

-- Вставляємо поточну версію
INSERT OR IGNORE INTO schema_version (version, description) 
VALUES (1, 'Initial schema with medical constraints');

-- Таблиця користувачів з покращеними constraints
CREATE TABLE IF NOT EXISTS users (
    user_id TEXT PRIMARY KEY,
    name TEXT,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT, 
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')), 
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    last_login INTEGER,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    
    -- Constraints
    CHECK (length(user_id) > 0),
    CHECK (email LIKE '%_@_%.__%'), 
    CHECK (created_at > 0),
    CHECK (updated_at >= created_at)
);

-- Тригер для автоматичного оновлення updated_at
CREATE TRIGGER IF NOT EXISTS update_users_timestamp 
AFTER UPDATE ON users
BEGIN
    UPDATE users SET updated_at = strftime('%s', 'now') WHERE user_id = NEW.user_id;
END;

-- Показники глюкози
CREATE TABLE IF NOT EXISTS glucose_readings (
    reading_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp INTEGER NOT NULL, 
    value REAL NOT NULL, -- mg/dL
    mmol_l REAL NOT NULL, -- mmol/L
    trend INTEGER, 
    trend_description TEXT,
    trend_arrow TEXT,
    is_valid INTEGER NOT NULL DEFAULT 1 CHECK (is_valid IN (0, 1)),
    source TEXT NOT NULL DEFAULT 'CGM' CHECK (source IN ('CGM', 'MANUAL', 'IMPORTED')),
    raw_data TEXT CHECK (raw_data IS NULL OR json_valid(raw_data)), 
    ml_features TEXT CHECK (ml_features IS NULL OR json_valid(ml_features)),

    CHECK (value > 0 AND value < 2000), 
    CHECK (mmol_l > 0 AND mmol_l < 55), 
    CHECK (trend >= 0 AND trend <= 9),
    CHECK (timestamp > 0),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE(user_id, timestamp)
);

-- Дози інсуліну з медичними обмеженнями
CREATE TABLE IF NOT EXISTS insulin_records (
    record_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    value REAL NOT NULL, -- одиниці інсуліну
    type TEXT NOT NULL CHECK (type IN ('bolus', 'basal', 'correction', 'extended')),
    iob_value REAL, -- активний інсулін
    duration_minutes INTEGER, -- для extended bolus
    notes TEXT,
    
    -- Медичні обмеження
    CHECK (value > 0 AND value <= 100), 
    CHECK (iob_value IS NULL OR (iob_value >= 0 AND iob_value <= 50)),
    CHECK (duration_minutes IS NULL OR duration_minutes > 0),
    CHECK (timestamp > 0),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Вуглеводи 
CREATE TABLE IF NOT EXISTS carb_records (
    record_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    value REAL NOT NULL, 
    meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'other')),
    absorption_time INTEGER, 
    notes TEXT,
    
    -- Медичні обмеження
    CHECK (value > 0 AND value <= 500), -- Максимум 500г вуглеводів за раз
    CHECK (absorption_time IS NULL OR (absorption_time > 0 AND absorption_time <= 480)), -- До 8 годин
    CHECK (timestamp > 0),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Фізична активність
CREATE TABLE IF NOT EXISTS activity_records (
    record_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    activity_type TEXT NOT NULL,
    duration_minutes INTEGER, -- тривалість активності
    intensity TEXT CHECK (intensity IN ('low', 'moderate', 'high', 'very_high')),
    notes TEXT,
    
    CHECK (length(activity_type) > 0),
    CHECK (duration_minutes IS NULL OR duration_minutes > 0),
    CHECK (timestamp > 0),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Прогнози з ML-метриками
CREATE TABLE IF NOT EXISTS predictions (
    prediction_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    reading_id INTEGER NOT NULL,
    predicted_value REAL NOT NULL,
    prediction_horizon INTEGER NOT NULL DEFAULT 60, 
    prediction_timestamp INTEGER NOT NULL,
    target_timestamp INTEGER NOT NULL,
    actual_value REAL, 
    accuracy_metric REAL, 
    model_version TEXT NOT NULL DEFAULT '1.0',
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (reading_id) REFERENCES glucose_readings(reading_id) ON DELETE CASCADE
);

-- Сповіщення з категоризацією
CREATE TABLE IF NOT EXISTS alerts (
    alert_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'urgent_low', 'low', 'high', 'urgent_high', 
        'rapid_fall', 'rapid_rise', 'prediction_low', 'prediction_high',
        'data_gap', 'sensor_error', 'calibration_needed'
    )),
    timestamp INTEGER NOT NULL,
    reading_id INTEGER,
    value REAL,
    message TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical', 'urgent')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'acknowledged', 'dismissed', 'expired')),
    acknowledged_at INTEGER,
    expires_at INTEGER, 
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (reading_id) REFERENCES glucose_readings(reading_id) ON DELETE SET NULL
);

-- Щоденна статистика з повними метриками
CREATE TABLE IF NOT EXISTS daily_statistics (
    stat_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    date TEXT NOT NULL, -- YYYY-MM-DD format
    readings_count INTEGER NOT NULL DEFAULT 0,
    average_glucose REAL,
    median_glucose REAL,
    standard_deviation REAL,
    coefficient_of_variation REAL, -- CV%
    time_in_range REAL, -- TIR %
    time_above_range REAL, -- TAR %
    time_below_range REAL, -- TBR %
    time_very_high REAL, -- >13.9 mmol/L
    time_very_low REAL, -- <3.0 mmol/L
    gmi REAL, -- Glucose Management Indicator
    hypo_events INTEGER DEFAULT 0,
    hyper_events INTEGER DEFAULT 0,
    total_insulin REAL DEFAULT 0,
    total_carbs REAL DEFAULT 0,
    calculated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE(user_id, date)
);

-- Аналіз патернів глікемії
CREATE TABLE IF NOT EXISTS pattern_analysis (
    pattern_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    start_date TEXT NOT NULL, -- YYYY-MM-DD
    end_date TEXT NOT NULL, -- YYYY-MM-DD
    pattern_type TEXT NOT NULL CHECK (pattern_type IN (
        'dawn_phenomenon', 'nighttime_lows', 'postprandial_spikes',
        'exercise_induced_lows', 'stress_hyperglycemia', 'weekly_pattern'
    )),
    description TEXT NOT NULL,
    recommendations TEXT,
    statistical_significance REAL, -- p-value
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Налаштування користувача
CREATE TABLE IF NOT EXISTS user_settings (
    settings_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    glucose_units TEXT NOT NULL DEFAULT 'mmol_L' CHECK (glucose_units IN ('mmol_L', 'mg_dL')),
    low_threshold REAL NOT NULL DEFAULT 3.9,
    high_threshold REAL NOT NULL DEFAULT 10.0,
    urgent_low_threshold REAL NOT NULL DEFAULT 3.0,
    urgent_high_threshold REAL NOT NULL DEFAULT 13.9,
    notification_settings TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(notification_settings)),
    theme TEXT NOT NULL DEFAULT 'system' CHECK (theme IN ('light', 'dark', 'system')),
    language TEXT NOT NULL DEFAULT 'uk' CHECK (language IN ('uk', 'en')),
    last_updated INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_glucose_user_time ON glucose_readings(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_glucose_time_value ON glucose_readings(timestamp, value) WHERE is_valid = 1;
CREATE INDEX IF NOT EXISTS idx_glucose_trend ON glucose_readings(trend) WHERE trend IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_glucose_source ON glucose_readings(source, timestamp);

CREATE INDEX IF NOT EXISTS idx_insulin_user_time ON insulin_records(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_insulin_type_time ON insulin_records(type, timestamp);
CREATE INDEX IF NOT EXISTS idx_insulin_active ON insulin_records(timestamp) WHERE iob_value > 0;

CREATE INDEX IF NOT EXISTS idx_carbs_user_time ON carb_records(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_carbs_meal_time ON carb_records(meal_type, timestamp);

CREATE INDEX IF NOT EXISTS idx_activity_user_time ON activity_records(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_activity_type ON activity_records(activity_type, timestamp);

CREATE INDEX IF NOT EXISTS idx_predictions_user_target ON predictions(user_id, target_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_predictions_accuracy ON predictions(accuracy_metric) WHERE accuracy_metric IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_predictions_confidence ON predictions(confidence_level DESC);

CREATE INDEX IF NOT EXISTS idx_alerts_user_status ON alerts(user_id, status, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_severity_time ON alerts(severity, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_type ON alerts(type, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_active ON alerts(timestamp) WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_daily_stats_user_date ON daily_statistics(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_stats_tir ON daily_statistics(time_in_range DESC);
CREATE INDEX IF NOT EXISTS idx_daily_stats_quality ON daily_statistics(gmi, coefficient_of_variation);

CREATE INDEX IF NOT EXISTS idx_patterns_user_type ON pattern_analysis(user_id, pattern_type);
CREATE INDEX IF NOT EXISTS idx_patterns_confidence ON pattern_analysis(confidence_level DESC);
CREATE INDEX IF NOT EXISTS idx_patterns_date_range ON pattern_analysis(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_user_settings_user ON user_settings(user_id);

-- Створення представлень (Views) для складних запитів
CREATE VIEW IF NOT EXISTS glucose_with_trends AS
SELECT 
    gr.*,
    LAG(gr.mmol_l, 1) OVER (PARTITION BY gr.user_id ORDER BY gr.timestamp) as prev_value,
    LEAD(gr.mmol_l, 1) OVER (PARTITION BY gr.user_id ORDER BY gr.timestamp) as next_value,
    (gr.mmol_l - LAG(gr.mmol_l, 1) OVER (PARTITION BY gr.user_id ORDER BY gr.timestamp)) as glucose_delta
FROM glucose_readings gr
WHERE gr.is_valid = 1;

-- Представлення для актуальних сповіщень
CREATE VIEW IF NOT EXISTS active_alerts AS
SELECT *
FROM alerts
WHERE status = 'pending' 
  AND (expires_at IS NULL OR expires_at > strftime('%s', 'now'))
ORDER BY severity DESC, timestamp DESC;

-- Представлення для щоденної статистики з рейтингом
CREATE VIEW IF NOT EXISTS daily_stats_ranked AS
SELECT 
    ds.*,
    RANK() OVER (PARTITION BY ds.user_id ORDER BY ds.time_in_range DESC) as tir_rank,
    RANK() OVER (PARTITION BY ds.user_id ORDER BY ds.coefficient_of_variation ASC) as stability_rank
FROM daily_statistics ds
WHERE ds.readings_count >= 144; -- Мінімум 12 годин даних

-- Тригери для автоматичного обчислення статистики
CREATE TRIGGER IF NOT EXISTS update_daily_stats_on_glucose_insert
AFTER INSERT ON glucose_readings
WHEN NEW.is_valid = 1
BEGIN
    INSERT OR REPLACE INTO daily_statistics (
        user_id, date, readings_count, average_glucose, calculated_at
    )
    SELECT 
        NEW.user_id,
        date(NEW.timestamp, 'unixepoch', 'localtime'),
        COUNT(*),
        AVG(mmol_l),
        strftime('%s', 'now')
    FROM glucose_readings 
    WHERE user_id = NEW.user_id 
      AND date(timestamp, 'unixepoch', 'localtime') = date(NEW.timestamp, 'unixepoch', 'localtime')
      AND is_valid = 1;
END;
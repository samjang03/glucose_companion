-- Таблиця користувачів
CREATE TABLE IF NOT EXISTS users (
    user_id TEXT PRIMARY KEY,
    name TEXT,
    email TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Таблиця показників глюкози
CREATE TABLE IF NOT EXISTS glucose_readings (
    reading_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    value REAL NOT NULL,
    mmol_l REAL NOT NULL,
    trend INTEGER,
    trend_description TEXT,
    trend_arrow TEXT,
    is_valid INTEGER DEFAULT 1,
    source TEXT DEFAULT 'CGM',
    raw_data TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE (user_id, timestamp)
);

-- Таблиця записів інсуліну
CREATE TABLE IF NOT EXISTS insulin_records (
    record_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    value REAL NOT NULL,
    type TEXT NOT NULL,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Таблиця записів вуглеводів
CREATE TABLE IF NOT EXISTS carb_records (
    record_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    value REAL NOT NULL,
    meal_type TEXT,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Таблиця записів активності
CREATE TABLE IF NOT EXISTS activity_records (
    record_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Таблиця сповіщень
CREATE TABLE IF NOT EXISTS alerts (
    alert_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    reading_id INTEGER,
    value REAL,
    message TEXT NOT NULL,
    severity TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    acknowledged_at TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Індекси для оптимізації
CREATE INDEX IF NOT EXISTS idx_glucose_user_time ON glucose_readings(user_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_insulin_user_time ON insulin_records(user_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_carbs_user_time ON carb_records(user_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_activity_user_time ON activity_records(user_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_alerts_user_status ON alerts(user_id, status);
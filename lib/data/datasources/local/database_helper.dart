// lib/data/datasources/local/database_helper.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart'; // ДОДАНО: імпорт для Database та openDatabase
import 'package:flutter/services.dart';
import 'package:glucose_companion/core/security/secure_storage.dart';
import 'package:glucose_companion/core/di/injection_container.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  // Використовуємо інжектований SecureStorage
  final _secureStorage = sl<SecureStorage>();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'glucose_companion.db');

    print('Opening database at: $path');

    // Отримання ключа шифрування
    String? encryptionKey = await _secureStorage.read(key: 'db_encryption_key');
    if (encryptionKey == null) {
      // Створення нового ключа шифрування
      final random = Random.secure();
      final List<int> keyBytes = List<int>.generate(
        32,
        (_) => random.nextInt(256),
      );
      encryptionKey = base64Encode(keyBytes);
      await _secureStorage.write(
        key: 'db_encryption_key',
        value: encryptionKey,
      );
    }

    // Відкриття зашифрованої бази даних
    return await openDatabase(
      path,
      version: 3, // Збільшили версію для гарантованого оновлення
      password: encryptionKey,
      onCreate: (db, version) async {
        print('Creating database with version $version');
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('Upgrading database from version $oldVersion to $newVersion');
        // Для простоти просто пересоздаємо всі таблиці
        await _dropAllTables(db);
        await _createTables(db);
      },
      onOpen: (db) async {
        print('Database opened successfully');
        // Перевіряємо наявність всіх таблиць
        await _verifyTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    try {
      print('Creating database tables...');

      // Таблиця користувачів
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          user_id TEXT PRIMARY KEY,
          name TEXT,
          email TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      print('✓ Users table created');

      // Таблиця показників глюкози
      await db.execute('''
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
        )
      ''');
      print('✓ Glucose readings table created');

      // Таблиця записів про інсулін
      await db.execute('''
        CREATE TABLE IF NOT EXISTS insulin_records (
          record_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          value REAL NOT NULL,
          type TEXT NOT NULL,
          notes TEXT,
          FOREIGN KEY (user_id) REFERENCES users(user_id)
        )
      ''');
      print('✓ Insulin records table created');

      // Таблиця записів про вуглеводи
      await db.execute('''
        CREATE TABLE IF NOT EXISTS carb_records (
          record_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          value REAL NOT NULL,
          meal_type TEXT,
          notes TEXT,
          FOREIGN KEY (user_id) REFERENCES users(user_id)
        )
      ''');
      print('✓ Carb records table created');

      // Таблиця записів про активність
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activity_records (
          record_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          activity_type TEXT NOT NULL,
          notes TEXT,
          FOREIGN KEY (user_id) REFERENCES users(user_id)
        )
      ''');
      print('✓ Activity records table created');

      // Створюємо індекси для оптимізації
      await _createIndexes(db);

      print('All tables created successfully');
    } catch (e) {
      print('Error creating database tables: $e');
      rethrow;
    }
  }

  Future<void> _createIndexes(Database db) async {
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_glucose_user_time ON glucose_readings(user_id, timestamp)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_insulin_user_time ON insulin_records(user_id, timestamp)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_carbs_user_time ON carb_records(user_id, timestamp)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_activity_user_time ON activity_records(user_id, timestamp)',
      );
      print('✓ Indexes created successfully');
    } catch (e) {
      print('Error creating indexes: $e');
      // Не кидаємо помилку, індекси не критичні
    }
  }

  Future<void> _dropAllTables(Database db) async {
    try {
      await db.execute('DROP TABLE IF EXISTS activity_records');
      await db.execute('DROP TABLE IF EXISTS carb_records');
      await db.execute('DROP TABLE IF EXISTS insulin_records');
      await db.execute('DROP TABLE IF EXISTS glucose_readings');
      // Не видаляємо users, щоб зберегти користувачів
      print('Tables dropped successfully');
    } catch (e) {
      print('Error dropping tables: $e');
    }
  }

  Future<void> _verifyTables(Database db) async {
    try {
      final List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      final tableNames =
          tables.map((table) => table['name'] as String).toList();
      print('Available tables: $tableNames');

      // Перевіряємо наявність всіх потрібних таблиць
      final requiredTables = [
        'users',
        'glucose_readings',
        'insulin_records',
        'carb_records',
        'activity_records',
      ];
      for (final tableName in requiredTables) {
        if (!tableNames.contains(tableName)) {
          print('WARNING: Table $tableName is missing!');
        } else {
          print('✓ Table $tableName exists');
        }
      }
    } catch (e) {
      print('Error verifying tables: $e');
    }
  }

  // Метод для повного перестворення бази даних
  Future<void> resetDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'glucose_companion.db');

      // Видаляємо існуючу базу
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print('Database file deleted');
      }

      // Пересоздаємо базу
      _database = await _initDatabase();
      print('Database reset completed');
    } catch (e) {
      print('Error resetting database: $e');
    }
  }

  // Метод для перевірки існування таблиць
  Future<List<String>> getTableNames() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      return tables.map((table) => table['name'] as String).toList();
    } catch (e) {
      print('Error getting table names: $e');
      return [];
    }
  }

  // Метод для тестування з'єднання з базою
  Future<bool> testConnection() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }

  // Метод для закриття бази даних
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('Database closed');
    }
  }
}

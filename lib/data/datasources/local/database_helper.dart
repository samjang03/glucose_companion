import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:glucose_companion/core/security/secure_storage.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  final _secureStorage = SecureStorage();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'glucose_companion.db');

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

    // Завантаження SQL-скрипта з assets
    String createScript = await rootBundle.loadString(
      'assets/sql/database_schema.sql',
    );

    // Відкриття зашифрованої бази даних
    return await openDatabase(
      path,
      version: 1,
      password: encryptionKey,
      onCreate: (db, version) async {
        // Розділяємо скрипт на окремі команди
        List<String> commands =
            createScript
                .split(';')
                .map((c) => c.trim())
                .where((c) => c.isNotEmpty)
                .toList();

        // Виконуємо кожну команду окремо
        for (var command in commands) {
          await db.execute('$command;');
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Тут буде код для міграції бази даних при оновленні
      },
    );
  }

  // Метод для закриття бази даних
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

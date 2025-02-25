import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:glucose_companion/data/datasources/local/database_helper.dart';
import 'package:glucose_companion/data/models/glucose_reading_db.dart';
import 'package:glucose_companion/domain/repositories/glucose_reading_repository.dart';

class GlucoseReadingRepositoryImpl implements GlucoseReadingRepository {
  final DatabaseHelper _databaseHelper;

  GlucoseReadingRepositoryImpl(this._databaseHelper);

  @override
  Future<int> insert(GlucoseReadingDb reading) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'glucose_readings',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> update(GlucoseReadingDb reading) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'glucose_readings',
      reading.toMap(),
      where: 'reading_id = ?',
      whereArgs: [reading.readingId],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'glucose_readings',
      where: 'reading_id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<GlucoseReadingDb?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'glucose_readings',
      where: 'reading_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return GlucoseReadingDb.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<GlucoseReadingDb>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('glucose_readings');
    return List.generate(maps.length, (i) {
      return GlucoseReadingDb.fromMap(maps[i]);
    });
  }

  @override
  Future<List<GlucoseReadingDb>> getByTimeRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'glucose_readings',
      where: 'user_id = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return GlucoseReadingDb.fromMap(maps[i]);
    });
  }

  @override
  Future<List<GlucoseReadingDb>> getLatestReadings(
    String userId,
    int limit,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'glucose_readings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return GlucoseReadingDb.fromMap(maps[i]);
    }).reversed.toList(); // Повертаємо у хронологічному порядку
  }

  @override
  Future<GlucoseReadingDb?> getLatestReading(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'glucose_readings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return GlucoseReadingDb.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> insertBatch(List<GlucoseReadingDb> readings) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      for (var reading in readings) {
        await txn.insert(
          'glucose_readings',
          reading.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:glucose_companion/data/datasources/local/database_helper.dart';
import 'package:glucose_companion/data/models/activity_record.dart';
import 'package:glucose_companion/domain/repositories/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final DatabaseHelper _databaseHelper;

  ActivityRepositoryImpl(this._databaseHelper);

  @override
  Future<int> insert(ActivityRecord record) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'activity_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> update(ActivityRecord record) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'activity_records',
      record.toMap(),
      where: 'record_id = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'activity_records',
      where: 'record_id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<ActivityRecord?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activity_records',
      where: 'record_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ActivityRecord.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<ActivityRecord>> getAll(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activity_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return ActivityRecord.fromMap(maps[i]);
    });
  }

  @override
  Future<List<ActivityRecord>> getByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activity_records',
      where: 'user_id = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return ActivityRecord.fromMap(maps[i]);
    });
  }

  @override
  Future<ActivityRecord?> getLastRecord(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activity_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ActivityRecord.fromMap(maps.first);
    }
    return null;
  }
}

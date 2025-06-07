import 'package:sqflite/sqflite.dart';
import 'package:glucose_companion/data/datasources/local/database_helper.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/domain/repositories/carb_repository.dart';

class CarbRepositoryImpl implements CarbRepository {
  final DatabaseHelper _databaseHelper;

  CarbRepositoryImpl(this._databaseHelper);

  @override
  Future<int> insert(CarbRecord record) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'carb_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> update(CarbRecord record) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'carb_records',
      record.toMap(),
      where: 'record_id = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'carb_records',
      where: 'record_id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<CarbRecord?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'carb_records',
      where: 'record_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return CarbRecord.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<CarbRecord>> getAll(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'carb_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return CarbRecord.fromMap(maps[i]);
    });
  }

  @override
  Future<List<CarbRecord>> getByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'carb_records',
      where: 'user_id = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return CarbRecord.fromMap(maps[i]);
    });
  }

  @override
  Future<CarbRecord?> getLastRecord(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'carb_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CarbRecord.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<double> getTotalCarbsForDay(String userId, DateTime date) async {
    final db = await _databaseHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(value) as total FROM carb_records WHERE user_id = ? AND timestamp BETWEEN ? AND ?',
      [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    if (result.isNotEmpty && result[0]['total'] != null) {
      return result[0]['total'];
    }
    return 0.0;
  }
}

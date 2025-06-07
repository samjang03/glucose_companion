// lib/data/repositories/alert_repository_impl.dart
import 'package:sqflite/sqflite.dart';
import 'package:glucose_companion/data/datasources/local/database_helper.dart';
import 'package:glucose_companion/data/models/alert.dart';
import 'package:glucose_companion/domain/repositories/alert_repository.dart';

class AlertRepositoryImpl implements AlertRepository {
  final DatabaseHelper _databaseHelper;

  AlertRepositoryImpl(this._databaseHelper);

  @override
  Future<int> insert(Alert alert) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'alerts',
      alert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> update(Alert alert) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'alerts',
      alert.toMap(),
      where: 'alert_id = ?',
      whereArgs: [alert.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete('alerts', where: 'alert_id = ?', whereArgs: [id]);
  }

  @override
  Future<Alert?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: 'alert_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Alert.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<Alert>> getAll(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return Alert.fromMap(maps[i]);
    });
  }

  @override
  Future<List<Alert>> getActive(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'pending'],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return Alert.fromMap(maps[i]);
    });
  }

  @override
  Future<List<Alert>> getByStatus(String userId, String status) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, status],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return Alert.fromMap(maps[i]);
    });
  }

  @override
  Future<int> acknowledge(int id) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'alerts',
      {
        'status': 'acknowledged',
        'acknowledged_at': DateTime.now().toIso8601String(),
      },
      where: 'alert_id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> dismiss(int id) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'alerts',
      {
        'status': 'dismissed',
        'acknowledged_at': DateTime.now().toIso8601String(),
      },
      where: 'alert_id = ?',
      whereArgs: [id],
    );
  }
}

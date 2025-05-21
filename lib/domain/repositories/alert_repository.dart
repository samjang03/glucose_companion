// lib/domain/repositories/alert_repository.dart
import 'package:glucose_companion/data/models/alert.dart';

abstract class AlertRepository {
  Future<int> insert(Alert alert);
  Future<int> update(Alert alert);
  Future<int> delete(int id);
  Future<Alert?> getById(int id);
  Future<List<Alert>> getAll(String userId);
  Future<List<Alert>> getActive(String userId);
  Future<List<Alert>> getByStatus(String userId, String status);
  Future<int> acknowledge(int id);
  Future<int> dismiss(int id);
}

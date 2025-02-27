import 'package:equatable/equatable.dart';

class InsulinRecord extends Equatable {
  final int? id;
  final String userId;
  final DateTime timestamp;
  final double units;
  final String type; // 'bolus' або 'basal'
  final String? notes;

  const InsulinRecord({
    this.id,
    required this.userId,
    required this.timestamp,
    required this.units,
    required this.type,
    this.notes,
  });

  factory InsulinRecord.fromMap(Map<String, dynamic> map) {
    return InsulinRecord(
      id: map['record_id'],
      userId: map['user_id'],
      timestamp: DateTime.parse(map['timestamp']),
      units: map['value'],
      type: map['type'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'record_id': id,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'value': units,
      'type': type,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, userId, timestamp, units, type, notes];

  InsulinRecord copyWith({
    int? id,
    String? userId,
    DateTime? timestamp,
    double? units,
    String? type,
    String? notes,
  }) {
    return InsulinRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      units: units ?? this.units,
      type: type ?? this.type,
      notes: notes ?? this.notes,
    );
  }
}

import 'package:equatable/equatable.dart';

class CarbRecord extends Equatable {
  final int? id;
  final String userId;
  final DateTime timestamp;
  final double grams;
  final String? mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final String? notes;

  const CarbRecord({
    this.id,
    required this.userId,
    required this.timestamp,
    required this.grams,
    this.mealType,
    this.notes,
  });

  factory CarbRecord.fromMap(Map<String, dynamic> map) {
    return CarbRecord(
      id: map['record_id'],
      userId: map['user_id'],
      timestamp: DateTime.parse(map['timestamp']),
      grams: map['value'].toDouble(),
      mealType: map['meal_type'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'record_id': id,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'value': grams,
      'meal_type': mealType,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, userId, timestamp, grams, mealType, notes];

  CarbRecord copyWith({
    int? id,
    String? userId,
    DateTime? timestamp,
    double? grams,
    String? mealType,
    String? notes,
  }) {
    return CarbRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      grams: grams ?? this.grams,
      mealType: mealType ?? this.mealType,
      notes: notes ?? this.notes,
    );
  }
}

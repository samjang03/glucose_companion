import 'package:equatable/equatable.dart';

class ActivityRecord extends Equatable {
  final int? id;
  final String userId;
  final DateTime timestamp;
  final String activityType;
  final String? notes;

  const ActivityRecord({
    this.id,
    required this.userId,
    required this.timestamp,
    required this.activityType,
    this.notes,
  });

  factory ActivityRecord.fromMap(Map<String, dynamic> map) {
    return ActivityRecord(
      id: map['record_id'],
      userId: map['user_id'],
      timestamp: DateTime.parse(map['timestamp']),
      activityType: map['activity_type'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'record_id': id,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'activity_type': activityType,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, userId, timestamp, activityType, notes];

  ActivityRecord copyWith({
    int? id,
    String? userId,
    DateTime? timestamp,
    String? activityType,
    String? notes,
  }) {
    return ActivityRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      activityType: activityType ?? this.activityType,
      notes: notes ?? this.notes,
    );
  }
}

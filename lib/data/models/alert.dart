// lib/data/models/alert.dart
import 'package:equatable/equatable.dart';

class Alert extends Equatable {
  final int? id;
  final String userId;
  final String type; // 'high', 'low', 'urgent_high', 'urgent_low', 'prediction'
  final DateTime timestamp;
  final int? readingId;
  final double? value;
  final String message;
  final String severity; // 'info', 'warning', 'critical'
  final String status; // 'pending', 'acknowledged', 'dismissed'
  final DateTime? acknowledgedAt;

  const Alert({
    this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    this.readingId,
    this.value,
    required this.message,
    required this.severity,
    required this.status,
    this.acknowledgedAt,
  });

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['alert_id'],
      userId: map['user_id'],
      type: map['type'],
      timestamp: DateTime.parse(map['timestamp']),
      readingId: map['reading_id'],
      value: map['value'],
      message: map['message'],
      severity: map['severity'],
      status: map['status'],
      acknowledgedAt:
          map['acknowledged_at'] != null
              ? DateTime.parse(map['acknowledged_at'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'alert_id': id,
      'user_id': userId,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'reading_id': readingId,
      'value': value,
      'message': message,
      'severity': severity,
      'status': status,
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    timestamp,
    readingId,
    value,
    message,
    severity,
    status,
    acknowledgedAt,
  ];

  Alert copyWith({
    int? id,
    String? userId,
    String? type,
    DateTime? timestamp,
    int? readingId,
    double? value,
    String? message,
    String? severity,
    String? status,
    DateTime? acknowledgedAt,
  }) {
    return Alert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      readingId: readingId ?? this.readingId,
      value: value ?? this.value,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }

  bool get isActive => status == 'pending';
}

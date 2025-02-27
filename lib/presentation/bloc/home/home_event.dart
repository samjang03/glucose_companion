import 'package:equatable/equatable.dart';
import 'package:glucose_companion/data/models/activity_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class LoadCurrentGlucoseEvent extends HomeEvent {}

class LoadGlucoseHistoryEvent extends HomeEvent {
  final int hours;

  const LoadGlucoseHistoryEvent({this.hours = 3});

  @override
  List<Object> get props => [hours];
}

class RefreshGlucoseDataEvent extends HomeEvent {}

class SetUserIdEvent extends HomeEvent {
  final String userId;

  const SetUserIdEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class RecordInsulinEvent extends HomeEvent {
  final double units;
  final String insulinType;
  final String? notes;

  const RecordInsulinEvent({
    required this.units,
    required this.insulinType,
    this.notes,
  });

  @override
  List<Object> get props => [units, insulinType, notes ?? ''];
}

class RecordCarbsEvent extends HomeEvent {
  final double grams;
  final String? foodType;
  final String? notes;

  const RecordCarbsEvent({required this.grams, this.foodType, this.notes});

  @override
  List<Object> get props => [grams, foodType ?? '', notes ?? ''];
}

class LoadDailyRecordsEvent extends HomeEvent {
  final DateTime date;

  const LoadDailyRecordsEvent(this.date);

  @override
  List<Object> get props => [date];
}

class RecordActivityEvent extends HomeEvent {
  final String activityType;
  final String? notes;

  const RecordActivityEvent({required this.activityType, this.notes});

  @override
  List<Object> get props => [activityType, notes ?? ''];
}

class UpdateInsulinRecordEvent extends HomeEvent {
  final InsulinRecord record;

  const UpdateInsulinRecordEvent(this.record);

  @override
  List<Object> get props => [record];
}

class UpdateCarbRecordEvent extends HomeEvent {
  final CarbRecord record;

  const UpdateCarbRecordEvent(this.record);

  @override
  List<Object> get props => [record];
}

class UpdateActivityRecordEvent extends HomeEvent {
  final ActivityRecord record;

  const UpdateActivityRecordEvent(this.record);

  @override
  List<Object> get props => [record];
}

class DeleteRecordEvent extends HomeEvent {
  final String recordType; // 'insulin', 'carbs', або 'activity'
  final int recordId;

  const DeleteRecordEvent(this.recordType, this.recordId);

  @override
  List<Object> get props => [recordType, recordId];
}

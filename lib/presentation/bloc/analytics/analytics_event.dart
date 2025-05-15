// lib/presentation/bloc/analytics/analytics_event.dart
import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object> get props => [];
}

class LoadAnalyticsEvent extends AnalyticsEvent {
  final int days;

  const LoadAnalyticsEvent({this.days = 7});

  @override
  List<Object> get props => [days];
}

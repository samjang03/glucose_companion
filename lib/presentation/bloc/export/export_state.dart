import 'package:equatable/equatable.dart';
import '../../../services/export/export_service.dart';

abstract class ExportState extends Equatable {
  const ExportState();

  @override
  List<Object?> get props => [];
}

class ExportInitial extends ExportState {}

class ExportInProgress extends ExportState {
  final double progress;

  const ExportInProgress({required this.progress});

  @override
  List<Object?> get props => [progress];
}

class ExportSuccess extends ExportState {
  final ExportResult result;

  const ExportSuccess({required this.result});

  @override
  List<Object?> get props => [result];
}

class ExportFailure extends ExportState {
  final String error;

  const ExportFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

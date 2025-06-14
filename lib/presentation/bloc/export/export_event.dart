import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../services/export/export_service.dart';

abstract class ExportEvent extends Equatable {
  const ExportEvent();

  @override
  List<Object?> get props => [];
}

class StartExportEvent extends ExportEvent {
  final DateTime startDate;
  final DateTime endDate;
  final ExportFormat format;
  final String userId;
  final String userName;

  const StartExportEvent({
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.userId,
    required this.userName,
  });

  @override
  List<Object?> get props => [startDate, endDate, format, userId, userName];
}

class ShareFileEvent extends ExportEvent {
  final File file;

  const ShareFileEvent(this.file);

  @override
  List<Object?> get props => [file];
}

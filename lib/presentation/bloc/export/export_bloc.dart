import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/export/export_service.dart';
import 'export_event.dart';
import 'export_state.dart';

class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final ExportService _exportService;

  ExportBloc(this._exportService) : super(ExportInitial()) {
    on<StartExportEvent>(_onStartExport);
    on<ShareFileEvent>(_onShareFile);
  }

  Future<void> _onStartExport(
    StartExportEvent event,
    Emitter<ExportState> emit,
  ) async {
    emit(ExportInProgress(progress: 0.0));

    try {
      final result = await _exportService.exportGlucoseReport(
        startDate: event.startDate,
        endDate: event.endDate,
        userId: event.userId,
        userName: event.userName,
        format: event.format,
        onProgress: (progress) {
          emit(ExportInProgress(progress: progress));
        },
      );

      if (result.isSuccess) {
        emit(ExportSuccess(result: result));
      } else {
        emit(ExportFailure(error: result.message));
      }
    } catch (e) {
      emit(ExportFailure(error: e.toString()));
    }
  }

  Future<void> _onShareFile(
    ShareFileEvent event,
    Emitter<ExportState> emit,
  ) async {
    try {
      await _exportService.shareFile(event.file);
    } catch (e) {
      emit(ExportFailure(error: 'Failed to share file: ${e.toString()}'));
    }
  }
}

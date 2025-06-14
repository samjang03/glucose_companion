// lib/services/export/export_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_generator_service.dart';

class ExportService {
  final GlucoseReportPDFGenerator _pdfGenerator = GlucoseReportPDFGenerator();

  Future<ExportResult> exportGlucoseReport({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
    required String userName,
    required ExportFormat format,
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);

      switch (format) {
        case ExportFormat.pdf:
          return await _exportPDF(
            startDate,
            endDate,
            userId,
            userName,
            onProgress,
          );
        case ExportFormat.csv:
          return await _exportCSV(startDate, endDate, userId, onProgress);
        case ExportFormat.excel:
          return await _exportExcel(startDate, endDate, userId, onProgress);
        default:
          throw UnsupportedError('Export format not supported');
      }
    } catch (e) {
      return ExportResult.failure('Failed to export data: ${e.toString()}');
    }
  }

  Future<ExportResult> _exportPDF(
    DateTime startDate,
    DateTime endDate,
    String userId,
    String userName,
    Function(double)? onProgress,
  ) async {
    try {
      onProgress?.call(0.2);

      final file = await _pdfGenerator.generateReport(
        startDate: startDate,
        endDate: endDate,
        userId: userId,
        userName: userName,
      );

      onProgress?.call(1.0);

      return ExportResult.success(
        file: file,
        message: 'PDF report generated successfully',
      );
    } catch (e) {
      return ExportResult.failure('Failed to generate PDF: ${e.toString()}');
    }
  }

  Future<ExportResult> _exportCSV(
    DateTime startDate,
    DateTime endDate,
    String userId,
    Function(double)? onProgress,
  ) async {
    try {
      onProgress?.call(0.3);

      // This would integrate with your actual data repositories
      // For now, we'll create a simple CSV structure
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/glucose_data_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      final csvContent = StringBuffer();
      csvContent.writeln(
        'timestamp,glucose_mmol_l,glucose_mg_dl,trend,trend_direction',
      );

      // Add sample CSV data here
      csvContent.writeln('2025-05-01 08:00:00,7.2,130,4,Flat');
      csvContent.writeln('2025-05-01 08:05:00,7.4,133,3,Rising slightly');

      onProgress?.call(0.8);

      await file.writeAsString(csvContent.toString());

      onProgress?.call(1.0);

      return ExportResult.success(
        file: file,
        message: 'CSV data exported successfully',
      );
    } catch (e) {
      return ExportResult.failure('Failed to export CSV: ${e.toString()}');
    }
  }

  Future<ExportResult> _exportExcel(
    DateTime startDate,
    DateTime endDate,
    String userId,
    Function(double)? onProgress,
  ) async {
    try {
      // For Excel export, you would use a package like excel
      // This is a placeholder implementation
      onProgress?.call(0.5);

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/glucose_data_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );

      // Placeholder: create empty file
      await file.writeAsBytes([]);

      onProgress?.call(1.0);

      return ExportResult.success(
        file: file,
        message: 'Excel file exported successfully',
      );
    } catch (e) {
      return ExportResult.failure('Failed to export Excel: ${e.toString()}');
    }
  }

  Future<void> shareFile(File file) async {
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Glucose monitoring report');
  }

  Future<void> saveToDocuments(File file) async {
    // Additional implementation for saving to device documents
    // This might involve platform-specific code
  }
}

enum ExportFormat { pdf, csv, excel }

class ExportResult {
  final bool isSuccess;
  final File? file;
  final String message;

  ExportResult._({required this.isSuccess, this.file, required this.message});

  factory ExportResult.success({required File file, required String message}) {
    return ExportResult._(isSuccess: true, file: file, message: message);
  }

  factory ExportResult.failure(String message) {
    return ExportResult._(isSuccess: false, message: message);
  }
}

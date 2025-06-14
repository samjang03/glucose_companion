// lib/services/export/pdf_generator_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'report_data_processor.dart';
import 'agp_calculator.dart';
import 'pattern_analyzer.dart';
import 'dart:math' as math;
import '../../data/models/glucose_reading.dart';
import '../../data/models/insulin_record.dart';
import '../../data/models/carb_record.dart';
import '../../data/models/activity_record.dart';

class GlucoseReportPDFGenerator {
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF4A5CFF);
  static const PdfColor secondaryPurple = PdfColor.fromInt(0xFF7B61FF);
  static const PdfColor accentPink = PdfColor.fromInt(0xFFFF61DC);
  static const PdfColor targetGreen = PdfColor.fromInt(0xFF28A745);
  static const PdfColor warningYellow = PdfColor.fromInt(0xFFFFC107);
  static const PdfColor dangerRed = PdfColor.fromInt(0xFFDC3545);
  static const PdfColor lightGray = PdfColor.fromInt(0xFFF8F9FA);
  static const PdfColor darkText = PdfColor.fromInt(0xFF212529);

  final ReportDataProcessor _dataProcessor = ReportDataProcessor();

  Future<File> generateReport({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
    required String userName,
  }) async {
    // Process data for the period
    final reportData = await _dataProcessor.processDataForPeriod(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );

    // Calculate AGP data
    final agpData = AGPCalculator.calculateAGP(reportData.glucoseReadings);

    // Analyze patterns
    final patterns = PatternAnalyzer.analyzeAdvancedPatterns(
      reportData.glucoseReadings,
      reportData.insulinRecords,
      reportData.carbRecords,
    );

    // Create PDF document
    final pdf = pw.Document();

    // Add pages
    await _addOverviewPage(pdf, reportData, patterns, userName);
    await _addPatternsPage(pdf, patterns, reportData, userName);
    await _addDailyViewPages(pdf, reportData, userName);
    await _addAGPPage(pdf, agpData, reportData, userName);
    await _addStatisticsPages(pdf, reportData, userName);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/glucose_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<void> _addOverviewPage(
    pw.Document pdf,
    ReportPeriodData reportData,
    List<Map<String, dynamic>> patterns,
    String userName,
  ) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(
                'Overview',
                reportData.startDate,
                reportData.endDate,
                userName,
              ),

              pw.SizedBox(height: 20),

              // Main metrics row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left column - Glucose metrics
                  pw.Expanded(
                    flex: 2,
                    child: _buildGlucoseMetrics(reportData.statistics),
                  ),

                  pw.SizedBox(width: 20),

                  // Right column - TIR and Sensor usage
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      children: [
                        _buildTimeInRangeChart(reportData.statistics),
                        pw.SizedBox(height: 20),
                        _buildSensorUsage(reportData),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Top Patterns section
              _buildTopPatternsSection(patterns),

              pw.SizedBox(height: 30),

              // AGP Chart
              _buildOverviewAGPChart(reportData.glucoseReadings),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildHeader(
    String title,
    DateTime startDate,
    DateTime endDate,
    String userName,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: darkText,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '${_formatDateRange(startDate, endDate)} | $userName',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: primaryBlue,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              'Glucose Companion',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGlucoseMetrics(Map<String, dynamic> statistics) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Glucose',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 20),

          // Average glucose and GMI row
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Average glucose',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: '${statistics['average'].toStringAsFixed(1)}',
                            style: pw.TextStyle(
                              fontSize: 36,
                              fontWeight: pw.FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          pw.TextSpan(
                            text: ' mmol/L',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GMI',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      '${statistics['gmi'].toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Standard deviation and CV row
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Standard deviation',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text:
                                '${statistics['standardDeviation'].toStringAsFixed(1)}',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          pw.TextSpan(
                            text: ' mmol/L',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Coefficient of Variation',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: '${statistics['cv'].toStringAsFixed(1)}',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          pw.TextSpan(
                            text: ' %',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTimeInRangeChart(Map<String, dynamic> statistics) {
    final double timeBelowRange = statistics['timeBelowRange'];
    final double timeInRange = statistics['timeInRange'];
    final double timeAboveRange = statistics['timeAboveRange'];

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Time in Range',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 15),

          // TIR visualization (simplified bar chart)
          pw.Container(
            height: 120,
            child: pw.Column(
              children: [
                _buildTIRBar(
                  'Very High',
                  timeAboveRange > 30 ? timeAboveRange - 30 : 0,
                  dangerRed,
                ),
                _buildTIRBar(
                  'High',
                  timeAboveRange > 30 ? 30 : timeAboveRange,
                  warningYellow,
                ),
                _buildTIRBar('In Range', timeInRange, targetGreen),
                _buildTIRBar(
                  'Low',
                  timeBelowRange > 4 ? 4 : timeBelowRange,
                  warningYellow,
                ),
                _buildTIRBar(
                  'Very Low',
                  timeBelowRange > 4 ? timeBelowRange - 4 : 0,
                  dangerRed,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Text(
            'Target Range: 3.9-10.0 mmol/L',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTIRBar(String label, double percentage, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Container(
            width: 100,
            height: 16,
            decoration: pw.BoxDecoration(
              color: lightGray,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                width: percentage,
                height: 16,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            '${percentage.toStringAsFixed(0)}% $label',
            style: pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSensorUsage(ReportPeriodData reportData) {
    final totalDays =
        reportData.endDate.difference(reportData.startDate).inDays;
    final daysWithData = reportData.dailyReadings.length;
    final totalReadings = reportData.glucoseReadings.length;
    final expectedReadings =
        totalDays * 288; // 288 readings per day (every 5 minutes)
    final timeActive = (totalReadings / expectedReadings * 100).clamp(0, 100);

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Sensor usage',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 15),

          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Days with data',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.Text(
                '$daysWithData/$totalDays days',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 15),

              pw.Text(
                'Time active',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.Text(
                '${timeActive.toStringAsFixed(0)}%',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 15),

              pw.Text(
                'Avg. calibrations per day',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.Text(
                '0.0',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTopPatternsSection(List<Map<String, dynamic>> patterns) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Top Patterns',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),

        pw.SizedBox(height: 15),

        pw.Column(
          children:
              patterns
                  .take(3)
                  .map((pattern) => _buildPatternItem(pattern))
                  .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPatternItem(Map<String, dynamic> pattern) {
    PdfColor indicatorColor;
    switch (pattern['severity']) {
      case 'positive':
        indicatorColor = targetGreen;
        break;
      case 'high':
        indicatorColor = dangerRed;
        break;
      case 'moderate':
        indicatorColor = warningYellow;
        break;
      default:
        indicatorColor = primaryBlue;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 4, height: 40, color: indicatorColor),

          pw.SizedBox(width: 15),

          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  pattern['title'],
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  pattern['description'],
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildOverviewAGPChart(List<GlucoseReading> readings) {
    return pw.Container(
      height: 200,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'This graph shows your data averaged over ${readings.length > 2000 ? '7+' : '3-7'} days',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),

          pw.SizedBox(height: 20),

          // Simplified AGP visualization
          pw.Expanded(
            child: pw.Container(
              width: double.infinity,
              child: pw.Stack(
                children: [
                  // Target range background
                  pw.Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    top: 100, // Замінили height на top
                    child: pw.Container(color: targetGreen.shade(0.1)),
                  ),

                  // Time axis labels
                  pw.Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    top: 160, // Замінили height на top
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('00:00', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('06:00', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('12:00', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('18:00', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('00:00', style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),

                  // Glucose range labels
                  pw.Positioned(
                    top: 0,
                    bottom: 30,
                    left: 0,
                    right: 500, // Замінили width на right
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('22.5', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('17.5', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('12.5', style: pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          '10.0',
                          style: pw.TextStyle(fontSize: 10, color: targetGreen),
                        ),
                        pw.Text('7.5', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('5.0', style: pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          '3.9',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: warningYellow,
                          ),
                        ),
                        pw.Text('2.5', style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  double _calculatePercentage(
    List<GlucoseReading> readings,
    bool Function(GlucoseReading) condition,
  ) {
    if (readings.isEmpty) return 0.0;
    final count = readings.where(condition).length;
    return (count / readings.length) * 100;
  }

  String _formatDateRange(DateTime startDate, DateTime endDate) {
    return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  // Export functionality for different formats
  Future<File> exportToCSV({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    final reportData = await _dataProcessor.processDataForPeriod(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/glucose_data_${DateTime.now().millisecondsSinceEpoch}.csv',
    );

    final csvContent = StringBuffer();

    // CSV Header
    csvContent.writeln(
      'timestamp,glucose_mmol_l,glucose_mg_dl,trend,trend_direction,trend_arrow',
    );

    // Add glucose readings
    for (var reading in reportData.glucoseReadings) {
      csvContent.writeln(
        '${reading.timestamp.toIso8601String()},'
        '${reading.mmolL.toStringAsFixed(2)},'
        '${reading.value.toStringAsFixed(0)},'
        '${reading.trend},'
        '${reading.trendDirection},'
        '${reading.trendArrow}',
      );
    }

    await file.writeAsString(csvContent.toString());
    return file;
  }

  Future<File> exportToExcel({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    final reportData = await _dataProcessor.processDataForPeriod(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/glucose_data_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    // For actual Excel export, you would use the excel package
    // This is a placeholder implementation
    final csvContent = StringBuffer();
    csvContent.writeln(
      'timestamp,glucose_mmol_l,glucose_mg_dl,trend,trend_direction',
    );

    for (var reading in reportData.glucoseReadings) {
      csvContent.writeln(
        '${reading.timestamp.toIso8601String()},'
        '${reading.mmolL.toStringAsFixed(2)},'
        '${reading.value.toStringAsFixed(0)},'
        '${reading.trend},'
        '${reading.trendDirection}',
      );
    }

    // Write as CSV for now (in real implementation, use excel package)
    await file.writeAsString(csvContent.toString());
    return file;
  }

  Future<void> _addPatternsPage(
    pw.Document pdf,
    List<Map<String, dynamic>> patterns,
    ReportPeriodData reportData,
    String userName,
  ) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                'Patterns',
                reportData.startDate,
                reportData.endDate,
                userName,
              ),

              pw.SizedBox(height: 30),

              // Detailed patterns analysis
              ...patterns
                  .map((pattern) => _buildDetailedPattern(pattern, reportData))
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildDetailedPattern(
    Map<String, dynamic> pattern,
    ReportPeriodData reportData,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 30),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            pattern['title'],
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Text(
            pattern['description'],
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),

          if (pattern['percentage'] != null) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Occurrence: ${pattern['percentage'].toStringAsFixed(1)}%',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ],

          if (pattern['recommendation'] != null) ...[
            pw.SizedBox(height: 15),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Recommendation:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    pattern['recommendation'],
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addDailyViewPages(
    pw.Document pdf,
    ReportPeriodData reportData,
    String userName,
  ) async {
    final sortedDays = reportData.dailyReadings.keys.toList()..sort();

    // Group days into pages (2 days per page)
    for (int i = 0; i < sortedDays.length; i += 2) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  'Daily View',
                  reportData.startDate,
                  reportData.endDate,
                  userName,
                ),

                pw.SizedBox(height: 20),

                // First day
                _buildDayChart(
                  sortedDays[i],
                  reportData.dailyReadings[sortedDays[i]]!,
                ),

                pw.SizedBox(height: 20),

                // Second day (if exists)
                if (i + 1 < sortedDays.length)
                  _buildDayChart(
                    sortedDays[i + 1],
                    reportData.dailyReadings[sortedDays[i + 1]]!,
                  ),
              ],
            );
          },
        ),
      );
    }
  }

  pw.Widget _buildDayChart(String dayKey, List<dynamic> readings) {
    final date = DateTime.parse(dayKey);
    final dayName = _getDayName(date.weekday);

    return pw.Container(
      // height: 180, // Видаліть цей параметр
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$dayName, ${date.day}/${date.month}/${date.year}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 15),

          // Simplified glucose chart visualization
          pw.Container(
            // width: double.infinity, // Видаліть цей параметр
            // height: 120, // Додайте фіксовану висоту
            child: pw.Stack(
              children: [
                // Target range background
                pw.Positioned(
                  bottom: 30,
                  left: 50,
                  right: 0,
                  top: 20,
                  child: pw.Container(color: targetGreen.shade(0.1)),
                ),

                // Time axis
                pw.Positioned(
                  bottom: 0,
                  left: 50,
                  right: 0,
                  // height: 20, // Видаліть цей параметр
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('00:00', style: pw.TextStyle(fontSize: 9)),
                      pw.Text('06:00', style: pw.TextStyle(fontSize: 9)),
                      pw.Text('12:00', style: pw.TextStyle(fontSize: 9)),
                      pw.Text('18:00', style: pw.TextStyle(fontSize: 9)),
                      pw.Text('00:00', style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),

                // Glucose range labels
                pw.Positioned(
                  top: 20,
                  bottom: 30,
                  left: 0,
                  // width: 45, // Видаліть цей параметр
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('15.0', style: pw.TextStyle(fontSize: 9)),
                      pw.Text(
                        '10.0',
                        style: pw.TextStyle(fontSize: 9, color: targetGreen),
                      ),
                      pw.Text('7.5', style: pw.TextStyle(fontSize: 9)),
                      pw.Text('5.0', style: pw.TextStyle(fontSize: 9)),
                      pw.Text(
                        '3.9',
                        style: pw.TextStyle(fontSize: 9, color: warningYellow),
                      ),
                      pw.Text('2.5', style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addAGPPage(
    pw.Document pdf,
    Map<String, List<double>> agpData,
    ReportPeriodData reportData,
    String userName,
  ) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                'AGP (Ambulatory Glucose Profile)',
                reportData.startDate,
                reportData.endDate,
                userName,
              ),

              pw.SizedBox(height: 20),

              // TIR Goals and Metrics Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _buildTIRGoals(reportData.statistics)),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: _buildGlucoseMetricsAGP(reportData.statistics),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Main AGP Chart
              _buildMainAGPChart(agpData),

              pw.SizedBox(height: 30),

              // Daily glucose profiles
              _buildDailyGlucoseProfiles(reportData.dailyReadings),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildTIRGoals(Map<String, dynamic> statistics) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Time in Ranges',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Goals for Type 1 and Type 2 Diabetes',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),

          pw.SizedBox(height: 15),

          pw.Text(
            'Each 5% increase in the Target Range is clinically beneficial.\nEach 1% time in range = about 15 minutes per day',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),

          pw.SizedBox(height: 20),

          // TIR breakdown with goals
          _buildTIRGoalItem(
            'Very High',
            statistics['timeAboveRange'] > 30
                ? statistics['timeAboveRange'] - 30
                : 0,
            '<5%',
            dangerRed,
          ),
          _buildTIRGoalItem(
            'High',
            statistics['timeAboveRange'] > 30
                ? 30
                : statistics['timeAboveRange'],
            '<25%',
            warningYellow,
          ),
          _buildTIRGoalItem(
            'In Range',
            statistics['timeInRange'],
            '>70%',
            targetGreen,
          ),
          _buildTIRGoalItem(
            'Low',
            statistics['timeBelowRange'] > 4 ? 4 : statistics['timeBelowRange'],
            '<4%',
            warningYellow,
          ),
          _buildTIRGoalItem(
            'Very Low',
            statistics['timeBelowRange'] > 4
                ? statistics['timeBelowRange'] - 4
                : 0,
            '<1%',
            dangerRed,
          ),

          pw.SizedBox(height: 15),

          pw.Text(
            'Target Range: 3.9-10.0 mmol/L\nVery High: Above 13.9 mmol/L\nVery Low: Below 3.0 mmol/L',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTIRGoalItem(
    String label,
    double percentage,
    String goal,
    PdfColor color,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Container(
            // width: 15, // Видаліть цей параметр
            // height: 15, // Видаліть цей параметр
            color: color,
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Text(label, style: pw.TextStyle(fontSize: 12))),
          pw.Text(
            '${percentage.toStringAsFixed(0)}%',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 15),
          pw.Text(
            'Goal: $goal',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGlucoseMetricsAGP(Map<String, dynamic> statistics) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Glucose Metrics',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 20),

          _buildMetricRow(
            'Average Glucose',
            'Goal: <8.5 mmol/L',
            '${statistics['average'].toStringAsFixed(1)} mmol/L',
          ),
          pw.SizedBox(height: 15),
          _buildMetricRow(
            'GMI',
            'Goal: <7%',
            '${statistics['gmi'].toStringAsFixed(1)}%',
          ),
          pw.SizedBox(height: 15),
          _buildMetricRow(
            'Coefficient of Variation',
            'Goal: <36%',
            '${statistics['cv'].toStringAsFixed(1)}%',
          ),
          pw.SizedBox(height: 15),
          _buildMetricRow('Time CGM Active', '', '96.8%'),
        ],
      ),
    );
  }

  pw.Widget _buildMetricRow(String label, String goal, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        if (goal.isNotEmpty) ...[
          pw.Text(
            goal,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: primaryBlue,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMainAGPChart(Map<String, List<double>> agpData) {
    return pw.Container(
      // height: 250, // Видаліть цей параметр
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Ambulatory Glucose Profile (AGP)',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'AGP is a summary of glucose values from the report period, with median (50%) and other percentiles shown as if they occurred in a single day.',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),

          pw.SizedBox(height: 15),

          // AGP Chart visualization
          pw.Container(
            // width: double.infinity, // Видаліть цей параметр
            // height: 180, // Додайте фіксовану висоту
            child: pw.Stack(
              children: [
                // Target range background
                pw.Positioned(
                  bottom: 30,
                  left: 60,
                  right: 0,
                  top: 80,
                  child: pw.Container(color: targetGreen.shade(0.1)),
                ),

                // Time axis
                pw.Positioned(
                  bottom: 0,
                  left: 60,
                  right: 0,
                  // height: 25, // Видаліть цей параметр
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('00:00', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('03:00', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('06:00', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('09:00', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('12:00', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('15:00', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('18:00', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('21:00', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('00:00', style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDailyGlucoseProfiles(
    Map<String, List<dynamic>> dailyReadings,
  ) {
    final sortedDays = dailyReadings.keys.toList()..sort();

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Daily Glucose Profile',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Each daily profile represents a midnight-to-midnight period.',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),

          pw.SizedBox(height: 15),

          // Grid of daily profiles (7 days per week, multiple weeks)
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                sortedDays.take(14).map((dayKey) {
                  final date = DateTime.parse(dayKey);
                  return _buildMiniDayProfile(date, dailyReadings[dayKey]!);
                }).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMiniDayProfile(DateTime date, List<dynamic> readings) {
    return pw.Container(
      // width: 70, // Видаліть цей параметр
      // height: 60, // Видаліть цей параметр
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '${date.day}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Container(
            // width: double.infinity, // Видаліть цей параметр
            // height: 30, // Додайте фіксовану висоту
            decoration: pw.BoxDecoration(
              color: lightGray,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addStatisticsPages(
    pw.Document pdf,
    ReportPeriodData reportData,
    String userName,
  ) async {
    // Daily Statistics Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                'Daily Statistics',
                reportData.startDate,
                reportData.endDate,
                userName,
              ),

              pw.SizedBox(height: 20),

              _buildDailyStatisticsTable(reportData.dailyReadings),
            ],
          );
        },
      ),
    );

    // Hourly Statistics Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                'Hourly Statistics',
                reportData.startDate,
                reportData.endDate,
                userName,
              ),

              pw.SizedBox(height: 20),

              _buildHourlyStatisticsTable(reportData.hourlyReadings),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildDailyStatisticsTable(
    Map<String, List<dynamic>> dailyReadings,
  ) {
    final sortedDays = dailyReadings.keys.toList()..sort();

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Table header
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Daily Statistics',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                ...sortedDays.take(7).map((day) {
                  final date = DateTime.parse(day);
                  return pw.Expanded(
                    child: pw.Text(
                      _getDayName(date.weekday),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Sample statistics rows
          _buildStatisticsRow(
            'TIR %',
            sortedDays.take(7).toList(),
            dailyReadings,
          ),
          _buildStatisticsRow(
            'Avg Glucose',
            sortedDays.take(7).toList(),
            dailyReadings,
          ),
          _buildStatisticsRow(
            '# Readings',
            sortedDays.take(7).toList(),
            dailyReadings,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatisticsRow(
    String label,
    List<String> days,
    Map<String, List<dynamic>> dailyReadings,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: pw.TextStyle(fontSize: 10))),
          ...days.map((day) {
            final readings = dailyReadings[day] ?? [];
            String displayValue = '-';

            if (readings.isNotEmpty) {
              switch (label) {
                case 'TIR %':
                  displayValue = '75';
                  break;
                case 'Avg Glucose':
                  displayValue = '8.2';
                  break;
                case '# Readings':
                  displayValue = readings.length.toString();
                  break;
              }
            }

            return pw.Expanded(
              child: pw.Text(
                displayValue,
                style: pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  pw.Widget _buildHourlyStatisticsTable(
    Map<int, List<dynamic>> hourlyReadings,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Table header for first 12 hours
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Hourly Statistics',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                ...List.generate(
                  12,
                  (i) => pw.Expanded(
                    child: pw.Text(
                      '${i.toString().padLeft(2, '0')}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sample hourly statistics
          _buildHourlyStatisticsRow(
            'TIR %',
            List.generate(12, (i) => i),
            hourlyReadings,
          ),
          _buildHourlyStatisticsRow(
            'Avg',
            List.generate(12, (i) => i),
            hourlyReadings,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHourlyStatisticsRow(
    String label,
    List<int> hours,
    Map<int, List<dynamic>> hourlyReadings,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: pw.TextStyle(fontSize: 8))),
          ...hours.map((hour) {
            String displayValue = '-';

            switch (label) {
              case 'TIR %':
                displayValue = '${60 + (hour * 2)}';
                break;
              case 'Avg':
                displayValue = '${7.0 + (hour * 0.3)}'.substring(0, 3);
                break;
            }

            return pw.Expanded(
              child: pw.Text(
                displayValue,
                style: pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

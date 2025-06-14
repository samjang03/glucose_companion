import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/presentation/bloc/export/export_bloc.dart';
import 'package:glucose_companion/presentation/bloc/export/export_event.dart';
import 'package:glucose_companion/presentation/bloc/export/export_state.dart';
import '../../../../services/export/export_service.dart';

class ExportSection extends StatefulWidget {
  const ExportSection({Key? key}) : super(key: key);

  @override
  State<ExportSection> createState() => _ExportSectionState();
}

class _ExportSectionState extends State<ExportSection> {
  DateTime _startDate = DateTime(2025, 5, 1);
  DateTime _endDate = DateTime(2025, 6, 1);
  ExportFormat _selectedFormat = ExportFormat.pdf;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExportBloc, ExportState>(
      listener: (context, state) {
        if (state is ExportSuccess) {
          _showSuccessDialog(context, state.result);
        } else if (state is ExportFailure) {
          _showErrorDialog(context, state.error);
        }
      },
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.file_download_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Export Data',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Export your glucose data and reports for sharing with healthcare providers or personal records.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),

              // Date Range Selection
              _buildDateRangeSelector(context),

              const SizedBox(height: 20),

              // Format Selection
              _buildFormatSelector(context),

              const SizedBox(height: 24),

              // Export Button
              _buildExportButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildDateField(
                context,
                'From',
                _startDate,
                (date) => setState(() => _startDate = date),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _buildDateField(
                context,
                'To',
                _endDate,
                (date) => setState(() => _endDate = date),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Quick date range buttons
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDateButton('Last 7 days', () {
              final now = DateTime.now();
              setState(() {
                _endDate = now;
                _startDate = now.subtract(const Duration(days: 7));
              });
            }),
            _buildQuickDateButton('Last 30 days', () {
              final now = DateTime.now();
              setState(() {
                _endDate = now;
                _startDate = now.subtract(const Duration(days: 30));
              });
            }),
            _buildQuickDateButton('May 2025', () {
              setState(() {
                _startDate = DateTime(2025, 5, 1);
                _endDate = DateTime(2025, 6, 1);
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );

        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildFormatSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Format',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 12),

        Column(
          children:
              ExportFormat.values.map((format) {
                return RadioListTile<ExportFormat>(
                  value: format,
                  groupValue: _selectedFormat,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFormat = value);
                    }
                  },
                  title: Text(_getFormatTitle(format)),
                  subtitle: Text(_getFormatDescription(format)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
        ),
      ],
    );
  }

  String _getFormatTitle(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'PDF Report';
      case ExportFormat.csv:
        return 'CSV Data';
      case ExportFormat.excel:
        return 'Excel Spreadsheet';
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'Complete report with charts, statistics, and patterns analysis';
      case ExportFormat.csv:
        return 'Raw glucose data in comma-separated values format';
      case ExportFormat.excel:
        return 'Structured data in Excel format with multiple sheets';
    }
  }

  Widget _buildExportButton(BuildContext context) {
    return BlocBuilder<ExportBloc, ExportState>(
      builder: (context, state) {
        final isLoading = state is ExportInProgress;
        final progress = state is ExportInProgress ? state.progress : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: isLoading ? null : () => _startExport(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  isLoading
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              value: progress > 0 ? progress : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Generating... ${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getFormatIcon(_selectedFormat)),
                          const SizedBox(width: 8),
                          Text(
                            'Export ${_getFormatTitle(_selectedFormat)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),

            if (isLoading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
      case ExportFormat.csv:
        return Icons.table_chart;
      case ExportFormat.excel:
        return Icons.grid_on;
    }
  }

  void _startExport(BuildContext context) {
    // Validate date range
    if (_startDate.isAfter(_endDate)) {
      _showErrorDialog(context, 'Start date must be before end date.');
      return;
    }

    final daysDifference = _endDate.difference(_startDate).inDays;
    if (daysDifference > 90) {
      _showErrorDialog(context, 'Date range cannot exceed 90 days.');
      return;
    }

    // Start export
    context.read<ExportBloc>().add(
      StartExportEvent(
        startDate: _startDate,
        endDate: _endDate,
        format: _selectedFormat,
        userId: 'demo_user', // Replace with actual user ID
        userName: 'Demo User', // Replace with actual user name
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, ExportResult result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Export Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.message),
                const SizedBox(height: 16),
                Text(
                  'File saved to: ${result.file?.path ?? ''}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (result.file != null) {
                    context.read<ExportBloc>().add(
                      ShareFileEvent(result.file!),
                    );
                  }
                },
                child: const Text('Share'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: Icon(Icons.error, color: Colors.red, size: 48),
            title: const Text('Export Failed'),
            content: Text(error),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

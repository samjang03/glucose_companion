import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/core/di/injection_container.dart';
import 'package:glucose_companion/data/datasources/dexcom_api_client.dart';
import 'package:glucose_companion/data/models/user_settings.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_bloc.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_event.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();
    _settingsBloc = sl<SettingsBloc>();
    _settingsBloc.add(LoadSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _settingsBloc,
      child: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is ReportExported) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report generated successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Показуємо діалог з опціями
            _showReportGeneratedDialog(context, state.filePath);
          } else if (state is ReportExportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading && state is! ReportExporting) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SettingsLoaded ||
              state is ReportExporting ||
              state is ReportPreviewing ||
              state is ReportSharing) {
            final settings = _getSettingsFromState(state);
            return _buildSettingsUI(context, settings, state);
          } else if (state is SettingsError) {
            return Center(child: Text('Error: ${state.message}'));
          } else {
            return const Center(child: Text('Loading settings...'));
          }
        },
      ),
    );
  }

  UserSettings _getSettingsFromState(SettingsState state) {
    if (state is SettingsLoaded) return state.settings;
    if (state is ReportExporting ||
        state is ReportPreviewing ||
        state is ReportSharing) {
      final previousState = _settingsBloc.state;
      if (previousState is SettingsLoaded) return previousState.settings;
    }
    return const UserSettings(); // Fallback
  }

  Widget _buildSettingsUI(
    BuildContext context,
    UserSettings settings,
    SettingsState currentState,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildMeasurementSection(settings),
        const Divider(),
        _buildThresholdsSection(settings),
        const Divider(),
        _buildDexcomSection(settings),
        const Divider(),
        _buildAlertSection(settings),
        const Divider(),
        _buildThemeSection(settings),
        const Divider(),
        _buildProfileSection(settings),
        const Divider(),

        // НОВА СЕКЦІЯ ДЛЯ ЕКСПОРТУ ЗВІТІВ
        _buildReportsSection(settings, currentState),

        const SizedBox(height: 60), // Додатковий простір внизу
      ],
    );
  }

  // НОВА СЕКЦІЯ ДЛЯ ЗВІТІВ
  Widget _buildReportsSection(
    UserSettings settings,
    SettingsState currentState,
  ) {
    final isExporting = currentState is ReportExporting;
    final isPreviewing = currentState is ReportPreviewing;
    final isSharing = currentState is ReportSharing;
    final isProcessing = isExporting || isPreviewing || isSharing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Reports & Export',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: Icon(Icons.file_download),
        ),

        if (isProcessing)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  isExporting
                      ? (currentState as ReportExporting).message
                      : isPreviewing
                      ? 'Preparing preview...'
                      : isSharing
                      ? 'Sharing report...'
                      : 'Processing...',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

        ListTile(
          title: const Text('Generate PDF Report'),
          subtitle: const Text('Create detailed glucose analysis report'),
          trailing: const Icon(Icons.picture_as_pdf),
          enabled: !isProcessing,
          onTap: () => _showReportOptionsDialog(context),
        ),

        ListTile(
          title: const Text('Preview Report'),
          subtitle: const Text('Preview report before generating'),
          trailing: const Icon(Icons.preview),
          enabled: !isProcessing,
          onTap: () => _showPreviewOptionsDialog(context),
        ),

        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Reports include glucose statistics, time in range analysis, daily patterns, and detected trends over your selected period.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  void _showReportOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Generate PDF Report'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select time period for your glucose report:'),
                const SizedBox(height: 16),

                _buildReportOption(
                  context,
                  'Last 7 days',
                  'Quick overview of recent glucose data',
                  () => _generateReport(context, 7),
                ),
                _buildReportOption(
                  context,
                  'Last 14 days',
                  'Recommended period for comprehensive analysis',
                  () => _generateReport(context, 14),
                ),
                _buildReportOption(
                  context,
                  'Last 30 days',
                  'Extended analysis for pattern recognition',
                  () => _generateReport(context, 30),
                ),
                _buildReportOption(
                  context,
                  'Custom period',
                  'Choose your own date range',
                  () => _showCustomDatePicker(context, false),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _showPreviewOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Preview Report'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select time period to preview:'),
                const SizedBox(height: 16),

                _buildReportOption(
                  context,
                  'Last 7 days',
                  'Quick preview',
                  () => _previewReport(context, 7),
                ),
                _buildReportOption(
                  context,
                  'Last 14 days',
                  'Standard preview',
                  () => _previewReport(context, 14),
                ),
                _buildReportOption(
                  context,
                  'Custom period',
                  'Choose your own date range',
                  () => _showCustomDatePicker(context, true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Widget _buildReportOption(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _generateReport(BuildContext context, int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    _settingsBloc.add(
      ExportReportEvent(startDate: startDate, endDate: endDate),
    );
  }

  void _previewReport(BuildContext context, int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    _settingsBloc.add(
      PreviewReportEvent(startDate: startDate, endDate: endDate),
    );
  }

  void _showCustomDatePicker(BuildContext context, bool isPreview) {
    DateTime startDate = DateTime.now().subtract(const Duration(days: 14));
    DateTime endDate = DateTime.now();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    isPreview
                        ? 'Preview Custom Period'
                        : 'Generate Custom Report',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Start Date'),
                        subtitle: Text(
                          '${startDate.day}/${startDate.month}/${startDate.year}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              startDate = picked;
                              if (startDate.isAfter(endDate)) {
                                endDate = startDate.add(
                                  const Duration(days: 1),
                                );
                              }
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: const Text('End Date'),
                        subtitle: Text(
                          '${endDate.day}/${endDate.month}/${endDate.year}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              endDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Period: ${endDate.difference(startDate).inDays + 1} days',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (isPreview) {
                          _settingsBloc.add(
                            PreviewReportEvent(
                              startDate: startDate,
                              endDate: endDate,
                            ),
                          );
                        } else {
                          _settingsBloc.add(
                            ExportReportEvent(
                              startDate: startDate,
                              endDate: endDate,
                            ),
                          );
                        }
                      },
                      child: Text(isPreview ? 'Preview' : 'Generate'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showReportGeneratedDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Report Generated'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text(
                  'Your glucose report has been successfully generated!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _settingsBloc.add(ShareReportEvent(filePath));
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
    );
  }

  // ІСНУЮЧІ МЕТОДИ ЗАЛИШАЮТЬСЯ БЕЗ ЗМІН
  Widget _buildMeasurementSection(UserSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Measurement Units',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: Icon(Icons.straighten),
        ),
        RadioListTile<String>(
          title: const Text('mmol/L'),
          value: 'mmol_L',
          groupValue: settings.glucoseUnits,
          onChanged: (value) {
            if (value != null) {
              _settingsBloc.add(UpdateGlucoseUnitsEvent(value));
            }
          },
        ),
        RadioListTile<String>(
          title: const Text('mg/dL'),
          value: 'mg_dL',
          groupValue: settings.glucoseUnits,
          onChanged: (value) {
            if (value != null) {
              _settingsBloc.add(UpdateGlucoseUnitsEvent(value));
            }
          },
        ),
      ],
    );
  }

  Widget _buildThresholdsSection(UserSettings settings) {
    final valueSymbol = settings.glucoseUnits == 'mmol_L' ? 'mmol/L' : 'mg/dL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Glucose Thresholds',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: Icon(Icons.warning),
        ),
        ListTile(
          title: const Text('Low Glucose Threshold'),
          subtitle: Text('Below this value is considered low'),
          trailing: Text(
            '${settings.lowThreshold.toStringAsFixed(1)} $valueSymbol',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap:
              () => _showThresholdDialog(
                context,
                'Low Glucose Threshold',
                settings.lowThreshold,
                (value) => _settingsBloc.add(
                  UpdateThresholdsEvent(lowThreshold: value),
                ),
                min: 3.0,
                max: 5.0,
                units: valueSymbol,
              ),
        ),
        ListTile(
          title: const Text('High Glucose Threshold'),
          subtitle: Text('Above this value is considered high'),
          trailing: Text(
            '${settings.highThreshold.toStringAsFixed(1)} $valueSymbol',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap:
              () => _showThresholdDialog(
                context,
                'High Glucose Threshold',
                settings.highThreshold,
                (value) => _settingsBloc.add(
                  UpdateThresholdsEvent(highThreshold: value),
                ),
                min: 8.0,
                max: 15.0,
                units: valueSymbol,
              ),
        ),
        ListTile(
          title: const Text('Urgent Low Threshold'),
          subtitle: Text('Critical low level, requires immediate action'),
          trailing: Text(
            '${settings.urgentLowThreshold.toStringAsFixed(1)} $valueSymbol',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          onTap:
              () => _showThresholdDialog(
                context,
                'Urgent Low Threshold',
                settings.urgentLowThreshold,
                (value) => _settingsBloc.add(
                  UpdateThresholdsEvent(urgentLowThreshold: value),
                ),
                min: 2.0,
                max: 4.0,
                units: valueSymbol,
              ),
        ),
        ListTile(
          title: const Text('Urgent High Threshold'),
          subtitle: Text('Critical high level, requires attention'),
          trailing: Text(
            '${settings.urgentHighThreshold.toStringAsFixed(1)} $valueSymbol',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          onTap:
              () => _showThresholdDialog(
                context,
                'Urgent High Threshold',
                settings.urgentHighThreshold,
                (value) => _settingsBloc.add(
                  UpdateThresholdsEvent(urgentHighThreshold: value),
                ),
                min: 12.0,
                max: 20.0,
                units: valueSymbol,
              ),
        ),
      ],
    );
  }

  Widget _buildDexcomSection(UserSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Dexcom Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: Icon(Icons.settings_remote),
        ),
        ListTile(
          title: const Text('Dexcom Region'),
          subtitle: const Text('Select your Dexcom account region'),
          trailing: DropdownButton<String>(
            value: settings.dexcomRegion,
            onChanged: (value) {
              if (value != null) {
                _settingsBloc.add(UpdateDexcomRegionEvent(value));
              }
            },
            items: const [
              DropdownMenuItem(value: 'us', child: Text('United States')),
              DropdownMenuItem(value: 'ous', child: Text('Outside US')),
              DropdownMenuItem(value: 'jp', child: Text('Japan')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSection(UserSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Alerts & Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: Icon(Icons.notifications),
        ),
        SwitchListTile(
          title: const Text('Enable Alerts'),
          subtitle: const Text('Get notified for critical glucose levels'),
          value: settings.alertsEnabled,
          onChanged: (value) {
            _settingsBloc.add(UpdateAlertSettingsEvent(alertsEnabled: value));
          },
        ),
        SwitchListTile(
          title: const Text('Prediction Alerts'),
          subtitle: const Text(
            'Alert when glucose is predicted to go out of range',
          ),
          value: settings.predictionAlertsEnabled,
          onChanged:
              settings.alertsEnabled
                  ? (value) {
                    _settingsBloc.add(
                      UpdateAlertSettingsEvent(predictionAlertsEnabled: value),
                    );
                  }
                  : null,
        ),
        SwitchListTile(
          title: const Text('Vibration'),
          subtitle: const Text('Vibrate on alert'),
          value: settings.vibrateOnAlert,
          onChanged:
              settings.alertsEnabled
                  ? (value) {
                    _settingsBloc.add(
                      UpdateAlertSettingsEvent(vibrateOnAlert: value),
                    );
                  }
                  : null,
        ),
        SwitchListTile(
          title: const Text('Sound'),
          subtitle: const Text('Play sound on alert'),
          value: settings.soundOnAlert,
          onChanged:
              settings.alertsEnabled
                  ? (value) {
                    _settingsBloc.add(
                      UpdateAlertSettingsEvent(soundOnAlert: value),
                    );
                  }
                  : null,
        ),
      ],
    );
  }

  Widget _buildThemeSection(UserSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: Icon(Icons.color_lens),
        ),
        RadioListTile<String>(
          title: const Text('Light Theme'),
          value: 'light',
          groupValue: settings.theme,
          onChanged: (value) {
            if (value != null) {
              _settingsBloc.add(UpdateThemeEvent(value));
            }
          },
        ),
        RadioListTile<String>(
          title: const Text('Dark Theme'),
          value: 'dark',
          groupValue: settings.theme,
          onChanged: (value) {
            if (value != null) {
              _settingsBloc.add(UpdateThemeEvent(value));
            }
          },
        ),
        RadioListTile<String>(
          title: const Text('System Default'),
          value: 'system',
          groupValue: settings.theme,
          onChanged: (value) {
            if (value != null) {
              _settingsBloc.add(UpdateThemeEvent(value));
            }
          },
        ),
      ],
    );
  }

  Widget _buildProfileSection(UserSettings settings) {
    final TextEditingController emailController = TextEditingController(
      text: settings.userEmail,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: Icon(Icons.person),
        ),
        ListTile(
          title: const Text('User ID'),
          subtitle: Text(settings.userId.isEmpty ? 'Not set' : settings.userId),
          trailing: const Icon(Icons.info),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'User ID is generated automatically and cannot be changed',
                ),
              ),
            );
          },
        ),
        ListTile(
          title: const Text('Email'),
          subtitle: Text(
            settings.userEmail.isEmpty ? 'Not set' : settings.userEmail,
          ),
          trailing: const Icon(Icons.edit),
          onTap: () => _showEmailDialog(context, emailController, settings),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            onPressed: () => _showClearDataDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Clear All Data'),
          ),
        ),
      ],
    );
  }

  void _showThresholdDialog(
    BuildContext context,
    String title,
    double currentValue,
    Function(double) onSave, {
    required double min,
    required double max,
    required String units,
  }) {
    double value = currentValue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select a value between $min and $max $units'),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Slider(
                        value: value,
                        min: min,
                        max: max,
                        divisions: ((max - min) * 10).toInt(),
                        onChanged: (newValue) {
                          setState(() {
                            value = newValue;
                          });
                        },
                      ),
                      Text(
                        '${value.toStringAsFixed(1)} $units',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onSave(value);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEmailDialog(
    BuildContext context,
    TextEditingController controller,
    UserSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Email'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty &&
                    controller.text.contains('@')) {
                  _settingsBloc.add(
                    UpdateUserInfoEvent(userEmail: controller.text),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'Are you sure you want to clear all your data? This action cannot be undone.',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement clear data functionality
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data has been cleared'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All Data'),
            ),
          ],
        );
      },
    );
  }
}

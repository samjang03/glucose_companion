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
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SettingsLoaded) {
            return _buildSettingsUI(context, state.settings);
          } else if (state is SettingsError) {
            return Center(child: Text('Error: ${state.message}'));
          } else {
            return const Center(child: Text('Loading settings...'));
          }
        },
      ),
    );
  }

  Widget _buildSettingsUI(BuildContext context, UserSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildMeasurementSection(settings),
        const Divider(),
        _buildThresholdsSection(settings),
        const Divider(),
        _buildDexcomSection(settings),
        const Divider(),
        _buildRefreshSection(settings),
        const Divider(),
        _buildAlertSection(settings),
        const Divider(),
        _buildThemeSection(settings),
        const Divider(),
        _buildProfileSection(settings),
        const SizedBox(height: 60), // Додатковий простір внизу
      ],
    );
  }

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

  Widget _buildRefreshSection(UserSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Data Refresh',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: Icon(Icons.refresh),
        ),
        ListTile(
          title: const Text('Auto Refresh Interval'),
          subtitle: Text(
            'Glucose data will refresh every ${settings.autoRefreshInterval} minutes',
          ),
          trailing: DropdownButton<int>(
            value: settings.autoRefreshInterval,
            onChanged: (value) {
              if (value != null) {
                _settingsBloc.add(UpdateRefreshIntervalEvent(value));
              }
            },
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 minute')),
              DropdownMenuItem(value: 2, child: Text('2 minutes')),
              DropdownMenuItem(value: 5, child: Text('5 minutes')),
              DropdownMenuItem(value: 10, child: Text('10 minutes')),
              DropdownMenuItem(value: 15, child: Text('15 minutes')),
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

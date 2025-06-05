import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/core/l10n/app_localizations.dart';
import 'package:glucose_companion/core/utils/glucose_converter.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_bloc.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_state.dart';
import 'package:intl/intl.dart';

class CurrentGlucoseCard extends StatelessWidget {
  final GlucoseReading? reading;
  final bool isLoading;
  final VoidCallback onRefresh;

  const CurrentGlucoseCard({
    Key? key,
    this.reading,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final useMMOL =
            state is SettingsLoaded
                ? state.settings.glucoseUnits == 'mmol_L'
                : true;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.currentGlucose,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: isLoading ? null : onRefresh,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  const CircularProgressIndicator()
                else if (reading == null)
                  Text(
                    AppLocalizations.noDataAvailable,
                    style: const TextStyle(fontSize: 18),
                  )
                else
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            useMMOL
                                ? reading!.mmolL.toStringAsFixed(1)
                                : GlucoseConverter.mmolToMgdl(
                                  reading!.mmolL,
                                ).round().toString(),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: _getGlucoseColor(reading!.mmolL, theme),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            useMMOL ? 'ммоль/л' : 'мг/дл',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getLocalizedTrendDirection(
                              reading!.trendDirection,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: _getGlucoseColor(reading!.mmolL, theme),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            reading!.trendArrow,
                            style: TextStyle(
                              fontSize: 18,
                              color: _getGlucoseColor(reading!.mmolL, theme),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocalizations.lastUpdate} ${DateFormat('HH:mm').format(reading!.timestamp)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getGlucoseColor(double glucoseValue, ThemeData theme) {
    if (glucoseValue < 3.9) {
      return Colors.red;
    } else if (glucoseValue > 10.0) {
      return Colors.orange;
    } else {
      return theme.colorScheme.primary;
    }
  }

  String _getLocalizedTrendDirection(String trendDirection) {
    switch (trendDirection.toLowerCase()) {
      case 'stable':
      case 'flat':
        return AppLocalizations.stable;
      case 'rising':
        return AppLocalizations.get('rising');
      case 'falling':
        return AppLocalizations.get('falling');
      case 'rising rapidly':
        return AppLocalizations.get('rising_rapidly');
      case 'falling rapidly':
        return AppLocalizations.get('falling_rapidly');
      case 'rising slightly':
        return AppLocalizations.get('rising_slightly');
      case 'falling slightly':
        return AppLocalizations.get('falling_slightly');
      default:
        return trendDirection;
    }
  }
}

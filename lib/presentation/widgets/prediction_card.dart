import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/core/l10n/app_localizations.dart';
import 'package:glucose_companion/core/utils/glucose_converter.dart';
import 'package:glucose_companion/presentation/bloc/prediction/prediction_bloc.dart';
import 'package:glucose_companion/presentation/bloc/prediction/prediction_event.dart';
import 'package:glucose_companion/presentation/bloc/prediction/prediction_state.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_bloc.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_state.dart';
import 'package:intl/intl.dart';

class PredictionCard extends StatelessWidget {
  const PredictionCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PredictionBloc, PredictionState>(
      builder: (context, state) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.glucosePrediction,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        context.read<PredictionBloc>().add(
                          const LoadPredictionEvent(),
                        );
                      },
                    ),
                  ],
                ),
                _buildPredictionContent(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPredictionContent(BuildContext context, PredictionState state) {
    if (state is PredictionLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(AppLocalizations.loading),
            ],
          ),
        ),
      );
    } else if (state is PredictionLoaded) {
      return BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final useMMOL =
              settingsState is SettingsLoaded
                  ? settingsState.settings.glucoseUnits == 'mmol_L'
                  : true;

          final predValue =
              useMMOL
                  ? state.predictedValue
                  : GlucoseConverter.mmolToMgdl(state.predictedValue);

          final predValueString =
              useMMOL
                  ? state.predictedValue.toStringAsFixed(1)
                  : predValue.round().toString();

          final units = useMMOL ? 'ммоль/л' : 'мг/дл';

          // Визначаємо колір на основі прогнозованого значення
          Color valueColor;
          if (state.predictedValue < 3.9) {
            valueColor = Colors.red;
          } else if (state.predictedValue > 10.0) {
            valueColor = Colors.orange;
          } else {
            valueColor = Theme.of(context).colorScheme.primary;
          }

          final timeFormat = DateFormat('HH:mm');

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${AppLocalizations.in1HourAt} ${timeFormat.format(state.predictionTime)}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      predValueString,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(units, style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    } else if (state is PredictionError) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<PredictionBloc>().add(const LoadPredictionEvent());
              },
              child: Text(AppLocalizations.tryAgain),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.noPredictionAvailable,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<PredictionBloc>().add(const LoadPredictionEvent());
              },
              child: Text(AppLocalizations.getPrediction),
            ),
          ],
        ),
      );
    }
  }
}

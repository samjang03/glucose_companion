import 'package:flutter/material.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Glucose',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              const Text('No data available', style: TextStyle(fontSize: 18))
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reading!.mmolL.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _getGlucoseColor(reading!.mmolL, theme),
                        ),
                      ),
                      const Text(
                        'mmol/L',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        reading!.trendArrow,
                        style: TextStyle(
                          fontSize: 24,
                          color: _getGlucoseColor(reading!.mmolL, theme),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    reading!.trendDirection,
                    style: TextStyle(
                      fontSize: 16,
                      color: _getGlucoseColor(reading!.mmolL, theme),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last update: ${DateFormat('HH:mm').format(reading!.timestamp)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
          ],
        ),
      ),
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
}

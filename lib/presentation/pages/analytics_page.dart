// lib/presentation/pages/analytics_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/core/di/injection_container.dart';
import 'package:glucose_companion/data/models/analytics_data.dart';
import 'package:glucose_companion/presentation/bloc/analytics/analytics_bloc.dart';
import 'package:glucose_companion/presentation/bloc/analytics/analytics_event.dart';
import 'package:glucose_companion/presentation/bloc/analytics/analytics_state.dart';
import 'package:glucose_companion/presentation/widgets/hourly_average_chart.dart';
import 'package:glucose_companion/presentation/widgets/stats_card.dart';
import 'package:glucose_companion/presentation/widgets/time_in_range_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late AnalyticsBloc _analyticsBloc;
  int _selectedPeriod = 7; // Default to 7 days

  @override
  void initState() {
    super.initState();
    _analyticsBloc = sl<AnalyticsBloc>();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    _analyticsBloc.add(LoadAnalyticsEvent(days: _selectedPeriod));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _analyticsBloc,
      child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              _loadAnalytics();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),
                  if (state is AnalyticsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (state is AnalyticsLoaded)
                    _buildAnalyticsContent(context, state.data)
                  else if (state is AnalyticsError)
                    _buildErrorMessage(state.message)
                  else
                    const Center(
                      child: Text('Select a period to view analytics'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildPeriodButton(2, 'Today'),
          _buildPeriodButton(7, '7 days'),
          _buildPeriodButton(14, '14 days'),
          _buildPeriodButton(30, '30 days'),
          _buildPeriodButton(90, '90 days'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(int days, String label) {
    final isSelected = _selectedPeriod == days;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = days;
          });
          _loadAnalytics();
        },
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(
    BuildContext context,
    GlucoseAnalyticsData data,
  ) {
    // Перевіряємо чи є дані
    if (data.readingsCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No data available for this period',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Glucose readings will appear here once you start using the app',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAnalytics,
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('MMM d, yyyy');
    final period =
        "${dateFormat.format(data.startDate)} — ${dateFormat.format(data.endDate)}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Період за який показана статистика
        Text(
          period,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // Glucose
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Glucose',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      data.averageGlucose.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getColorForGlucose(data.averageGlucose),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('mmol/L', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Standard Deviation'),
                    const SizedBox(width: 8),
                    Text(
                      data.standardDeviation.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(' mmol/L'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('GMI'),
                    const SizedBox(width: 8),
                    Text(
                      '${data.gmi.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Time in Range
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Time in Range',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${data.timeAboveRange.toStringAsFixed(1)}% High',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${data.timeInRange.toStringAsFixed(1)}% In Range',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(width: 12, height: 12, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              '${data.timeBelowRange.toStringAsFixed(1)}% Low',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${data.timeInRange.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getColorForTIR(data.timeInRange),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TimeInRangeChart(
                  timeInRange: data.timeInRange,
                  timeAboveRange: data.timeAboveRange,
                  timeBelowRange: data.timeBelowRange,
                ),
                const SizedBox(height: 8),
                const Text('Target Range: 3.9–10.0 mmol/L'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // События
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Hypo Events',
                value: data.hypoEvents.toString(),
                icon: Icons.arrow_downward,
                iconColor: Colors.red,
                valueColor: data.hypoEvents > 0 ? Colors.red : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatsCard(
                title: 'Hyper Events',
                value: data.hyperEvents.toString(),
                icon: Icons.arrow_upward,
                iconColor: Colors.orange,
                valueColor: data.hyperEvents > 0 ? Colors.orange : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Hourly Average
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Patterns',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                HourlyAverageChart(hourlyAverages: data.hourlyAverages),
                const SizedBox(height: 8),
                const Text(
                  'Hourly average glucose levels',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Додаткова інформація
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Additional Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Readings Count'),
                  trailing: Text(
                    data.readingsCount.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Time in Urgent Low (<3.0 mmol/L)'),
                  trailing: Text(
                    '${data.timeInUrgentLow.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: data.timeInUrgentLow > 1 ? Colors.red : null,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Time in Urgent High (>13.9 mmol/L)'),
                  trailing: Text(
                    '${data.timeInUrgentHigh.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: data.timeInUrgentHigh > 5 ? Colors.red : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading analytics data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Color _getColorForGlucose(double value) {
    if (value < 3.9) {
      return Colors.red;
    } else if (value > 10.0) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getColorForTIR(double value) {
    if (value < 50) {
      return Colors.red;
    } else if (value < 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/core/di/injection_container.dart';
import 'package:glucose_companion/data/models/alert.dart';
import 'package:glucose_companion/presentation/bloc/alerts/alerts_bloc.dart';
import 'package:glucose_companion/presentation/bloc/alerts/alerts_event.dart';
import 'package:glucose_companion/presentation/bloc/alerts/alerts_state.dart';
import 'package:glucose_companion/presentation/bloc/home/home_bloc.dart';
import 'package:glucose_companion/presentation/bloc/home/home_state.dart';
import 'package:intl/intl.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AlertsBloc _alertsBloc;
  String _userId = 'default_user';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _alertsBloc = sl<AlertsBloc>();

    // Get the current user ID from Home bloc state
    final homeState = sl<HomeBloc>().state;
    if (homeState is CurrentGlucoseLoaded ||
        homeState is GlucoseHistoryLoaded ||
        homeState is DailyRecordsLoaded) {
      // Update user ID when we have it
      // This would be better handled with a dedicated user bloc
      setState(() {
        _userId = 'default_user'; // Replace with actual user ID when available
      });
    }

    // Load active alerts by default
    _loadAlerts(activeOnly: true);

    // Listener for tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Tab 0 = Active alerts, Tab 1 = All alerts/history
        _loadAlerts(activeOnly: _tabController.index == 0);
      }
    });
  }

  void _loadAlerts({required bool activeOnly}) {
    _alertsBloc.add(LoadAlertsEvent(userId: _userId, activeOnly: activeOnly));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _alertsBloc,
      child: Scaffold(
        body: Column(
          children: [
            // Tab bar for switching between active and all alerts
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Active Alerts'),
                Tab(text: 'Alert History'),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Active alerts tab
                  _buildMockAlertsList(context, true),

                  // Alert history tab
                  _buildMockAlertsList(context, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Цей метод створює список мок-сповіщень для демонстрації
  Widget _buildMockAlertsList(BuildContext context, bool isActiveTab) {
    final now = DateTime.now();

    // Створюємо тестові сповіщення
    final List<Alert> mockAlerts =
        isActiveTab
            ?
            // Активні сповіщення
            [
              Alert(
                id: 1,
                userId: _userId,
                type: 'urgent_low',
                timestamp: now.subtract(const Duration(minutes: 5)),
                value: 2.8,
                message: 'Urgent Low Glucose Alert',
                severity: 'critical',
                status: 'pending',
              ),
              Alert(
                id: 2,
                userId: _userId,
                type: 'high',
                timestamp: now.subtract(const Duration(minutes: 10)),
                value: 11.5,
                message: 'High Glucose Alert',
                severity: 'warning',
                status: 'pending',
              ),
              Alert(
                id: 3,
                userId: _userId,
                type: 'prediction_low',
                timestamp: now,
                value: 3.5,
                message:
                    'Predicted Low Glucose at ${DateFormat('HH:mm').format(now.add(const Duration(minutes: 30)))}',
                severity: 'info',
                status: 'pending',
              ),
              Alert(
                id: 4,
                userId: _userId,
                type: 'rapid_fall',
                timestamp: now.subtract(const Duration(minutes: 15)),
                value: 5.8,
                message: 'Glucose Falling Rapidly',
                severity: 'warning',
                status: 'pending',
              ),
              Alert(
                id: 5,
                userId: _userId,
                type: 'data_gap',
                timestamp: now.subtract(const Duration(minutes: 20)),
                value: null,
                message: 'No glucose data for 25 minutes',
                severity: 'warning',
                status: 'pending',
              ),
            ]
            :
            // Архівні сповіщення (історія сповіщень)
            [
              Alert(
                id: 6,
                userId: _userId,
                type: 'urgent_high',
                timestamp: now.subtract(const Duration(hours: 2)),
                value: 15.7,
                message: 'Urgent High Glucose',
                severity: 'critical',
                status: 'acknowledged',
                acknowledgedAt: now.subtract(const Duration(hours: 1)),
              ),
              Alert(
                id: 7,
                userId: _userId,
                type: 'high',
                timestamp: now.subtract(const Duration(hours: 4)),
                value: 12.2,
                message: 'High Glucose',
                severity: 'warning',
                status: 'dismissed',
                acknowledgedAt: now.subtract(
                  const Duration(hours: 3, minutes: 50),
                ),
              ),
              Alert(
                id: 8,
                userId: _userId,
                type: 'low',
                timestamp: now.subtract(const Duration(hours: 6)),
                value: 3.7,
                message: 'Low Glucose',
                severity: 'warning',
                status: 'acknowledged',
                acknowledgedAt: now.subtract(
                  const Duration(hours: 5, minutes: 55),
                ),
              ),
              Alert(
                id: 9,
                userId: _userId,
                type: 'data_gap',
                timestamp: now.subtract(const Duration(hours: 8)),
                value: null,
                message: 'No glucose data for 30 minutes',
                severity: 'warning',
                status: 'dismissed',
                acknowledgedAt: now.subtract(
                  const Duration(hours: 7, minutes: 45),
                ),
              ),
            ];

    return ListView.builder(
      itemCount: mockAlerts.length,
      itemBuilder: (context, index) {
        final alert = mockAlerts[index];
        return _buildAlertItem(context, alert);
      },
    );
  }

  Widget _buildAlertItem(BuildContext context, Alert alert) {
    // Define icon and color based on severity
    IconData icon;
    Color color;

    switch (alert.severity) {
      case 'critical':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'warning':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'info':
      default:
        icon = Icons.info;
        color = Colors.blue;
        break;
    }

    // Format time
    final timeFormat = DateFormat('HH:mm, MMM d');
    final formattedTime = timeFormat.format(alert.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          alert.message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(formattedTime),
            if (alert.value != null)
              Text(
                'Glucose: ${alert.value!.toStringAsFixed(1)} mmol/L',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getValueColor(alert.value!),
                ),
              ),
            if (alert.status != 'pending' && alert.acknowledgedAt != null)
              Text(
                '${alert.status == 'acknowledged' ? 'Acknowledged' : 'Dismissed'} at ${DateFormat('HH:mm').format(alert.acknowledgedAt!)}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing:
            alert.status == 'pending'
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      tooltip: 'Acknowledge',
                      onPressed: () {
                        // В демо-режимі нічого не робимо
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      tooltip: 'Dismiss',
                      onPressed: () {
                        // В демо-режимі нічого не робимо
                      },
                    ),
                  ],
                )
                : null,
      ),
    );
  }

  Color _getValueColor(double value) {
    if (value < 3.9) {
      return Colors.red;
    } else if (value > 10.0) {
      return Colors.orange;
    }
    return Theme.of(context).colorScheme.primary;
  }
}

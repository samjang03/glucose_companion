// lib/presentation/pages/alerts_page.dart
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
                  BlocBuilder<AlertsBloc, AlertsState>(
                    builder: (context, state) {
                      if (state is AlertsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is AlertsLoaded) {
                        return _buildAlertsList(context, state.alerts);
                      } else if (state is AlertError) {
                        return Center(child: Text('Error: ${state.message}'));
                      } else {
                        return const Center(
                          child: Text('No alerts to display'),
                        );
                      }
                    },
                  ),

                  // Alert history tab
                  BlocBuilder<AlertsBloc, AlertsState>(
                    builder: (context, state) {
                      if (state is AlertsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is AlertsLoaded) {
                        return _buildAlertsList(context, state.alerts);
                      } else if (state is AlertError) {
                        return Center(child: Text('Error: ${state.message}'));
                      } else {
                        return const Center(
                          child: Text('No alert history to display'),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(BuildContext context, List<Alert> alerts) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabController.index == 0 ? Icons.check_circle : Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0
                  ? 'No active alerts'
                  : 'No alerts in history',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
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

    return Dismissible(
      key: Key('alert_${alert.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text(
                    'Are you sure you want to delete this alert?',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (direction) {
        if (alert.id != null) {
          context.read<AlertsBloc>().add(DeleteAlertEvent(alert.id!));
        }
      },
      child: Card(
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
                          if (alert.id != null) {
                            context.read<AlertsBloc>().add(
                              AcknowledgeAlertEvent(alert.id!),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        tooltip: 'Dismiss',
                        onPressed: () {
                          if (alert.id != null) {
                            context.read<AlertsBloc>().add(
                              DismissAlertEvent(alert.id!),
                            );
                          }
                        },
                      ),
                    ],
                  )
                  : null,
        ),
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

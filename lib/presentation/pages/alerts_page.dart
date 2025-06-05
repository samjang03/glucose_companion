import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/core/di/injection_container.dart';
import 'package:glucose_companion/core/l10n/app_localizations.dart';
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
      setState(() {
        _userId = 'default_user';
      });
    }

    // Load active alerts by default
    _loadAlerts(activeOnly: true);

    // Listener for tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
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
              tabs: [
                Tab(text: AppLocalizations.activeAlerts),
                Tab(text: AppLocalizations.alertHistory),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Active alerts tab
                  _buildRealisticAlertsList(context, true),

                  // Alert history tab
                  _buildRealisticAlertsList(context, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Створює реалістичний список сповіщень
  Widget _buildRealisticAlertsList(BuildContext context, bool isActiveTab) {
    final now = DateTime.now();

    // Створюємо реалістичні сповіщення
    final List<Alert> mockAlerts =
        isActiveTab
            ?
            // Активні сповіщення - тільки останні важливі
            [
              Alert(
                id: 1,
                userId: _userId,
                type: 'low',
                timestamp: now.subtract(const Duration(minutes: 3)),
                value: 3.7,
                message: 'Низька глюкоза',
                severity: 'warning',
                status: 'pending',
              ),
              Alert(
                id: 2,
                userId: _userId,
                type: 'prediction_low',
                timestamp: now.subtract(const Duration(minutes: 8)),
                value: 3.4,
                message:
                    'Прогнозується низька глюкоза о ${DateFormat('HH:mm').format(now.add(const Duration(minutes: 52)))}',
                severity: 'info',
                status: 'pending',
              ),
            ]
            :
            // Історія сповіщень - логічна послідовність
            [
              Alert(
                id: 3,
                userId: _userId,
                type: 'low',
                timestamp: now.subtract(const Duration(minutes: 3)),
                value: 3.7,
                message: 'Низька глюкоза',
                severity: 'warning',
                status: 'pending',
              ),
              Alert(
                id: 4,
                userId: _userId,
                type: 'prediction_low',
                timestamp: now.subtract(const Duration(minutes: 8)),
                value: 3.4,
                message:
                    'Прогнозується низька глюкоза о ${DateFormat('HH:mm').format(now.add(const Duration(minutes: 52)))}',
                severity: 'info',
                status: 'pending',
              ),
              Alert(
                id: 5,
                userId: _userId,
                type: 'data_gap',
                timestamp: now.subtract(const Duration(minutes: 35)),
                value: null,
                message: 'Відсутні дані глюкози протягом 27 хвилин',
                severity: 'warning',
                status: 'acknowledged',
                acknowledgedAt: now.subtract(const Duration(minutes: 32)),
              ),
              Alert(
                id: 6,
                userId: _userId,
                type: 'rapid_fall',
                timestamp: now.subtract(const Duration(minutes: 95)),
                value: 8.1,
                message: 'Глюкоза швидко падає',
                severity: 'warning',
                status: 'acknowledged',
                acknowledgedAt: now.subtract(const Duration(minutes: 90)),
              ),
              Alert(
                id: 7,
                userId: _userId,
                type: 'high',
                timestamp: now.subtract(const Duration(hours: 2, minutes: 5)),
                value: 11.2,
                message: 'Висока глюкоза',
                severity: 'warning',
                status: 'dismissed',
                acknowledgedAt: now.subtract(
                  const Duration(hours: 1, minutes: 58),
                ),
              ),
              Alert(
                id: 8,
                userId: _userId,
                type: 'prediction_high',
                timestamp: now.subtract(const Duration(hours: 2, minutes: 45)),
                value: 12.8,
                message:
                    'Прогнозується висока глюкоза о ${DateFormat('HH:mm').format(now.subtract(const Duration(hours: 1, minutes: 45)))}',
                severity: 'info',
                status: 'dismissed',
                acknowledgedAt: now.subtract(
                  const Duration(hours: 2, minutes: 40),
                ),
              ),
              Alert(
                id: 9,
                userId: _userId,
                type: 'rapid_rise',
                timestamp: now.subtract(const Duration(hours: 3, minutes: 15)),
                value: 7.8,
                message: 'Глюкоза швидко зростає',
                severity: 'warning',
                status: 'acknowledged',
                acknowledgedAt: now.subtract(
                  const Duration(hours: 3, minutes: 10),
                ),
              ),
            ];

    if (mockAlerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                isActiveTab
                    ? 'Немає активних сповіщень'
                    : 'Історія сповіщень порожня',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                isActiveTab
                    ? 'Усі сповіщення опрацьовано'
                    : 'Сповіщення з\'являтимуться тут',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: mockAlerts.length,
      itemBuilder: (context, index) {
        final alert = mockAlerts[index];
        return _buildAlertItem(context, alert);
      },
    );
  }

  Widget _buildAlertItem(BuildContext context, Alert alert) {
    // Define icon and color based on severity and type
    IconData icon;
    Color color;

    switch (alert.type) {
      case 'urgent_low':
        icon = Icons.arrow_downward;
        color = Colors.red[700]!;
        break;
      case 'low':
        icon = Icons.trending_down;
        color = Colors.red[500]!;
        break;
      case 'urgent_high':
        icon = Icons.arrow_upward;
        color = Colors.red[700]!;
        break;
      case 'high':
        icon = Icons.trending_up;
        color = Colors.orange[600]!;
        break;
      case 'rapid_fall':
        icon = Icons.south;
        color = Colors.orange[500]!;
        break;
      case 'rapid_rise':
        icon = Icons.north;
        color = Colors.orange[500]!;
        break;
      case 'prediction_low':
      case 'prediction_high':
        icon = Icons.schedule;
        color = Colors.blue[600]!;
        break;
      case 'data_gap':
        icon = Icons.signal_wifi_off;
        color = Colors.grey[600]!;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue[600]!;
        break;
    }

    // Format time
    final timeFormat = DateFormat('HH:mm, d MMM');
    final formattedTime = timeFormat.format(alert.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      elevation: alert.status == 'pending' ? 3 : 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(
            alert.status == 'pending' ? 0.2 : 0.1,
          ),
          child: Icon(
            icon,
            color: alert.status == 'pending' ? color : color.withOpacity(0.6),
          ),
        ),
        title: Text(
          _getLocalizedAlertMessage(alert),
          style: TextStyle(
            fontWeight:
                alert.status == 'pending' ? FontWeight.bold : FontWeight.normal,
            color: alert.status == 'pending' ? null : Colors.grey[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (alert.value != null) ...[
              const SizedBox(height: 2),
              Text(
                '${AppLocalizations.glucose} ${alert.value!.toStringAsFixed(1)} ммоль/л',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getValueColor(alert.value!),
                  fontSize: 13,
                ),
              ),
            ],
            if (alert.status != 'pending' && alert.acknowledgedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '${_getStatusText(alert.status)} о ${DateFormat('HH:mm').format(alert.acknowledgedAt!)}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        trailing:
            alert.status == 'pending'
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      tooltip: AppLocalizations.acknowledge,
                      onPressed: () {
                        // В демо-режимі просто показуємо снекбар
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Сповіщення підтверджено'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      tooltip: AppLocalizations.dismiss,
                      onPressed: () {
                        // В демо-режимі просто показуємо снекбар
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Сповіщення відхилено'),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                )
                : Icon(
                  alert.status == 'acknowledged' ? Icons.check : Icons.close,
                  color: Colors.grey[400],
                ),
      ),
    );
  }

  String _getLocalizedAlertMessage(Alert alert) {
    switch (alert.type) {
      case 'urgent_low':
        return 'Критично низька глюкоза';
      case 'low':
        return 'Низька глюкоза';
      case 'urgent_high':
        return 'Критично висока глюкоза';
      case 'high':
        return 'Висока глюкоза';
      case 'rapid_fall':
        return 'Глюкоза швидко падає';
      case 'rapid_rise':
        return 'Глюкоза швидко зростає';
      case 'prediction_low':
      case 'prediction_high':
        return alert.message; // Вже локалізовано в сервісі
      case 'data_gap':
        return alert.message; // Вже локалізовано в сервісі
      default:
        return alert.message;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'acknowledged':
        return AppLocalizations.acknowledged;
      case 'dismissed':
        return AppLocalizations.dismissed;
      default:
        return status;
    }
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

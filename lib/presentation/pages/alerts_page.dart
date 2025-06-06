// lib/presentation/pages/alerts_page.dart
import 'package:flutter/material.dart';
import 'package:glucose_companion/services/realistic_alerts_service.dart';
import 'package:glucose_companion/data/models/alert.dart';
import 'package:intl/intl.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Alert> _allAlerts = [];
  List<Alert> _activeAlerts = [];
  List<Alert> _historyAlerts = [];
  String _userId = 'default_user';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAlerts() {
    _allAlerts = RealisticAlertsService.generateRealisticAlerts();
    _activeAlerts = _allAlerts.where((alert) => alert.isActive).toList();
    _historyAlerts = _allAlerts.where((alert) => !alert.isActive).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                _buildAlertsList(context, _activeAlerts, true),

                // Alert history tab
                _buildAlertsList(context, _historyAlerts, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(
    BuildContext context,
    List<Alert> alerts,
    bool isActiveTab,
  ) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActiveTab ? Icons.check_circle_outline : Icons.history,
              size: 64,
              color: isActiveTab ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isActiveTab ? 'No Active Alerts' : 'No Alert History',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isActiveTab
                  ? 'All glucose levels are within normal range'
                  : 'No alerts have been recorded yet',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertItem(context, alert, isActiveTab);
      },
    );
  }

  Widget _buildAlertItem(BuildContext context, Alert alert, bool isActive) {
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
          _getAlertTitle(alert),
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
            isActive && alert.status == 'pending'
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      tooltip: 'Acknowledge',
                      onPressed: () => _acknowledgeAlert(alert),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      tooltip: 'Dismiss',
                      onPressed: () => _dismissAlert(alert),
                    ),
                  ],
                )
                : null,
      ),
    );
  }

  String _getAlertTitle(Alert alert) {
    switch (alert.type) {
      case 'urgent_low':
        return 'Urgent Low Glucose';
      case 'low_glucose':
        return 'Low Glucose';
      case 'high_glucose':
        return 'High Glucose';
      case 'urgent_high':
        return 'Urgent High Glucose';
      case 'rapid_fall':
        return 'Glucose Falling Rapidly';
      case 'rapid_rise':
        return 'Glucose Rising Rapidly';
      case 'prediction_low':
        // Витягуємо час з повідомлення
        final timeMatch = RegExp(
          r'at (\d{1,2}:\d{2})',
        ).firstMatch(alert.message);
        final time = timeMatch?.group(1) ?? '10:15';
        return 'Predicted Low Glucose at $time';
      case 'prediction_high':
        // Витягуємо час з повідомлення
        final timeMatch = RegExp(
          r'at (\d{1,2}:\d{2})',
        ).firstMatch(alert.message);
        final time = timeMatch?.group(1) ?? '14:35';
        return 'Predicted High Glucose at $time';
      case 'data_gap':
        return 'No glucose data for 30 minutes';
      default:
        return alert.message;
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

  void _acknowledgeAlert(Alert alert) {
    setState(() {
      _activeAlerts.remove(alert);
      final updatedAlert = alert.copyWith(
        status: 'acknowledged',
        acknowledgedAt: DateTime.now(),
      );
      _historyAlerts.insert(0, updatedAlert);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert acknowledged'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _dismissAlert(Alert alert) {
    setState(() {
      _activeAlerts.remove(alert);
      final updatedAlert = alert.copyWith(
        status: 'dismissed',
        acknowledgedAt: DateTime.now(),
      );
      _historyAlerts.insert(0, updatedAlert);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert dismissed'),
        backgroundColor: Colors.grey,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

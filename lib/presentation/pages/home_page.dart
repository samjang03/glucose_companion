// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/core/di/injection_container.dart';
import 'package:glucose_companion/core/security/session_manager.dart';
import 'package:glucose_companion/data/models/activity_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/data/models/glucose_chart_data.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';
import 'package:glucose_companion/presentation/bloc/home/home_bloc.dart';
import 'package:glucose_companion/presentation/bloc/home/home_event.dart';
import 'package:glucose_companion/presentation/bloc/home/home_state.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_bloc.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_state.dart';
import 'package:glucose_companion/presentation/pages/login_page.dart';
import 'package:glucose_companion/presentation/pages/settings_page.dart';
import 'package:glucose_companion/presentation/widgets/activity_input_dialog.dart';
import 'package:glucose_companion/presentation/widgets/current_glucose_card.dart';
import 'package:glucose_companion/presentation/widgets/glucose_chart.dart';
import 'package:glucose_companion/presentation/widgets/insulin_input_dialog.dart';
import 'package:glucose_companion/presentation/widgets/carbs_input_dialog.dart';
import 'package:glucose_companion/presentation/widgets/daily_records_list.dart';
import 'package:glucose_companion/presentation/bloc/prediction/prediction_bloc.dart';
import 'package:glucose_companion/presentation/bloc/prediction/prediction_event.dart';
import 'package:glucose_companion/presentation/widgets/prediction_card.dart';
import 'package:glucose_companion/presentation/bloc/prediction/prediction_state.dart';
import 'package:glucose_companion/presentation/pages/analytics_page.dart';
import 'package:glucose_companion/presentation/bloc/alerts/alerts_bloc.dart';
import 'package:glucose_companion/presentation/bloc/alerts/alerts_state.dart';
import 'package:glucose_companion/presentation/bloc/alerts/alerts_event.dart';
import 'package:glucose_companion/presentation/pages/alerts_page.dart';
import 'package:glucose_companion/presentation/widgets/modern_tab_bar.dart';
import 'package:glucose_companion/presentation/widgets/glucose_trend_chart.dart';
import 'package:badges/badges.dart' as badges;
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _sessionManager = sl<SessionManager>();
  late final HomeBloc _homeBloc;
  late final PredictionBloc _predictionBloc;
  late TabController _tabController;
  late final AlertsBloc _alertsBloc;
  int _activeAlertsCount = 0;
  String _currentUserId = 'default_user';

  GlucoseReading? _currentReading;
  List<GlucoseReading> _glucoseHistory = [];
  List<InsulinRecord> _insulinRecords = [];
  List<CarbRecord> _carbRecords = [];
  List<ActivityRecord> _activityRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Ініціалізація AlertsBloc
    _alertsBloc = sl<AlertsBloc>();

    // Initialize BLoC
    _homeBloc = sl<HomeBloc>();
    _predictionBloc = sl<PredictionBloc>();

    // Set session expiry handler
    _sessionManager.onSessionExpired = _handleSessionExpired;

    // Initialize tab controller
    _tabController = TabController(length: 4, vsync: this);

    // Завантажуємо активні сповіщення для бейджу
    sl<AlertsBloc>().add(
      LoadAlertsEvent(userId: 'default_user', activeOnly: true),
    );

    _tabController.addListener(() {
      // Викликаємо setState щоб оновити FAB при зміні вкладки
      if (mounted) {
        setState(() {});
      }
    });

    // Load initial data
    _refreshData();

    // Завантажуємо активні сповіщення
    _alertsBloc.add(LoadAlertsEvent(userId: _currentUserId, activeOnly: true));

    // Слухаємо зміни стану для оновлення лічильника сповіщень
    _alertsBloc.stream.listen((state) {
      if (state is AlertsLoaded && state.activeOnly) {
        setState(() {
          _activeAlertsCount = state.alerts.length;
        });
      }
    });

    // Запустіть завантаження прогнозу після того, як віджет побудовано
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PredictionBloc>().add(const LoadPredictionEvent());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _homeBloc.close();
    _predictionBloc.close();
    super.dispose();
  }

  void _handleSessionExpired() {
    // Navigate to login page when session expires
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your session has expired. Please login again.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _logout() async {
    await _sessionManager.logout();

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  void _refreshData() {
    _homeBloc.add(LoadCurrentGlucoseEvent());
    _homeBloc.add(const LoadGlucoseHistoryEvent(hours: 3));
    _homeBloc.add(LoadDailyRecordsEvent(DateTime.now()));

    // Запуск оновлення прогнозу, якщо віджет вже побудовано
    if (mounted) {
      try {
        context.read<PredictionBloc>().add(const LoadPredictionEvent());
      } catch (e) {
        print('Failed to update prediction: $e');
      }
    }
  }

  // Конвертація з GlucoseReading в GlucoseDataPoint для нового графіка
  List<GlucoseDataPoint> _convertToHistoryData(List<GlucoseReading> readings) {
    final now = DateTime.now();
    final twoHoursAgo = now.subtract(const Duration(hours: 2));

    // Фільтруємо дані за останні 2 години та округлюємо до десятих
    return readings
        .where((reading) => reading.timestamp.isAfter(twoHoursAgo))
        .map(
          (reading) => GlucoseDataPoint(
            timestamp: reading.timestamp,
            glucose: double.parse(reading.mmolL.toStringAsFixed(1)),
            isPrediction: false,
          ),
        )
        .toList();
  }

  // Генерація тестових даних для прогнозу (замініть на реальні дані з PredictionBloc)
  List<GlucoseDataPoint> _generatePredictionData() {
    if (_currentReading == null) return [];

    final now = DateTime.now();
    final List<GlucoseDataPoint> data = [];

    // Починаємо з поточного значення
    double currentValue = _currentReading!.mmolL;

    // Generate 1 hour of prediction data (12 points, every 5 minutes)
    for (int i = 1; i <= 12; i++) {
      final timestamp = now.add(Duration(minutes: i * 5));

      // Плавний підйом без гармошки
      final timeProgress = i / 12.0;
      final smoothChange =
          currentValue + (timeProgress * 0.6); // підйом на 0.6 за годину

      // Мінімальний шум для реалістичності
      final variation = (math.sin(i * 0.5) * 0.05); // дуже малі коливання

      final glucose = double.parse(
        (smoothChange + variation).toStringAsFixed(1),
      );

      data.add(
        GlucoseDataPoint(
          timestamp: timestamp,
          glucose: glucose.clamp(currentValue - 1.0, currentValue + 2.0),
          isPrediction: true,
        ),
      );
    }

    return data;
  }

  void _showAddDataDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildAddDataOption(Icons.medication, 'Record Insulin', () {
                Navigator.pop(context);
                _showInsulinDialog();
              }),
              _buildAddDataOption(Icons.restaurant, 'Record Carbs', () {
                Navigator.pop(context);
                _showCarbsDialog();
              }),
              _buildAddDataOption(Icons.fitness_center, 'Record Activity', () {
                Navigator.pop(context);
                _showActivityDialog();
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddDataOption(IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A5CFF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF4A5CFF)),
        ),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showActivityDialog({ActivityRecord? record}) {
    showDialog(
      context: context,
      builder: (context) {
        return ActivityInputDialog(
          initialActivityType: record?.activityType,
          initialNotes: record?.notes,
          isEditing: record != null,
          onSave: (activityType, notes) {
            if (record != null) {
              // Режим редагування
              _homeBloc.add(
                UpdateActivityRecordEvent(
                  record.copyWith(activityType: activityType, notes: notes),
                ),
              );
            } else {
              // Новий запис
              _homeBloc.add(
                RecordActivityEvent(activityType: activityType, notes: notes),
              );
            }

            // ВАЖЛИВО: Оновлюємо записи за сьогодні після збереження
            Future.delayed(const Duration(milliseconds: 500), () {
              _homeBloc.add(LoadDailyRecordsEvent(DateTime.now()));
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeBloc),
        BlocProvider.value(value: sl<SettingsBloc>()),
        BlocProvider.value(value: _predictionBloc),
        BlocProvider.value(value: _alertsBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<SettingsBloc, SettingsState>(
            listener: (context, state) {
              if (state is SettingsLoaded || state is SettingsSaved) {
                // Refresh data when settings change
                _refreshData();
              }
            },
          ),
          BlocListener<HomeBloc, HomeState>(
            listener: (context, state) {
              if (state is CurrentGlucoseLoaded) {
                setState(() {
                  _currentReading = state.currentReading;
                  _isLoading = false;
                });
              } else if (state is GlucoseHistoryLoaded) {
                setState(() {
                  _glucoseHistory = state.readings;
                });
              } else if (state is CurrentGlucoseLoading) {
                setState(() {
                  _isLoading = true;
                });
              } else if (state is HomeLoadingFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
                setState(() {
                  _isLoading = false;
                });
              } else if (state is DailyRecordsLoaded) {
                setState(() {
                  _insulinRecords = state.insulinRecords;
                  _carbRecords = state.carbRecords;
                  _activityRecords = state.activityRecords;
                });
              } else if (state is InsulinRecorded || state is CarbsRecorded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Record saved successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xFF4A5CFF),
            elevation: 0,
            title: const Text(
              'SweetSight',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _refreshData,
                tooltip: 'Refresh data',
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    // Overview Tab
                    SizedBox(
                      height: 58, // Трохи збільшили висоту для кращого балансу
                      child: Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.home,
                              size: 20,
                            ), // Трохи збільшили іконку
                            const SizedBox(height: 3),
                            Flexible(
                              child: Text(
                                'Overview',
                                style: const TextStyle(
                                  fontSize: 13,
                                ), // Збільшили до 13px
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Analytics Tab
                    SizedBox(
                      height: 58,
                      child: Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.analytics, size: 20),
                            const SizedBox(height: 3),
                            Flexible(
                              child: Text(
                                'Analytics',
                                style: const TextStyle(
                                  fontSize: 13,
                                ), // Збільшили до 13px
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Alerts Tab with Badge
                    SizedBox(
                      height: 58,
                      child: Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _activeAlertsCount > 0
                                ? badges.Badge(
                                  badgeContent: Text(
                                    _activeAlertsCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.notifications,
                                    size: 20,
                                  ),
                                )
                                : const Icon(Icons.notifications, size: 20),
                            const SizedBox(height: 3),
                            Flexible(
                              child: Text(
                                'Alerts',
                                style: const TextStyle(
                                  fontSize: 13,
                                ), // Збільшили до 13px
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Settings Tab
                    SizedBox(
                      height: 58,
                      child: Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.settings, size: 20),
                            const SizedBox(height: 3),
                            Flexible(
                              child: Text(
                                'Settings',
                                style: const TextStyle(
                                  fontSize: 13,
                                ), // Збільшили до 13px
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorWeight: 2,
                  // Прибираємо стандартні підписи, оскільки використовуємо власні
                  labelStyle: const TextStyle(fontSize: 0),
                  unselectedLabelStyle: const TextStyle(fontSize: 0),
                  // Мінімальні відступи між табами
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 1.0,
                  ), // Трохи зменшили
                  // Розтягуємо таби на всю ширину
                  isScrollable: false,
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildAnalyticsTab(),
              const AlertsPage(),
              const SettingsPage(),
            ],
          ),
          floatingActionButton:
              _tabController.index == 0
                  ? FloatingActionButton(
                    onPressed: _showAddDataDialog,
                    backgroundColor: const Color(0xFF4A5CFF),
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                  : null,
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Glucose Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Glucose',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _refreshData,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const CircularProgressIndicator(color: Color(0xFF4A5CFF))
                  else if (_currentReading != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentReading!.mmolL.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF4A5CFF),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'mmol/L',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentReading!.trendDirection,
                          style: TextStyle(
                            color: const Color(0xFF4A5CFF).withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentReading!.trendArrow,
                          style: TextStyle(
                            color: const Color(0xFF4A5CFF).withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last update: ${_currentReading!.timestamp.hour}:${_currentReading!.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ] else
                    const Text(
                      'No glucose data available',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Glucose Trend Chart - новий график
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  _glucoseHistory.isEmpty && _isLoading
                      ? Container(
                        height: 300,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4A5CFF),
                          ),
                        ),
                      )
                      : GlucoseTrendChart(
                        historyData: _convertToHistoryData(_glucoseHistory),
                        predictionData: _generatePredictionData(),
                        lowThreshold: 3.9,
                        highThreshold: 10.0,
                      ),
            ),

            const SizedBox(height: 16),

            // Today's Records Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
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
                        const Text(
                          'Today\'s Records',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _showAddDataDialog,
                          child: const Text(
                            'Add',
                            style: TextStyle(color: Color(0xFF4A5CFF)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DailyRecordsList(
                      insulinRecords: _insulinRecords,
                      carbRecords: _carbRecords,
                      activityRecords: _activityRecords,
                      onEditInsulin: (record) {
                        _showInsulinDialog(record: record);
                      },
                      onEditCarb: (record) {
                        _showCarbsDialog(record: record);
                      },
                      onEditActivity: (record) {
                        _showActivityDialog(record: record);
                      },
                      onDeleteRecord: (type, id) {
                        _homeBloc.add(DeleteRecordEvent(type, id));
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildStatsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    // Calculate statistics based on historical data
    if (_glucoseHistory.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No data available for statistics',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Calculate basic statistics
    final values = _glucoseHistory.map((r) => r.mmolL).toList();
    final average = values.reduce((a, b) => a + b) / values.length;

    // Time in range
    final inRange = values.where((v) => v >= 3.9 && v <= 10.0).length;
    final timeInRange = (inRange / values.length * 100).toStringAsFixed(1);

    // Time above range
    final aboveRange = values.where((v) => v > 10.0).length;
    final timeAboveRange = (aboveRange / values.length * 100).toStringAsFixed(
      1,
    );

    // Time below range
    final belowRange = values.where((v) => v < 3.9).length;
    final timeBelowRange = (belowRange / values.length * 100).toStringAsFixed(
      1,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              'Average Glucose',
              '${average.toStringAsFixed(1)} mmol/L',
              Colors.white,
            ),
            const Divider(color: Colors.grey),
            _buildStatItem('Time in Range', '$timeInRange%', Colors.green),
            _buildStatItem(
              'Time Above Range',
              '$timeAboveRange%',
              Colors.orange,
            ),
            _buildStatItem('Time Below Range', '$timeBelowRange%', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    // Placeholder for analytics screen
    return const AnalyticsPage();
  }

  void _showInsulinDialog({InsulinRecord? record}) {
    showDialog(
      context: context,
      builder: (context) {
        return InsulinInputDialog(
          initialType: record?.type,
          initialUnits: record?.units,
          initialNotes: record?.notes,
          isEditing: record != null,
          onSave: (units, insulinType, notes) {
            if (record != null) {
              // Режим редагування
              _homeBloc.add(
                UpdateInsulinRecordEvent(
                  record.copyWith(
                    units: units,
                    type: insulinType,
                    notes: notes,
                  ),
                ),
              );
            } else {
              // Новий запис
              _homeBloc.add(
                RecordInsulinEvent(
                  units: units,
                  insulinType: insulinType,
                  notes: notes,
                ),
              );
            }

            // ВАЖЛИВО: Оновлюємо записи за сьогодні після збереження
            Future.delayed(const Duration(milliseconds: 500), () {
              _homeBloc.add(LoadDailyRecordsEvent(DateTime.now()));
            });
          },
        );
      },
    );
  }

  void _showCarbsDialog({CarbRecord? record}) {
    showDialog(
      context: context,
      builder: (context) {
        return CarbsInputDialog(
          initialGrams: record?.grams,
          initialMealType: record?.mealType,
          initialNotes: record?.notes,
          isEditing: record != null,
          onSave: (grams, mealType, notes) {
            if (record != null) {
              // Режим редагування
              _homeBloc.add(
                UpdateCarbRecordEvent(
                  record.copyWith(
                    grams: grams,
                    mealType: mealType,
                    notes: notes,
                  ),
                ),
              );
            } else {
              // Новий запис
              _homeBloc.add(
                RecordCarbsEvent(
                  grams: grams,
                  foodType: mealType,
                  notes: notes,
                ),
              );
            }

            // ВАЖЛИВО: Оновлюємо записи за сьогодні після збереження
            Future.delayed(const Duration(milliseconds: 500), () {
              _homeBloc.add(LoadDailyRecordsEvent(DateTime.now()));
            });
          },
        );
      },
    );
  }
}

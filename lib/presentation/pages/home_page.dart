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
import 'package:badges/badges.dart' as badges;

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

  void _showAddDataDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.medical_services),
                title: const Text('Record Insulin'),
                onTap: () {
                  Navigator.pop(context);
                  _showInsulinDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Record Carbs'),
                onTap: () {
                  Navigator.pop(context);
                  _showCarbsDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('Record Activity'),
                onTap: () {
                  Navigator.pop(context);
                  _showActivityDialog();
                },
              ),
            ],
          ),
        );
      },
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
          appBar: AppBar(
            title: const Text('Glucose Companion'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
                tooltip: 'Refresh data',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                const Tab(text: 'Overview', icon: Icon(Icons.home)),
                const Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
                Tab(
                  text: 'Alerts',
                  icon:
                      _activeAlertsCount > 0
                          ? badges.Badge(
                            badgeContent: Text(
                              _activeAlertsCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            child: const Icon(Icons.notifications),
                          )
                          : const Icon(Icons.notifications),
                ),
                const Tab(text: 'Settings', icon: Icon(Icons.settings)),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
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
                    child: const Icon(Icons.add),
                  )
                  : null,
        ),
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon), const SizedBox(height: 4), Text(label)],
      ),
    );
  }

  Widget _buildTabWithBadge(IconData icon, String label, int badgeCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          badgeCount > 0
              ? badges.Badge(
                badgeContent: Text(
                  badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: Icon(icon),
              )
              : Icon(icon),
          const SizedBox(height: 4),
          Text(label),
        ],
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
            CurrentGlucoseCard(
              reading: _currentReading,
              isLoading: _isLoading,
              onRefresh: _refreshData,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Glucose Trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child:
                          _glucoseHistory.isEmpty && !_isLoading
                              ? const Center(child: Text('No data available'))
                              : _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : GlucoseChart(
                                data: GlucoseChartData.fromReadings(
                                  _glucoseHistory,
                                  DateTime.now(),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            BlocProvider<PredictionBloc>.value(
              value: sl<PredictionBloc>(),
              child: const PredictionCard(),
            ),
            const SizedBox(height: 16),
            Card(
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
                        const Text(
                          'Today\'s Records',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _showAddDataDialog,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DailyRecordsList(
                      insulinRecords: _insulinRecords,
                      carbRecords: _carbRecords,
                      activityRecords:
                          _activityRecords, // Переконайтеся, що тут передається правильний список
                      onEditInsulin: (record) {
                        _showInsulinDialog(record: record);
                      },
                      onEditCarb: (record) {
                        _showCarbsDialog(record: record);
                      },
                      onEditActivity: (record) {
                        _showActivityDialog(
                          record: record,
                        ); // Тут має бути ActivityRecord
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No data available for statistics'),
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Average Glucose'),
              trailing: Text(
                '${average.toStringAsFixed(1)} mmol/L',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Time in Range'),
              trailing: Text(
                '$timeInRange%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            ListTile(
              title: const Text('Time Above Range'),
              trailing: Text(
                '$timeAboveRange%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            ListTile(
              title: const Text('Time Below Range'),
              trailing: Text(
                '$timeBelowRange%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
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
          // Правильний діалог для вуглеводів
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

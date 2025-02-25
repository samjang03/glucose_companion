import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/core/di/injection_container.dart';
import 'package:glucose_companion/core/security/session_manager.dart';
import 'package:glucose_companion/data/models/glucose_chart_data.dart'; // Правильний шлях
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/domain/repositories/dexcom_repository.dart';
import 'package:glucose_companion/presentation/bloc/home/home_bloc.dart';
import 'package:glucose_companion/presentation/bloc/home/home_event.dart';
import 'package:glucose_companion/presentation/bloc/home/home_state.dart';
import 'package:glucose_companion/presentation/pages/login_page.dart';
import 'package:glucose_companion/presentation/widgets/current_glucose_card.dart';
import 'package:glucose_companion/presentation/widgets/glucose_chart.dart'; // Віджет графіка

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _sessionManager = sl<SessionManager>();
  late final HomeBloc _homeBloc;
  late TabController _tabController;

  GlucoseReading? _currentReading;
  List<GlucoseReading> _glucoseHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Ініціалізуємо BLoC
    _homeBloc = HomeBloc(sl<DexcomRepository>());

    // Встановлюємо обробник закінчення сесії
    _sessionManager.onSessionExpired = _handleSessionExpired;

    // Ініціалізуємо контролер вкладок
    _tabController = TabController(length: 3, vsync: this);

    // Завантажуємо початкові дані
    _homeBloc.add(LoadCurrentGlucoseEvent());
    _homeBloc.add(const LoadGlucoseHistoryEvent(hours: 3));
  }

  @override
  void dispose() {
    _homeBloc.close();
    _tabController.dispose();
    super.dispose();
  }

  void _handleSessionExpired() {
    // Переходимо на сторінку входу, якщо сесія закінчилась
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
    _homeBloc.add(RefreshGlucoseDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      bloc: _homeBloc,
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
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
          setState(() {
            _isLoading = false;
          });
        }
      },
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
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Icons.home)),
              Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
              Tab(text: 'Settings', icon: Icon(Icons.settings)),
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
            _buildSettingsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddDataDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    // Розраховуємо статистику на основі історичних даних
    if (_glucoseHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No data available for statistics'),
        ),
      );
    }

    // Розрахунок базової статистики
    final values = _glucoseHistory.map((r) => r.mmolL).toList();
    final average = values.reduce((a, b) => a + b) / values.length;

    // Час в діапазоні
    final inRange = values.where((v) => v >= 3.9 && v <= 10.0).length;
    final timeInRange = (inRange / values.length * 100).toStringAsFixed(1);

    // Час вище діапазону
    final aboveRange = values.where((v) => v > 10.0).length;
    final timeAboveRange = (aboveRange / values.length * 100).toStringAsFixed(
      1,
    );

    // Час нижче діапазону
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
    // Заглушка для аналітичного екрану
    return const Center(child: Text('Analytics - Coming Soon'));
  }

  Widget _buildSettingsTab() {
    // Заглушка для екрану налаштувань
    return const Center(child: Text('Settings - Coming Soon'));
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
                  // Буде реалізовано пізніше
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInsulinDialog() {
    final unitsController = TextEditingController();
    String selectedType = 'Bolus';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record Insulin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Insulin Type'),
                items: const [
                  DropdownMenuItem(value: 'Bolus', child: Text('Bolus')),
                  DropdownMenuItem(value: 'Basal', child: Text('Basal')),
                ],
                onChanged: (value) {
                  selectedType = value ?? 'Bolus';
                },
              ),
              TextField(
                controller: unitsController,
                decoration: const InputDecoration(labelText: 'Units'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (unitsController.text.isNotEmpty) {
                  try {
                    final units = double.parse(unitsController.text);
                    _homeBloc.add(
                      RecordInsulinEvent(
                        units: units,
                        insulinType: selectedType,
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid number'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showCarbsDialog() {
    final carbsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record Carbs'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: carbsController,
                decoration: const InputDecoration(labelText: 'Carbs (grams)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (carbsController.text.isNotEmpty) {
                  try {
                    final carbs = double.parse(carbsController.text);
                    _homeBloc.add(RecordCarbsEvent(grams: carbs));
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid number'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

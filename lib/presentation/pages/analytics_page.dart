// lib/presentation/pages/analytics_page.dart
import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:glucose_companion/core/di/injection_container.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';
import 'package:glucose_companion/services/mock_data_service.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MockDataService _mockDataService = MockDataService();

  // Період для аналізу
  int _selectedPeriod = 7; // Стандартно 7 днів
  String _userId = 'mock_user_1';

  // Дані
  List<GlucoseReading> _glucoseData = [];
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _patterns = [];

  // Масив для відображення AGP
  List<List<double>> _agpPercentiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      // Генеруємо тестові дані
      _glucoseData = _mockDataService.generateMockGlucoseData(
        _selectedPeriod,
        _userId,
      );
      _statistics = _mockDataService.generateStatistics(_glucoseData);
      _patterns = _mockDataService.analyzePatterns(_glucoseData);

      // Генеруємо дані для AGP
      _generateAGPData();
    });
  }

  void _generateAGPData() {
    if (_glucoseData.isEmpty) {
      _agpPercentiles = [];
      return;
    }

    // Створюємо 24-годинний профіль AGP
    // Для кожного 30-хвилинного блоку, розраховуємо перцентилі
    _agpPercentiles = List.generate(
      48,
      (_) => [0, 0, 0, 0, 0],
    ); // [5%, 25%, 50%, 75%, 95%]

    // Групуємо дані по 30-хвилинним інтервалам
    final Map<int, List<double>> timeBlocks = {};

    for (var reading in _glucoseData) {
      // Обчислюємо індекс 30-хвилинного блоку (0-47)
      final hour = reading.timestamp.hour;
      final minute = reading.timestamp.minute;
      final blockIndex = (hour * 2) + (minute ~/ 30);

      if (!timeBlocks.containsKey(blockIndex)) {
        timeBlocks[blockIndex] = [];
      }

      timeBlocks[blockIndex]!.add(reading.mmolL);
    }

    // Обчислюємо перцентилі для кожного блоку
    for (int i = 0; i < 48; i++) {
      if (timeBlocks.containsKey(i) && timeBlocks[i]!.isNotEmpty) {
        final values = timeBlocks[i]!..sort();

        // 5й перцентиль
        _agpPercentiles[i][0] = _getPercentile(values, 5);

        // 25й перцентиль
        _agpPercentiles[i][1] = _getPercentile(values, 25);

        // 50й перцентиль (медіана)
        _agpPercentiles[i][2] = _getPercentile(values, 50);

        // 75й перцентиль
        _agpPercentiles[i][3] = _getPercentile(values, 75);

        // 95й перцентиль
        _agpPercentiles[i][4] = _getPercentile(values, 95);
      } else {
        // Якщо немає даних для цього часового блоку, інтерполюємо з сусідніх
        int prevIndex = (i - 1 + 48) % 48;
        int nextIndex = (i + 1) % 48;

        while (!timeBlocks.containsKey(prevIndex) ||
            timeBlocks[prevIndex]!.isEmpty) {
          prevIndex = (prevIndex - 1 + 48) % 48;
          if (prevIndex == i) break; // Запобігаємо нескінченному циклу
        }

        while (!timeBlocks.containsKey(nextIndex) ||
            timeBlocks[nextIndex]!.isEmpty) {
          nextIndex = (nextIndex + 1) % 48;
          if (nextIndex == i) break; // Запобігаємо нескінченному циклу
        }

        if ((timeBlocks.containsKey(prevIndex) &&
                timeBlocks[prevIndex]!.isNotEmpty) &&
            (timeBlocks.containsKey(nextIndex) &&
                timeBlocks[nextIndex]!.isNotEmpty)) {
          for (int j = 0; j < 5; j++) {
            _agpPercentiles[i][j] =
                (_agpPercentiles[prevIndex][j] +
                    _agpPercentiles[nextIndex][j]) /
                2;
          }
        } else if (timeBlocks.containsKey(prevIndex) &&
            timeBlocks[prevIndex]!.isNotEmpty) {
          _agpPercentiles[i] = List.from(_agpPercentiles[prevIndex]);
        } else if (timeBlocks.containsKey(nextIndex) &&
            timeBlocks[nextIndex]!.isNotEmpty) {
          _agpPercentiles[i] = List.from(_agpPercentiles[nextIndex]);
        } else {
          // Якщо немає даних взагалі, встановлюємо стандартні значення
          _agpPercentiles[i] = [3.9, 5.0, 7.0, 9.0, 12.0];
        }
      }
    }
  }

  double _getPercentile(List<double> sortedValues, int percentile) {
    if (sortedValues.isEmpty) return 0;
    if (sortedValues.length == 1) return sortedValues[0];

    final index = (sortedValues.length - 1) * percentile / 100;
    if (index.floor() == index) {
      return sortedValues[index.toInt()];
    } else {
      final lower = sortedValues[index.floor()];
      final upper = sortedValues[index.ceil()];
      return lower + (upper - lower) * (index - index.floor());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Селектор періоду
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPeriodButton(7, '7 Days'),
                    _buildPeriodButton(14, '14 Days'),
                    _buildPeriodButton(30, '30 Days'),
                  ],
                ),
              ),
            ),
          ),

          // Вкладки для різних типів аналітики
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Patterns'),
              Tab(text: 'AGP'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),

          // Контент вкладок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPatternsTab(),
                _buildAGPTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(int days, String label) {
    return ElevatedButton(
      onPressed: () {
        if (_selectedPeriod != days) {
          setState(() {
            _selectedPeriod = days;
          });
          _loadData();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _selectedPeriod == days
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
        foregroundColor:
            _selectedPeriod == days
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
      ),
      child: Text(label),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок з періодом
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedPeriod Days Overview',
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(DateTime.now().subtract(Duration(days: _selectedPeriod - 1)))} - ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                    style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // Ключові показники
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Glucose Metrics',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Перший ряд метрик - фіксована висота та Expanded для керування розміром
                  SizedBox(
                    height: 80,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Average Glucose',
                            '${_statistics['average']?.toStringAsFixed(1) ?? "N/A"} mmol/L',
                            Icons.bar_chart,
                            _getAverageColor(_statistics['average'] ?? 0),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: _buildMetricCard(
                            'GMI',
                            '${_statistics['gmi']?.toStringAsFixed(1) ?? "N/A"}%',
                            Icons.percent,
                            _getA1cColor(_statistics['gmi'] ?? 0),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Другий ряд метрик - також з фіксованою висотою
                  SizedBox(
                    height: 80,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Std Deviation',
                            '${_statistics['standardDeviation']?.toStringAsFixed(1) ?? "N/A"} mmol/L',
                            Icons.show_chart,
                            _getStdDevColor(
                              _statistics['standardDeviation'] ?? 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: _buildMetricCard(
                            'CV',
                            '${_statistics['cv']?.toStringAsFixed(1) ?? "N/A"}%',
                            Icons.area_chart,
                            _getCVColor(_statistics['cv'] ?? 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // Час у діапазоні
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time in Range',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // TIR діаграма
                  SizedBox(
                    height: 40.0,
                    child: Row(
                      children: [
                        // Часу Нижче Діапазону (червоний)
                        Expanded(
                          flex: (_statistics['timeBelowRange'] ?? 0).round(),
                          child: Container(
                            color: Colors.red,
                            child: Center(
                              child:
                                  _statistics['timeBelowRange'] != null &&
                                          _statistics['timeBelowRange'] >= 5
                                      ? Text(
                                        '${_statistics['timeBelowRange']?.toStringAsFixed(0) ?? "0"}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                        ),

                        // Часу В Діапазоні (зелений)
                        Expanded(
                          flex: (_statistics['timeInRange'] ?? 0).round(),
                          child: Container(
                            color: Colors.green,
                            child: Center(
                              child: Text(
                                '${_statistics['timeInRange']?.toStringAsFixed(0) ?? "0"}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Часу Вище Діапазону (оранжевий)
                        Expanded(
                          flex: (_statistics['timeAboveRange'] ?? 0).round(),
                          child: Container(
                            color: Colors.orange,
                            child: Center(
                              child:
                                  _statistics['timeAboveRange'] != null &&
                                          _statistics['timeAboveRange'] >= 5
                                      ? Text(
                                        '${_statistics['timeAboveRange']?.toStringAsFixed(0) ?? "0"}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Таблиця з деталями
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('Very Low (<3.0 mmol/L)'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '${(_statistics['timeBelowRange'] != null ? (_statistics['timeBelowRange']! * 0.2) : 0).toStringAsFixed(1)}%',
                              textAlign: TextAlign.end,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('Low (3.0-3.9 mmol/L)'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '${(_statistics['timeBelowRange'] != null ? (_statistics['timeBelowRange']! * 0.8) : 0).toStringAsFixed(1)}%',
                              textAlign: TextAlign.end,
                              style: const TextStyle(color: Colors.deepOrange),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('In Range (3.9-10.0 mmol/L)'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '${_statistics['timeInRange']?.toStringAsFixed(1) ?? "0.0"}%',
                              textAlign: TextAlign.end,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('High (10.0-13.9 mmol/L)'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '${(_statistics['timeAboveRange'] != null ? (_statistics['timeAboveRange']! * 0.7) : 0).toStringAsFixed(1)}%',
                              textAlign: TextAlign.end,
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('Very High (>13.9 mmol/L)'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '${(_statistics['timeAboveRange'] != null ? (_statistics['timeAboveRange']! * 0.3) : 0).toStringAsFixed(1)}%',
                              textAlign: TextAlign.end,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // Графік даних глюкози за період
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Average Patterns',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  SizedBox(height: 250.0, child: _buildDailyPatternChart()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsTab() {
    return _patterns.isEmpty
        ? const Center(child: Text('No significant patterns detected'))
        : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _patterns.length,
          itemBuilder: (context, index) {
            final pattern = _patterns[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getPatternIcon(pattern['type']),
                          color: _getPatternColor(pattern['severity']),
                          size: 32.0,
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pattern['title'],
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                pattern['description'],
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16.0),

                    // Рекомендації відповідно до типу паттерну
                    _buildRecommendations(pattern['type']),
                  ],
                ),
              ),
            );
          },
        );
  }

  Widget _buildAGPTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ambulatory Glucose Profile (AGP)',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Based on $_selectedPeriod days of data',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 16.0),

                  SizedBox(height: 300.0, child: _buildAGPChart()),

                  // Додаємо легенду для AGP
                  const SizedBox(height: 16.0),
                  _buildAGPLegend(),

                  const SizedBox(height: 16.0),

                  const Text(
                    'AGP is a summary of glucose values from the report period, with median (50%) and other percentiles shown as if they occurred in a single day.',
                    style: TextStyle(fontSize: 14.0),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Profiles',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Оновлений віджет для перегляду окремих днів
                  _buildDailyProfilesPreview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Додаємо легенду для AGP
  Widget _buildAGPLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend:',
            style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 16.0,
            runSpacing: 8.0,
            children: [
              _buildLegendItem(
                color: Colors.black,
                label: '50% (Median)',
                isLine: true,
                description: 'Middle value',
              ),
              _buildLegendItem(
                color: Colors.blue[300]!,
                label: '25-75%',
                isArea: true,
                description: 'Interquartile range',
              ),
              _buildLegendItem(
                color: Colors.blue[50]!,
                label: '5-95%',
                isArea: true,
                description: '90% of readings',
              ),
              _buildLegendItem(
                color: Colors.red.withOpacity(0.5),
                label: 'Target Range',
                isDashed: true,
                description: '3.9-10.0 mmol/L',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    String description = '',
    bool isLine = false,
    bool isArea = false,
    bool isDashed = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isLine
            ? Container(width: 20, height: 2, color: color)
            : isArea
            ? Container(width: 20, height: 10, color: color)
            : isDashed
            ? Container(
              width: 20,
              height: 1,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: color,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            )
            : Container(width: 10, height: 10, color: color),
        const SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (description.isNotEmpty)
              Text(
                description,
                style: TextStyle(fontSize: 10.0, color: Colors.grey[600]),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyProfilesPreview() {
    // Виводить міні-графіки за останні дні в оновленому вигляді
    return SizedBox(
      height: 350.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: min(_selectedPeriod, 7),
        itemBuilder: (context, index) {
          final day = DateTime.now().subtract(Duration(days: index));

          // Фільтруємо дані глюкози за цей день
          final dayData =
              _glucoseData
                  .where(
                    (reading) =>
                        reading.timestamp.year == day.year &&
                        reading.timestamp.month == day.month &&
                        reading.timestamp.day == day.day,
                  )
                  .toList();

          return Container(
            width: 300.0, // Збільшуємо ширину з 200.0 до 280.0
            margin: const EdgeInsets.only(right: 16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    DateFormat('E, MMM d').format(day),
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child:
                      dayData.isEmpty
                          ? const Center(child: Text('No data'))
                          : _buildImprovedDailyProfileChart(dayData),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImprovedDailyProfileChart(List<GlucoseReading> dayData) {
    if (dayData.isEmpty) return const Center(child: Text('No data'));

    // Сортуємо дані за часом
    dayData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Створюємо точки для графіка з усередненням кожні 15 хвилин, для більшої плавності
    final Map<double, List<double>> aggregatedData = {};

    for (var reading in dayData) {
      // Заокруглюємо до найближчих 15 хвилин для усереднення
      final hour = reading.timestamp.hour;
      final minute = (reading.timestamp.minute ~/ 15) * 15;
      final timeKey = hour + (minute / 60);

      if (!aggregatedData.containsKey(timeKey)) {
        aggregatedData[timeKey] = [];
      }

      aggregatedData[timeKey]!.add(reading.mmolL);
    }

    final List<FlSpot> spots = [];

    // Виправляємо помилку з методом sort
    final sortedKeys = aggregatedData.keys.toList()..sort();

    for (var key in sortedKeys) {
      final values = aggregatedData[key]!;
      final avgValue = values.reduce((a, b) => a + b) / values.length;
      spots.add(FlSpot(key, avgValue));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              // Сіра сітка для значущих ліній
              if (value % 5 == 0) {
                return FlLine(
                  color: Colors.grey[600]!.withOpacity(0.2),
                  strokeWidth: 0.5,
                );
              }
              // Червоні пунктирні лінії для цільових значень
              else if (value == 3.9 || value == 10.0) {
                return FlLine(
                  color: Colors.red.withOpacity(0.5),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              }
              return FlLine(color: Colors.transparent);
            },
            getDrawingVerticalLine: (value) {
              // Вертикальні лінії через кожні 6 годин
              if (value % 6 == 0) {
                return FlLine(
                  color: Colors.grey[600]!.withOpacity(0.2),
                  strokeWidth: 0.5,
                );
              }
              return FlLine(color: Colors.transparent);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 6,
                getTitlesWidget: (value, meta) {
                  // Тільки для значень, що точно відповідають годинам (6:00, 12:00, 18:00, 24:00)
                  if (value == 0 ||
                      value == 6 ||
                      value == 12 ||
                      value == 18 ||
                      value == 24) {
                    String text;
                    if (value == 0) {
                      text = '00:00';
                    } else if (value == 24) {
                      text = '24:00';
                    } else {
                      text = '${value.toInt()}:00';
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(text, style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  // Підписи для осі Y
                  if (value == 5 ||
                      value == 10 ||
                      value == 15 ||
                      value == 3.9) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        value == 3.9 ? '3.9' : '${value.toInt()}',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              (value == 3.9)
                                  ? Colors.red[300]
                                  : Colors.grey[600],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          // Виділення цільової зони (3.9-10.0) сірим фоном
          rangeAnnotations: RangeAnnotations(
            verticalRangeAnnotations: [],
            horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                y1: 3.9,
                y2: 10.0,
                color: Colors.grey.withOpacity(0.1),
              ),
            ],
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          minX: 0,
          maxX: 24,
          minY: 2,
          maxY: 18,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
              tooltipMargin: 8,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              // Додаємо спеціальні маркери для точок
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final hour = spot.x.toInt();
                  final minute = ((spot.x - hour) * 60).toInt();
                  final formattedMinute =
                      (minute == 0) ? '00' : minute.toString().padLeft(2, '0');
                  return LineTooltipItem(
                    '${hour.toString().padLeft(2, '0')}:$formattedMinute - ${spot.y.toStringAsFixed(1)} mmol/L',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
            // Додаємо видимі точки при торканні
            getTouchedSpotIndicator: (
              LineChartBarData barData,
              List<int> spotIndexes,
            ) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: Colors.white,
                    strokeWidth: 2,
                    dashArray: [3, 3],
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
                );
              }).toList();
            },
            // Переконуємося, що точки видимі при торканні
            touchSpotThreshold: 20, // Збільшуємо зону дотику
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4, // Збільшуємо плавність лінії
              color: Theme.of(context).colorScheme.primary.withOpacity(
                0.8,
              ), // Тепер будемо малювати і контур
              barWidth: 1.5, // Тонка лінія для кращої візуалізації
              isStrokeCapRound: true,
              dotData: const FlDotData(
                show: false,
              ), // Не показуємо точки постійно
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.5), // Напівпрозора заливка
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0), // зменшено з 16.0
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // додати цей рядок
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16.0),
              const SizedBox(width: 4.0), // зменшено з 8.0
              Expanded(
                // обгорнути текст у Expanded
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.0,
                    color: Colors.grey[600],
                  ), // зменшено розмір
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(), // додати для вирівнювання
          Text(
            value,
            style: TextStyle(
              fontSize: 16.0, // зменшено з 18.0
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(String patternType) {
    switch (patternType) {
      case 'nighttime_highs':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text('• Consider adjusting basal insulin before bedtime'),
            Text('• Review evening meal timing and composition'),
            Text('• Check for late evening snacks without insulin coverage'),
          ],
        );
      case 'postprandial_highs':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text('• Consider pre-bolusing insulin 15-20 minutes before meals'),
            Text('• Review carb counting accuracy'),
            Text('• Consider adjusting insulin-to-carb ratios'),
          ],
        );
      case 'morning_lows':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text('• Consider reducing overnight basal insulin'),
            Text('• Avoid exercise before bedtime'),
            Text('• Consider having a small protein snack before bed'),
          ],
        );
      case 'best_day':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Great job!', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.0),
            Text('Review what worked well on this day:'),
            Text('• Meal timing and composition'),
            Text('• Activity levels'),
            Text('• Insulin timing and doses'),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDailyPatternChart() {
    if (_glucoseData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Групуємо дані по годинах, щоб отримати середнє значення для кожної години дня
    final Map<int, List<double>> hourlyData = {};

    for (var reading in _glucoseData) {
      final hour = reading.timestamp.hour;

      if (!hourlyData.containsKey(hour)) {
        hourlyData[hour] = [];
      }

      hourlyData[hour]!.add(reading.mmolL);
    }

    // Обчислюємо середнє значення для кожної години
    final List<FlSpot> averageSpots = [];

    for (int hour = 0; hour < 24; hour++) {
      if (hourlyData.containsKey(hour) && hourlyData[hour]!.isNotEmpty) {
        final values = hourlyData[hour]!;
        final average = values.reduce((a, b) => a + b) / values.length;

        // Округляємо до десятих для кращої читабельності
        final roundedAverage = (average * 10).round() / 10;
        averageSpots.add(FlSpot(hour.toDouble(), roundedAverage));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
              dashArray: value == 3.9 || value == 10.0 ? [5, 5] : null,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey[300], strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 4,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                String text = '';

                if (hour == 0) {
                  text = '12 AM';
                } else if (hour == 12) {
                  text = '12 PM';
                } else if (hour < 12) {
                  text = '$hour AM';
                } else {
                  text = '${hour - 12} PM';
                }

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(text, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: 23,
        minY: 2,
        maxY: 18,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} mmol/L',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 3.9,
              color: Colors.red.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(color: Colors.red[300], fontSize: 10),
                labelResolver: (line) => '3.9',
              ),
            ),
            HorizontalLine(
              y: 10.0,
              color: Colors.red.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(color: Colors.red[300], fontSize: 10),
                labelResolver: (line) => '10.0',
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: averageSpots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAGPChart() {
    if (_agpPercentiles.isEmpty) {
      return const Center(child: Text('No data available for AGP'));
    }

    // Створюємо дані для графіка
    final List<LineChartBarData> barData = [];

    // Дані для 5% і 95% перцентилів (найсвітліша заливка)
    final List<FlSpot> spots5 = [];
    final List<FlSpot> spots95 = [];

    // Дані для 25% і 75% перцентилів (середня заливка)
    final List<FlSpot> spots25 = [];
    final List<FlSpot> spots75 = [];

    // Дані для 50% перцентиля (медіана - лінія)
    final List<FlSpot> spots50 = [];

    for (int i = 0; i < _agpPercentiles.length; i++) {
      final timePoint = i / 2; // перетворюємо індекс у години (0-23.5)

      // Округляємо значення до десятих для кращої читабельності
      final p5 = (_agpPercentiles[i][0] * 10).round() / 10;
      final p25 = (_agpPercentiles[i][1] * 10).round() / 10;
      final p50 = (_agpPercentiles[i][2] * 10).round() / 10;
      final p75 = (_agpPercentiles[i][3] * 10).round() / 10;
      final p95 = (_agpPercentiles[i][4] * 10).round() / 10;

      spots5.add(FlSpot(timePoint, p5));
      spots25.add(FlSpot(timePoint, p25));
      spots50.add(FlSpot(timePoint, p50));
      spots75.add(FlSpot(timePoint, p75));
      spots95.add(FlSpot(timePoint, p95));
    }

    // Додаємо області між перцентилями (спочатку 5-95%, потім 25-75%)
    // 5-95% (найсвітліша область)
    barData.add(
      LineChartBarData(
        spots: spots5,
        isCurved: true,
        color: Colors.blue[100],
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue[50]!.withOpacity(0.3),
        ),
      ),
    );

    barData.add(
      LineChartBarData(
        spots: spots95,
        isCurved: true,
        color: Colors.blue[100],
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: Colors.transparent),
      ),
    );

    // 25-75% (основна область)
    barData.add(
      LineChartBarData(
        spots: spots25,
        isCurved: true,
        color: Colors.blue[300],
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue[100]!.withOpacity(0.5),
        ),
      ),
    );

    barData.add(
      LineChartBarData(
        spots: spots75,
        isCurved: true,
        color: Colors.blue[300],
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: Colors.transparent),
      ),
    );

    // Додаємо лінію 50-го перцентиля (медіана) останньою, щоб вона була зверху
    barData.add(
      LineChartBarData(
        spots: spots50,
        isCurved: true,
        color: Colors.black,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
    );

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
              dashArray: value == 3.9 || value == 10.0 ? [5, 5] : null,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey[300], strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 4,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                String text = '';

                if (hour == 0) {
                  text = '12 AM';
                } else if (hour == 12) {
                  text = '12 PM';
                } else if (hour < 12) {
                  text = '$hour AM';
                } else {
                  text = '${hour - 12} PM';
                }

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(text, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: 24,
        minY: 2,
        maxY: 18,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              // Показувати тільки значення для медіани (останньої лінії в списку)
              final medianSpot = touchedSpots.firstWhere(
                (spot) => spot.barIndex == barData.length - 1,
                orElse: () => touchedSpots.first,
              );

              return [
                LineTooltipItem(
                  '${medianSpot.y.toStringAsFixed(1)} mmol/L',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ];
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 3.9,
              color: Colors.red.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(color: Colors.red[300], fontSize: 10),
                labelResolver: (line) => '3.9',
              ),
            ),
            HorizontalLine(
              y: 10.0,
              color: Colors.red.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(color: Colors.red[300], fontSize: 10),
                labelResolver: (line) => '10.0',
              ),
            ),
          ],
        ),
        lineBarsData: barData,
      ),
    );
  }

  Color _getAverageColor(double average) {
    if (average < 3.9) {
      return Colors.red;
    } else if (average > 10.0) {
      return Colors.orange;
    } else if (average > 8.5) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  Color _getA1cColor(double a1c) {
    if (a1c < 6.5) {
      return Colors.green;
    } else if (a1c < 7.0) {
      return Colors.lightGreen;
    } else if (a1c < 7.5) {
      return Colors.amber;
    } else if (a1c < 8.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getStdDevColor(double stdDev) {
    if (stdDev < 2.0) {
      return Colors.green;
    } else if (stdDev < 3.0) {
      return Colors.lightGreen;
    } else if (stdDev < 4.0) {
      return Colors.amber;
    } else {
      return Colors.orange;
    }
  }

  Color _getCVColor(double cv) {
    if (cv < 30) {
      return Colors.green;
    } else if (cv < 36) {
      return Colors.lightGreen;
    } else if (cv < 42) {
      return Colors.amber;
    } else if (cv < 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getPatternIcon(String patternType) {
    switch (patternType) {
      case 'nighttime_highs':
        return Icons.nights_stay;
      case 'postprandial_highs':
        return Icons.restaurant;
      case 'morning_lows':
        return Icons.wb_sunny;
      case 'best_day':
        return Icons.star;
      default:
        return Icons.bar_chart;
    }
  }

  Color _getPatternColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.amber;
      case 'positive':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}

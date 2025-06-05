import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/core/l10n/app_localizations.dart';
import 'package:glucose_companion/core/utils/glucose_converter.dart';
import 'package:glucose_companion/data/models/glucose_chart_data.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_bloc.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_state.dart';
import 'package:glucose_companion/presentation/bloc/prediction/prediction_bloc.dart';
import 'package:glucose_companion/presentation/bloc/prediction/prediction_state.dart';
import 'package:intl/intl.dart';

class GlucoseChart extends StatelessWidget {
  final GlucoseChartData data;
  final double lowThreshold;
  final double highThreshold;

  const GlucoseChart({
    Key? key,
    required this.data,
    this.lowThreshold = 3.9,
    this.highThreshold = 10.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.spots.isEmpty) {
      return Center(child: Text(AppLocalizations.noDataAvailable));
    }

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final useMMOL =
            state is SettingsLoaded
                ? state.settings.glucoseUnits == 'mmol_L'
                : true;

        return BlocBuilder<PredictionBloc, PredictionState>(
          builder: (context, predictionState) {
            // Створюємо копію оригінальних точок
            List<FlSpot> historySpots = List.from(data.spots);
            List<FlSpot> predictionSpots = [];

            // Додаємо прогнозну точку, якщо є прогноз
            if (predictionState is PredictionLoaded) {
              final predictionValue =
                  useMMOL
                      ? predictionState.predictedValue
                      : GlucoseConverter.mmolToMgdl(
                        predictionState.predictedValue,
                      );

              // Прогноз на +60 хвилин від поточного моменту
              predictionSpots = [
                FlSpot(0, historySpots.last.y), // Поточна точка
                FlSpot(60, predictionValue), // Прогноз через годину
              ];
            }

            return Column(
              children: [
                // Легенда
                _buildLegend(context),
                const SizedBox(height: 8),

                // Основний графік
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: useMMOL ? 1 : 20,
                        verticalInterval: 30,
                        getDrawingHorizontalLine: (value) {
                          final checkValue =
                              useMMOL
                                  ? value
                                  : GlucoseConverter.mgdlToMmol(value);
                          return FlLine(
                            color:
                                (useMMOL &&
                                            (value == lowThreshold ||
                                                value == highThreshold)) ||
                                        (!useMMOL &&
                                            (checkValue == lowThreshold ||
                                                checkValue == highThreshold))
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                            strokeWidth:
                                (useMMOL &&
                                            (value == lowThreshold ||
                                                value == highThreshold)) ||
                                        (!useMMOL &&
                                            (checkValue == lowThreshold ||
                                                checkValue == highThreshold))
                                    ? 2
                                    : 1,
                            dashArray:
                                (useMMOL &&
                                            (value == lowThreshold ||
                                                value == highThreshold)) ||
                                        (!useMMOL &&
                                            (checkValue == lowThreshold ||
                                                checkValue == highThreshold))
                                    ? [5, 5]
                                    : null,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          // Вертикальна лінія для поділу історії та прогнозу
                          if (value == 0) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.5),
                              strokeWidth: 2,
                              dashArray: [5, 5],
                            );
                          }
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
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
                            interval: 60,
                            getTitlesWidget:
                                (value, meta) =>
                                    bottomTitleWidgets(value, meta),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: useMMOL ? 1 : 20,
                            getTitlesWidget:
                                (value, meta) =>
                                    leftTitleWidgets(value, meta, useMMOL),
                            reservedSize: 50,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: const Color(0xff37434d),
                          width: 1,
                        ),
                      ),
                      minX: -180, // 3 години назад
                      maxX: 60, // 1 година вперед
                      minY:
                          useMMOL
                              ? data.minY
                              : GlucoseConverter.mmolToMgdl(data.minY),
                      maxY:
                          useMMOL
                              ? data.maxY
                              : GlucoseConverter.mmolToMgdl(data.maxY),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final flSpot = barSpot;
                              String valueText;
                              if (useMMOL) {
                                valueText = flSpot.y.toStringAsFixed(1);
                              } else {
                                final mgdlValue =
                                    useMMOL
                                        ? GlucoseConverter.mmolToMgdl(flSpot.y)
                                        : flSpot.y;
                                valueText = mgdlValue.round().toString();
                              }

                              // Визначаємо тип точки
                              String typeText =
                                  flSpot.x <= 0 ? 'Історія' : 'Прогноз';

                              return LineTooltipItem(
                                '$typeText\n$valueText ${GlucoseConverter.unitString(useMMOL)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                      ),
                      lineBarsData: _buildLineBarsData(
                        historySpots,
                        predictionSpots,
                        useMMOL,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(
            color: Colors.blue,
            label: AppLocalizations.get('history'),
            isLine: true,
          ),
          _buildLegendItem(
            color: Colors.purple,
            label: AppLocalizations.get('prediction'),
            isDashed: true,
          ),
          _buildLegendItem(
            color: Colors.red.withOpacity(0.5),
            label: AppLocalizations.get('threshold'),
            isDashed: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isLine = false,
    bool isDashed = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            border: isDashed ? Border.all(color: color, width: 1) : null,
          ),
          child:
              isDashed ? CustomPaint(painter: DashedLinePainter(color)) : null,
        ),
        const SizedBox(width: 8.0),
        Text(
          label,
          style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<LineChartBarData> _buildLineBarsData(
    List<FlSpot> historySpots,
    List<FlSpot> predictionSpots,
    bool useMMOL,
  ) {
    List<LineChartBarData> lineBars = [];

    // Лінія нижнього порогу
    final adjustedLowThreshold =
        useMMOL ? lowThreshold : GlucoseConverter.mmolToMgdl(lowThreshold);
    lineBars.add(
      LineChartBarData(
        spots: [
          FlSpot(-180, adjustedLowThreshold),
          FlSpot(60, adjustedLowThreshold),
        ],
        isCurved: false,
        color: Colors.red.withOpacity(0.5),
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        dashArray: [5, 5],
      ),
    );

    // Лінія верхнього порогу
    final adjustedHighThreshold =
        useMMOL ? highThreshold : GlucoseConverter.mmolToMgdl(highThreshold);
    lineBars.add(
      LineChartBarData(
        spots: [
          FlSpot(-180, adjustedHighThreshold),
          FlSpot(60, adjustedHighThreshold),
        ],
        isCurved: false,
        color: Colors.red.withOpacity(0.5),
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        dashArray: [5, 5],
      ),
    );

    // Історичні дані
    lineBars.add(
      LineChartBarData(
        spots:
            useMMOL
                ? historySpots
                : historySpots
                    .map(
                      (spot) =>
                          FlSpot(spot.x, GlucoseConverter.mmolToMgdl(spot.y)),
                    )
                    .toList(),
        isCurved: true,
        gradient: LinearGradient(
          colors: [Colors.cyan, Colors.blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            final mmolValue =
                useMMOL ? spot.y : GlucoseConverter.mgdlToMmol(spot.y);
            Color dotColor;
            if (mmolValue < lowThreshold) {
              dotColor = Colors.red;
            } else if (mmolValue > highThreshold) {
              dotColor = Colors.orange;
            } else {
              dotColor = Colors.blue;
            }

            return FlDotCirclePainter(
              radius: 4,
              color: dotColor,
              strokeWidth: 1,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              Colors.cyan.withOpacity(0.3),
              Colors.blue.withOpacity(0.1),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );

    // Прогнозні дані
    if (predictionSpots.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: predictionSpots,
          isCurved: false,
          color: Colors.purple,
          barWidth: 3,
          isStrokeCapRound: true,
          dashArray: [8, 4],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 5,
                color: Colors.purple,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return lineBars;
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    String text;
    if (value == 0) {
      text = 'Зараз';
    } else if (value > 0) {
      // Майбутнє
      final hours = (value / 60).floor();
      final minutes = (value % 60).floor();
      if (hours > 0) {
        text = '+${hours}г${minutes > 0 ? '${minutes}хв' : ''}';
      } else {
        text = '+${minutes}хв';
      }
    } else {
      // Минуле
      final hours = (value.abs() / 60).floor();
      final minutes = (value.abs() % 60).floor();
      if (hours > 0) {
        text = '-${hours}г${minutes > 0 ? '${minutes}хв' : ''}';
      } else {
        text = '-${minutes}хв';
      }
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta, bool useMMOL) {
    const style = TextStyle(
      color: Color(0xff67727d),
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    String text;
    if (useMMOL) {
      text = value.toStringAsFixed(1);
    } else {
      text = value.round().toString();
    }

    return Text(text, style: style, textAlign: TextAlign.center);
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

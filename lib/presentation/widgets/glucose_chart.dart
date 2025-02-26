import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/core/utils/glucose_converter.dart';
import 'package:glucose_companion/data/models/glucose_chart_data.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_bloc.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_state.dart';
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
      return const Center(child: Text('No glucose data available'));
    }

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final useMMOL =
            state is SettingsLoaded
                ? state.settings.glucoseUnits == 'mmol_L'
                : true;

        // Конвертація порогових значень якщо потрібно
        final adjustedLowThreshold =
            useMMOL ? lowThreshold : GlucoseConverter.mmolToMgdl(lowThreshold);
        final adjustedHighThreshold =
            useMMOL
                ? highThreshold
                : GlucoseConverter.mmolToMgdl(highThreshold);

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: useMMOL ? 1 : 20,
              verticalInterval: 30,
              getDrawingHorizontalLine: (value) {
                final checkValue =
                    useMMOL ? value : GlucoseConverter.mgdlToMmol(value);
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
                  getTitlesWidget: bottomTitleWidgets,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: useMMOL ? 1 : 20,
                  getTitlesWidget:
                      (value, meta) => leftTitleWidgets(value, meta, useMMOL),
                  reservedSize: 40,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1),
            ),
            minX: data.minX,
            maxX: data.maxX,
            minY: useMMOL ? data.minY : GlucoseConverter.mmolToMgdl(data.minY),
            maxY: useMMOL ? data.maxY : GlucoseConverter.mmolToMgdl(data.maxY),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                tooltipRoundedRadius: 8,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final flSpot = barSpot;
                    // Форматуємо значення відповідно до одиниць
                    String valueText;
                    if (useMMOL) {
                      valueText = flSpot.y.toStringAsFixed(1);
                    } else {
                      // Для mg/dL конвертуємо з mmol/L (що ми зберігаємо в даних)
                      final mgdlValue = GlucoseConverter.mmolToMgdl(flSpot.y);
                      valueText = mgdlValue.round().toString();
                    }
                    return LineTooltipItem(
                      '$valueText ${GlucoseConverter.unitString(useMMOL)}',
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
            lineBarsData: [
              LineChartBarData(
                spots:
                    useMMOL
                        ? data.spots
                        : data.spots
                            .map(
                              (spot) => FlSpot(
                                spot.x,
                                GlucoseConverter.mmolToMgdl(spot.y),
                              ),
                            )
                            .toList(),
                isCurved: true,
                gradient: LinearGradient(
                  colors: data.gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    // Перевіряємо значення в mmol/L для визначення кольору
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
                    colors:
                        data.gradientColors
                            .map((color) => color.withOpacity(0.3))
                            .toList(),
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              // Лінія нижнього порогу
              LineChartBarData(
                spots: [
                  FlSpot(data.minX, adjustedLowThreshold),
                  FlSpot(data.maxX, adjustedLowThreshold),
                ],
                isCurved: false,
                color: Colors.red.withOpacity(0.5),
                barWidth: 1,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
                dashArray: [5, 5],
              ),
              // Лінія верхнього порогу
              LineChartBarData(
                spots: [
                  FlSpot(data.minX, adjustedHighThreshold),
                  FlSpot(data.maxX, adjustedHighThreshold),
                ],
                isCurved: false,
                color: Colors.red.withOpacity(0.5),
                barWidth: 1,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
                dashArray: [5, 5],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    // Відображаємо час (зміщення від поточного часу)
    String text;
    if (value == 0) {
      text = 'Now';
    } else {
      // Конвертуємо хвилини в години
      final hours = (value.abs() / 60).floor();
      final minutes = (value.abs() % 60).floor();

      if (hours > 0) {
        text = '-${hours}h${minutes > 0 ? '${minutes}m' : ''}';
      } else {
        text = '-${minutes}m';
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

    // Форматуємо залежно від одиниць вимірювання
    String text;
    if (useMMOL) {
      text = value.toStringAsFixed(1);
    } else {
      text = value.round().toString();
    }

    return Text(text, style: style, textAlign: TextAlign.center);
  }
}

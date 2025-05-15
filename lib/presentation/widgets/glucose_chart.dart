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
                // Додаємо вертикальну пунктирну лінію для позначення теперішнього часу
                if (value == 0) {
                  return FlLine(
                    color: Colors.red.withOpacity(0.5),
                    strokeWidth: 1,
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

                    // Визначаємо, чи це прогнозована точка
                    final isPredicted = barSpot.barIndex == 1;

                    return LineTooltipItem(
                      '${valueText} ${GlucoseConverter.unitString(useMMOL)} ${isPredicted ? '(Predicted)' : ''}',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            isPredicted ? FontStyle.italic : FontStyle.normal,
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
                  colors: data.historyGradientColors,
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
                        data.historyGradientColors
                            .map((color) => color.withOpacity(0.3))
                            .toList(),
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),

              // Лінія прогнозу (якщо є)
              if (data.predictionSpots.isNotEmpty)
                LineChartBarData(
                  spots:
                      useMMOL
                          ? data.predictionSpots
                          : data.predictionSpots
                              .map(
                                (spot) => FlSpot(
                                  spot.x,
                                  GlucoseConverter.mmolToMgdl(spot.y),
                                ),
                              )
                              .toList(),
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: data.predictionGradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      // Визначаємо колір для точок прогнозу
                      final mmolValue =
                          useMMOL
                              ? spot.y
                              : GlucoseConverter.mgdlToMmol(spot.y);
                      Color dotColor;
                      if (mmolValue < lowThreshold) {
                        dotColor = Colors.red;
                      } else if (mmolValue > highThreshold) {
                        dotColor = Colors.orange;
                      } else {
                        dotColor = Colors.purple;
                      }

                      // Показуємо лише останню точку (прогноз)
                      if (index == data.predictionSpots.length - 1) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: dotColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      } else {
                        // Для проміжних точок не показуємо крапки
                        return FlDotCirclePainter(
                          radius: 0,
                          color: Colors.transparent,
                          strokeWidth: 0,
                          strokeColor: Colors.transparent,
                        );
                      }
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors:
                          data.predictionGradientColors
                              .map((color) => color.withOpacity(0.3))
                              .toList(),
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  dashArray: null,
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
    } else if (value > 0) {
      // Майбутній час (прогноз)
      final hours = (value / 60).floor();
      final minutes = (value % 60).floor();

      if (hours > 0) {
        text = '+${hours}h${minutes > 0 ? '${minutes}m' : ''}';
      } else {
        text = '+${minutes}m';
      }
    } else {
      // Минулий час (історія)
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

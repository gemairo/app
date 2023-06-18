import 'package:flutter/material.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:silvio/hive/extentions.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LineChartGrades extends StatelessWidget {
  const LineChartGrades(
      {super.key, required this.grades, this.showAverage = false});

  final List<Grade> grades;
  final bool showAverage;
  @override
  Widget build(BuildContext context) {
    List<Grade> useablegrades = grades.numericalGrades.reversed.toList();
    final List<FlSpot> gradeData = List.generate(useablegrades.length, (index) {
      return FlSpot(index.toDouble(), useablegrades[index].grade);
    });
    final List<FlSpot> averageGradeData = showAverage
        ? List.generate(useablegrades.length, (index) {
            return FlSpot(index.toDouble(),
                useablegrades.take(index + 1).toList().average);
          })
        : [];
    return LayoutBuilder(
        builder: (context, constraints) => SizedBox(
            height: 250 - 16,
            child: LineChart(
              swapAnimationDuration: const Duration(milliseconds: 150),
              swapAnimationCurve: Curves.linear,
              LineChartData(
                borderData: FlBorderData(
                  show: false,
                  border: Border.all(color: const Color(0xff37434d)),
                ),
                maxY: 10,
                minY: 1,
                gridData: FlGridData(drawVerticalLine: false),
                clipData: FlClipData.none(),
                lineBarsData: [
                  LineChartBarData(
                    spots: gradeData,
                    isCurved: true,
                    isStrokeCapRound: true,
                    barWidth: 3,
                    preventCurveOverShooting: true,
                    color: (constraints.maxWidth / 3) / useablegrades.length < 1
                        ? Colors.transparent
                        : Theme.of(context).colorScheme.primary,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.20),
                    ),
                  ),
                  if (showAverage)
                    LineChartBarData(
                      spots: averageGradeData,
                      isCurved: true,
                      isStrokeCapRound: true,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: false,
                      ),
                      color:
                          (constraints.maxWidth / 3) / useablegrades.length < 1
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.inversePrimary,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .inversePrimary
                            .withOpacity(0.20),
                      ),
                    ),
                ],
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (value) {
                          value.sort(
                            (a, b) => a.bar.dotData.show
                                .toString()
                                .length
                                .compareTo(
                                    b.bar.dotData.show.toString().length),
                          );
                          return [
                            LineTooltipItem(
                                textAlign: TextAlign.start,
                                DateFormat.yMMMd('nl').format(useablegrades
                                    .toList()[value.first.x.toInt()]
                                    .addedDate
                                    .toLocal()),
                                TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                    fontWeight: FontWeight.bold,
                                    height: 1.5),
                                children: value
                                    .map((e) => TextSpan(
                                        text:
                                            "${!e.bar.dotData.show ? '\n${AppLocalizations.of(context)!.average}:' : '\n${AppLocalizations.of(context)!.grade}:'} ${e.y.displayNumber(decimalDigits: 2)}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.normal,
                                            height: 1.25)))
                                    .toList()),
                            LineTooltipItem("", const TextStyle(height: 0))
                          ];
                        },
                        fitInsideHorizontally: true,
                        tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        tooltipRoundedRadius: 4,
                        tooltipBorder: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1),
                        tooltipBgColor: Theme.of(context)
                            .colorScheme
                            .background
                            .withOpacity(1.00))),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: config.sufficientFrom,
                      color: Theme.of(context).colorScheme.error,
                      strokeWidth: 3,
                      dashArray: [20, 10],
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Text(
                        !(value > 9 || value < 2)
                            ? value.toInt().toString()
                            : "",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            )));
  }
}

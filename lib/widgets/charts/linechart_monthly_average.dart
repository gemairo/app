import 'package:flutter/material.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gemairo/hive/extentions.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MonthlyLineChartGrades extends StatelessWidget {
  const MonthlyLineChartGrades(
      {super.key, required this.grades, this.showAverage = false});

  final List<Grade> grades;
  final bool showAverage;
  @override
  Widget build(BuildContext context) {
    List<Grade> useablegrades = grades.numericalGrades.reversed.toList();

    List<DateTime> months = useablegrades
        .map(
            (g) => DateTime.parse(DateFormat('yyyy-MM-01').format(g.addedDate)))
        .toList()
        .unique();

    Map<DateTimeRange, List<Grade>> gradesPerMonth = {
      for (var month in months)
        DateTimeRange(
            start: month,
            end:
                DateTime(month.year, month.month + 1, month.day)): useablegrades
            .where((g) =>
                g.addedDate.isAfter(month) &&
                g.addedDate
                    .isBefore(DateTime(month.year, month.month + 1, month.day)))
            .toList()
    };

    Map<DateTimeRange, double> averagePerMonth = {
      for (var month in months)
        DateTimeRange(
                start: month,
                end: DateTime(month.year, month.month + 1, month.day)):
            useablegrades
                .where((g) => g.addedDate
                    .isBefore(DateTime(month.year, month.month + 1, month.day)))
                .toList()
                .average
    };

    final List<FlSpot> gradeData =
        List.generate(gradesPerMonth.length, (index) {
      return FlSpot(
          index.toDouble(), gradesPerMonth.values.toList()[index].average);
    });
    final List<FlSpot> averageGradeData = showAverage
        ? List.generate(averagePerMonth.length, (index) {
            return FlSpot(
                index.toDouble(), averagePerMonth.values.toList()[index]);
          })
        : [];
    return SizedBox(
        height: 250 - 56,
        child: LineChart(
          duration: const Duration(milliseconds: 150),
          curve: Curves.linear,
          LineChartData(
            borderData: FlBorderData(
              show: false,
              border: Border.all(color: const Color(0xff37434d)),
            ),
            maxY: 10,
            minY: 1,
            gridData: const FlGridData(drawVerticalLine: false),
            clipData: const FlClipData.none(),
            lineBarsData: [
              LineChartBarData(
                spots: gradeData,
                isCurved: true,
                isStrokeCapRound: true,
                barWidth: 3,
                preventCurveOverShooting: true,
                color: Theme.of(context).colorScheme.primary,
                belowBarData: BarAreaData(
                  show: true,
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.20),
                ),
              ),
              if (showAverage)
                LineChartBarData(
                  spots: averageGradeData,
                  isCurved: true,
                  isStrokeCapRound: true,
                  barWidth: 3,
                  dotData: const FlDotData(
                    show: false,
                  ),
                  color: Theme.of(context).colorScheme.inversePrimary,
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
                            .compareTo(b.bar.dotData.show.toString().length),
                      );
                      return [
                        LineTooltipItem(
                            textAlign: TextAlign.start,
                            "${DateFormat.yMMMM('nl').format(gradesPerMonth.keys.toList()[value.first.x.toInt()].start.toLocal())} (${gradesPerMonth.values.toList()[value.first.x.toInt()].length})",
                            TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurface,
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
                        if (showAverage)
                          const LineTooltipItem("", TextStyle(height: 0))
                      ];
                    },
                    fitInsideHorizontally: true,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tooltipRoundedRadius: 4,
                    tooltipBorder: BorderSide(
                        color: Theme.of(context).colorScheme.outline, width: 1),
                    getTooltipColor: (line) => Theme.of(context)
                        .colorScheme
                        .surface
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
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  interval: 1,
                  getTitlesWidget: (value, meta) => Text(
                    !(value > 9 || value < 2) ? value.toInt().toString() : "",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          ),
        ));
  }
}

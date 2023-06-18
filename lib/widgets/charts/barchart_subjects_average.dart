import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';

class BarChartSubjectsAverage extends StatelessWidget {
  const BarChartSubjectsAverage(
      {super.key, required this.subjects, this.rounded = false});

  final List<Subject> subjects;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barData = [];
    subjects.asMap().forEach((index, Subject subject) {
      double average = rounded
          ? subject.grades.average.round().toDouble()
          : subject.grades.average;
      barData.add(BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
              toY: average,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              width: 16,
              color: (average < config.sufficientFrom)
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              rodStackItems: [
                ...List.generate(
                    10,
                    (index) => BarChartRodStackItem(
                        index.toDouble(),
                        index + 1,
                        index.isOdd
                            ? (average < config.sufficientFrom)
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(context).colorScheme.inversePrimary
                            : (average < config.sufficientFrom)
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary)),
              ])
        ],
        showingTooltipIndicators: [],
      ));
    });
    return SizedBox(
        height: 175,
        child: BarChart(
            swapAnimationDuration: const Duration(milliseconds: 150),
            swapAnimationCurve: Curves.linear,
            BarChartData(
              maxY: 10,
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                    y: config.sufficientFrom,
                    color: Theme.of(context).colorScheme.error,
                    strokeWidth: 3,
                    dashArray: [20, 10])
              ]),
              barTouchData: BarTouchData(
                touchCallback: (p0, p1) {},
                touchTooltipData: BarTouchTooltipData(
                    tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                    tooltipMargin: 5,
                    fitInsideHorizontally: true,
                    // fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${subjects[group.x].name}: ',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                              text: (rounded ? rod.toY.round() : rod.toY)
                                  .toDouble()
                                  .displayNumber()),
                        ],
                      );
                    },
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    tooltipRoundedRadius: 4,
                    tooltipBorder: BorderSide(
                        color: Theme.of(context).colorScheme.outline, width: 1),
                    tooltipBgColor: Theme.of(context).colorScheme.background),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        child: Text(subjects[value.toInt()].code),
                      );
                    },
                    reservedSize: 24,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 25,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(
                            value.toInt().toString(),
                            maxLines: 1,
                          ));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              barGroups: barData,
              gridData: FlGridData(
                  show: true, horizontalInterval: 2, verticalInterval: 1),
            )));
  }
}

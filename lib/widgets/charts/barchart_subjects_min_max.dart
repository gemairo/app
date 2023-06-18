import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';

class BarChartSubjectsMinMax extends StatelessWidget {
  const BarChartSubjectsMinMax({super.key, required this.subjects});

  final List<Subject> subjects;

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barData = [];
    List<Subject> useableSubjects = subjects
        .where((subject) =>
            subject.grades.getHighest() != null &&
            subject.grades.getHighest() != subject.grades.getLowest())
        .toList();

    useableSubjects.asMap().forEach((index, Subject subject) {
      barData.add(BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
              toY: subject.grades.getHighest()!.grade,
              fromY: subject.grades.getLowest()!.grade,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              width: 16,
              color: Theme.of(context).colorScheme.primary,
              rodStackItems: [
                BarChartRodStackItem(
                    subject.grades.median - .1,
                    subject.grades.median + .1,
                    Theme.of(context).colorScheme.inversePrimary),
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
              minY: (useableSubjects
                          .expand((subject) => subject.grades)
                          .toList()
                          .getLowest()
                          ?.grade ??
                      2) -
                  1,
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
                    tooltipHorizontalAlignment: FLHorizontalAlignment.left,
                    tooltipMargin: 5,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      TextStyle itemTextStyle =
                          const TextStyle(fontWeight: FontWeight.normal);
                      return BarTooltipItem(
                        textAlign: TextAlign.left,
                        '${useableSubjects[group.x].name}\n',
                        TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontWeight: FontWeight.bold),
                        children: <TextSpan>[
                          TextSpan(
                              text: "max: ${rod.toY.displayNumber()}\n",
                              style: itemTextStyle),
                          TextSpan(
                              text:
                                  "med: ${useableSubjects[group.x].grades.median.displayNumber()}\n",
                              style: itemTextStyle),
                          TextSpan(
                              text: "min: ${rod.fromY.displayNumber()}",
                              style: itemTextStyle),
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
                        child: Text(useableSubjects[value.toInt()].code),
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
                  show: true, horizontalInterval: 1, verticalInterval: 1),
            )));
  }
}

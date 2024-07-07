import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BarChartSubjectsWeight extends StatelessWidget {
  const BarChartSubjectsWeight({super.key, required this.subjects});

  final List<Subject> subjects;

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barData = [];
    subjects.asMap().forEach((index, Subject subject) {
      barData.add(BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: subject.grades.map((grade) => grade.weight).sum /
                subject.grades.length,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            width: 16,
            color: Theme.of(context).colorScheme.primary,
          )
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
              barTouchData: BarTouchData(
                touchCallback: (p0, p1) {},
                touchTooltipData: BarTouchTooltipData(
                  tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                  tooltipMargin: 5,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    TextStyle itemTextStyle =
                        const TextStyle(fontWeight: FontWeight.normal);
                    return BarTooltipItem(
                      textAlign: TextAlign.left,
                      '${subjects[group.x].name}\n',
                      TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                      children: <TextSpan>[
                        TextSpan(
                            text: AppLocalizations.of(context)!
                                .totalWeight(rod.toY),
                            style: itemTextStyle),
                      ],
                    );
                  },
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  tooltipRoundedRadius: 4,
                  tooltipBorder: BorderSide(
                      color: Theme.of(context).colorScheme.outline, width: 1),
                  getTooltipColor: (line) =>
                      Theme.of(context).colorScheme.surface,
                ),
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
              gridData: const FlGridData(show: true, verticalInterval: 1),
            )));
  }
}

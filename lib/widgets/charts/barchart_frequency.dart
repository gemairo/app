import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';

class BarChartFrequency extends StatefulWidget {
  const BarChartFrequency({super.key, required this.grades});

  final List<Grade> grades;

  @override
  State<StatefulWidget> createState() => _BarChartFrequency();
}

class _BarChartFrequency extends State<BarChartFrequency> {
  bool showPattern = false;
  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barData = [];
    for (var i in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
      barData.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              borderRadius: showPattern
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(4), topRight: Radius.circular(4))
                  : null,
              width: showPattern ? 15 : 8,
              toY: widget.grades.getGradeFrequency()[i] ?? 0,
              color: Theme.of(context).colorScheme.primary,
              rodStackItems: List.generate(
                widget.grades
                    .getGradeFrequency()
                    .values
                    .reduce((curr, next) => curr > next ? curr : next)
                    .toInt(),
                (index) => BarChartRodStackItem(
                    index.toDouble(),
                    index + 1,
                    index.isOdd && showPattern
                        ? (i > config.sufficientFrom)
                            ? Theme.of(context).colorScheme.inversePrimary
                            : Theme.of(context).colorScheme.errorContainer
                        : i > config.sufficientFrom
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error),
              ),
              backDrawRodData: showPattern
                  ? null
                  : BackgroundBarChartRodData(
                      show: true,
                      toY: widget.grades
                          .getGradeFrequency()
                          .values
                          .reduce((curr, next) => curr > next ? curr : next),
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),
            )
          ],
          showingTooltipIndicators: showPattern ? [0] : [],
        ),
      );
    }
    return SizedBox(
      height: 250 - 64,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (value) => setState(() {
          showPattern = true;
        }),
        onPointerUp: (value) => setState(() {
          showPattern = false;
        }),
        child: BarChart(
          swapAnimationDuration: const Duration(milliseconds: 150),
          swapAnimationCurve: Curves.linear,
          BarChartData(
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipHorizontalAlignment: showPattern
                    ? FLHorizontalAlignment.center
                    : FLHorizontalAlignment.right,
                tooltipMargin: showPattern ? 5 : -10,
                fitInsideHorizontally: true,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return rod.toY > 0
                      ? BarTooltipItem(
                          (rod.toY).toInt().toString(),
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        )
                      : null;
                },
                tooltipPadding: showPattern
                    ? const EdgeInsets.symmetric(horizontal: 4, vertical: 0)
                    : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      child: Text(value.toInt().toString()),
                    );
                  },
                  reservedSize: 20,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: showPattern,
                  reservedSize: 25,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: Text(
                        value.toInt().toString(),
                        maxLines: 1,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            barGroups: barData,
            gridData: FlGridData(show: showPattern),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';

class GradeCalculate extends StatefulWidget {
  const GradeCalculate(
      {super.key,
      required context,
      required this.grades,
      required this.calcNewAverage,
      this.preFillWeight});

  final List<Grade> grades;
  final bool calcNewAverage;
  final double? preFillWeight;

  @override
  State<GradeCalculate> createState() => _GradeCalculate();
}

class _GradeCalculate extends State<GradeCalculate> {
  final gradeController = TextEditingController();
  final weightController = TextEditingController();
  final _formKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    if (widget.preFillWeight != null) {
      weightController.text = widget.preFillWeight!.displayNumber();
    }

    double result() {
      if (double.tryParse(gradeController.text.replaceAll(',', '.')) != null &&
          double.tryParse(weightController.text.replaceAll(',', '.')) != null) {
        if (widget.calcNewAverage) {
          return widget.grades.getNewAverage(
              double.parse(gradeController.text.replaceAll(',', '.')),
              double.parse(weightController.text.replaceAll(',', '.')));
        } else {
          return widget.grades.getNewGrade(
              double.parse(gradeController.text.replaceAll(',', '.')),
              double.parse(weightController.text.replaceAll(',', '.')));
        }
      } else {
        return double.nan;
      }
    }

    return Row(
      key: ValueKey<bool>(widget.calcNewAverage),
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
            flex: 2,
            child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: gradeController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: widget.calcNewAverage
                                ? AppLocalizations.of(context)!.grade
                                : AppLocalizations.of(context)!.average,
                            border: const OutlineInputBorder(),
                            filled: false,
                            isDense: true,
                          ),
                        )),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: weightController,
                          onSubmitted: (val) {
                            if (val != "" && gradeController.text != "") {
                              setState(() {});
                            }
                          },
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.weight,
                            border: const OutlineInputBorder(),
                            filled: false,
                            isDense: true,
                          ),
                        )),
                    FilledButton.icon(
                        onPressed: () {
                          if (gradeController.text != "" &&
                              weightController.text != "") {
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.calculate),
                        label: Text(AppLocalizations.of(context)!.calculate))
                  ],
                ))),
        Expanded(
            flex: 3,
            child: Center(
              key: ValueKey(widget.grades),
              child: result().isNaN
                  ? Icon(
                      Icons.query_stats,
                      size: 32,
                      color: Theme.of(context).colorScheme.surfaceTint,
                    )
                  : Text(result().displayNumber(decimalDigits: 2),
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: (result() < 0 || result() > 10)
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary)),
            ))
      ],
    );
  }
}

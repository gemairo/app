import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';

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
  bool showChange = false;

  @override
  Widget build(BuildContext context) {
    if (widget.preFillWeight != null && weightController.text == "") {
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
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
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          controller: weightController,
                          onSubmitted: (val) {
                            if (val != "" && gradeController.text != "") {
                              setState(() {});
                            }
                          },
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.weight,
                            hintText: widget.preFillWeight?.displayNumber(),
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
                        label: Text(AppLocalizations.of(context)!.calculate,
                            maxLines: 1, overflow: TextOverflow.ellipsis))
                  ],
                ))),
        Expanded(
            flex: 3,
            child: Center(
              key: ValueKey(widget.grades),
              child: result().isNaN
                  ? Icon(
                      const IconData(0xf201, fontFamily: "Gemairo"),
                      size: 32 * 0.8,
                      color: Theme.of(context).colorScheme.surfaceTint,
                    )
                  : InkWell(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(4.0)),
                      onTap: () => setState(() {
                        showChange = !showChange;
                      }),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showChange)
                            RotatedBox(
                                quarterTurns: (result() - widget.grades.average)
                                        .isNegative
                                    ? 1
                                    : 0,
                                child: Icon(
                                    color: (!showChange &&
                                                (result() < 0 ||
                                                    result() > 10) ||
                                            showChange &&
                                                (result() -
                                                        widget.grades.average)
                                                    .isNegative)
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context).colorScheme.primary,
                                    size: (32 *
                                        MediaQuery.of(context).textScaleFactor *
                                        1.2),
                                    Icons.arrow_outward)),
                          Text(
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: (!showChange &&
                                            (result() < 0 || result() > 10) ||
                                        showChange &&
                                            (result() - widget.grades.average)
                                                .isNegative)
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary),
                            showChange
                                ? (result() - widget.grades.average)
                                    .displayNumber(decimalDigits: 2)
                                : result().displayNumber(decimalDigits: 2),
                          ),
                        ],
                      ),
                    ),
            ))
      ],
    );
  }
}

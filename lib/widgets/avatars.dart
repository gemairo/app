import 'package:flutter/material.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';
import 'package:silvio/widgets/animations.dart';

class GradeAvatar extends StatelessWidget {
  const GradeAvatar(
      {super.key,
      required this.gradeString,
      this.isSufficient,
      this.decimalDigits});

  final String gradeString;
  final bool? isSufficient;
  final int? decimalDigits;

  @override
  Widget build(BuildContext context) {
    double? _grade = double.tryParse(gradeString.replaceAll(',', '.'));
    bool _isSufficient = _grade == null
        ? (isSufficient ?? true)
        : num.parse(_grade.toStringAsFixed(decimalDigits ?? 2)) >= config.sufficientFrom;

    String displayedGrade = _grade?.displayNumber(decimalDigits: decimalDigits) ?? gradeString;

    return ElasticAnimation(
      child: CircleAvatar(
          key: ValueKey<String>(displayedGrade),
          backgroundColor: !_isSufficient
              ? Theme.of(context).colorScheme.errorContainer
              : null,
          radius: 25,
          child: Text(
              displayedGrade,
              style: !_isSufficient
                  ? TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer)
                  : null)),
    );
  }
}

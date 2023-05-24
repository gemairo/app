import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:silvio/hive/adapters.dart';

import 'package:silvio/widgets/cards/list_grade.dart';
import 'package:silvio/widgets/cards/list_test.dart';
import 'package:silvio/widgets/bottom_sheet.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = false]) {
    final ids = Set();
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}

extension StringExtension on String {
  String capitalize() {
    return length > 0 ? "${this[0].toUpperCase()}${substring(1)}" : "";
  }

  String get getGradeString {
    double? grade = double.tryParse(replaceAll(',', '.'));
    return grade?.displayNumber() ?? this;
  }
}

extension DoubleExtention on double {
  String displayNumber({decimalDigits}) => NumberFormat.decimalPatternDigits(
          locale: config.usedLocaleCode ?? Platform.localeName,
          decimalDigits: decimalDigits)
      .format(decimalDigits != null
          ? num.parse(toStringAsFixed(decimalDigits))
          : this);
}

extension GradeCalculations on List<Grade> {
  List<Grade> get numericalGrades =>
      useable.where((Grade grade) => grade.grade != -1).toList();

  List<Grade> get useable =>
      where((Grade grade) => grade.type == GradeType.grade && grade.isEnabled)
          .toList();

  double get average {
    double total = 0;
    double totalgrades = 0;
    for (var grade in numericalGrades) {
      total += grade.grade * grade.weight;
      totalgrades += grade.weight;
    }
    return (total / totalgrades * 100).roundToDouble() / 100;
  }

  double get median {
    List<double> grades = List.of(map((e) => e.grade))
      ..sort((a, b) => a.compareTo(b));

    double median;

    int middle = grades.length ~/ 2;
    if (grades.length % 2 == 1) {
      median = grades[middle];
    } else {
      median = ((grades[middle - 1] + grades[middle]) / 2.0).roundToDouble();
    }

    return median;
  }

  double getPresentageSufficient() {
    double precentage = (useable.where((grade) => grade.isSufficient).length /
            useable.length *
            100)
        .roundToDouble();
    return precentage.isNaN ? 0 : precentage;
  }

  Grade? getHighest() {
    return numericalGrades.isNotEmpty
        ? numericalGrades.reversed
            .reduce((curr, next) => curr.grade > next.grade ? curr : next)
        : null;
  }

  Grade? getLowest() {
    return numericalGrades.isNotEmpty
        ? numericalGrades.reversed
            .reduce((curr, next) => curr.grade < next.grade ? curr : next)
        : null;
  }

  double getNewAverage(double grade, double weight) {
    double total = 0;
    double totalgrades = 0;
    for (var grade in List<Grade>.from(this).numericalGrades) {
      total += grade.grade * grade.weight;
      totalgrades += grade.weight;
    }
    return ((total + grade * weight) / (totalgrades + weight) * 100)
            .roundToDouble() /
        100;
  }

  double getNewGrade(double average, double weight) {
    double total = 0;
    double totalgrades = 0;
    for (var grade in List<Grade>.from(this).numericalGrades) {
      total += grade.grade * grade.weight;
      totalgrades += grade.weight;
    }
    return ((totalgrades + weight) * average - total) /
        weight *
        100.roundToDouble() /
        100;
  }

  Map<int, double> getGradeFrequency() {
    Map<int, double> gradefrequency = {};
    for (var i in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
      gradefrequency.addAll({
        i: numericalGrades
            .where((grade) => grade.grade.round() == i)
            .length
            .toDouble()
      });
    }
    return gradefrequency;
  }

  List<Grade> relatedSubjectGrades(Subject subject) {
    return where((g) =>
        g.subject.name.contains(subject.name) ||
        subject.name.contains(g.subject.name)).toList();
  }

  List<Grade> onlyFilterd(List<Filter> activeFilters) {
    List<Grade> filterdGrades = where(
      (Grade grade) =>
          !(activeFilters.where((filter) => filter.type == FilterTypes.quarterCode).isNotEmpty &&
              !activeFilters
                  .where((filter) => filter.type == FilterTypes.quarterCode)
                  .map((e) => e.filter)
                  .contains(grade.schoolQuarter?.id.toString())) &&
          !(activeFilters.where((filter) => filter.type == FilterTypes.subject).isNotEmpty &&
              !activeFilters
                  .where((filter) => filter.type == FilterTypes.subject)
                  .map((e) => e.filter)
                  .contains(grade.subject.id.toString())) &&
          !(activeFilters.where((filter) => filter.type == FilterTypes.teacher).isNotEmpty &&
              !activeFilters
                  .where((filter) => filter.type == FilterTypes.teacher)
                  .map((e) => e.filter)
                  .contains(grade.teacherCode)) &&
          !(activeFilters.where((filter) => filter.type == FilterTypes.dateRange).isNotEmpty &&
              !activeFilters
                  .where((filter) => filter.type == FilterTypes.dateRange)
                  .map((e) => e.filter)
                  .any((dateRange) =>
                      dateRange.start.difference(grade.addedDate).inMilliseconds.isNegative &&
                      !dateRange.end
                          .difference(DateUtils.dateOnly(grade.addedDate))
                          .inMilliseconds
                          .isNegative)) &&
          !(activeFilters.where((filter) => filter.type == FilterTypes.pta).isNotEmpty &&
              grade.isPTA != true) &&
          !(activeFilters.where((filter) => filter.type == FilterTypes.inputString).isNotEmpty &&
              !activeFilters.where((filter) => filter.type == FilterTypes.inputString).map((e) => e.filter).any((filter) => (grade.description != "" && grade.description.toLowerCase().contains(filter.toLowerCase())) || (grade.teacherCode != null && grade.teacherCode!.toLowerCase().contains(filter.toLowerCase())) || (grade.gradeString.toLowerCase().contains(filter.toLowerCase())))),
    ).toList();

    filterdGrades.sort((Grade a, Grade b) => b.addedDate.millisecondsSinceEpoch
        .compareTo(a.addedDate.millisecondsSinceEpoch));
    return filterdGrades;
  }

  List<Fact> generateFactsList(context, Person? person) {
    void Function() displayGrade(Grade grade) {
      return () => showSilvioModalBottomSheet(children: [
            GradeInformation(
              context: context,
              grade: grade,
              showGradeCalculate: true,
              grades: this,
            )
          ], context: context);
    }

    return [
      if (isNotEmpty)
        Fact(
            title: AppLocalizations.of(context)!.latestGrade,
            value: first.gradeString,
            onTap: displayGrade(first)),
      if (person != null &&
          getLinkedTests(person.calendarEvents)
              .where((test) => test.end.isAfter(DateTime.now()))
              .toList()
              .isNotEmpty)
        Fact(
            title: AppLocalizations.of(context)!.nextTest,
            value: getLinkedTests(person.calendarEvents)
                .where((test) => test.end.isAfter(DateTime.now()))
                .toList()
                .first
                .start
                .countdownString(context),
            onTap: () => showSilvioModalBottomSheet(children: [
                  EventInformation(
                      context: context,
                      event: getLinkedTests(person.calendarEvents)
                          .where((test) => test.end.isAfter(DateTime.now()))
                          .toList()
                          .first)
                ], context: context)),
      Fact(
          title: AppLocalizations.of(context)!.precentSufficient,
          value: "${getPresentageSufficient().displayNumber()}%"),
      if (getHighest() != null)
        Fact(
            title: AppLocalizations.of(context)!.highest,
            value: getHighest()!.gradeString,
            onTap: displayGrade(getHighest()!)),
      if (getLowest() != null)
        Fact(
            title: AppLocalizations.of(context)!.lowest,
            value: getLowest()!.gradeString,
            onTap: displayGrade(getLowest()!)),
      Fact(
          title:
              AppLocalizations.of(context)!.amountOfInsufficient.capitalize(),
          value: where((grade) => !grade.sufficient).length.toString()),
      if (where((grade) => !grade.sufficient).isNotEmpty)
        Fact(
            title: AppLocalizations.of(context)!.precentInsufficient,
            value: "${(100 - getPresentageSufficient()).displayNumber()}%"),
      if (isNotEmpty)
        Fact(
            title: AppLocalizations.of(context)!.averageWeight,
            value: map((e) => e.weight).average.displayNumber(decimalDigits: 2))
    ];
  }

  List<Subject> get subjects {
    List<Subject> foundSubjects = map<Subject>((grade) => grade.subject)
        .toList()
        .unique((g) => g.id)
        .map((e) => e.copy)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    for (Subject subject in foundSubjects) {
      subject.grades =
          where((grade) => grade.subject.id == subject.id).toList();
    }
    return foundSubjects;
  }

  List<CalendarEvent> getLinkedTests(List<CalendarEvent> calendarEvents) {
    return calendarEvents.tests
        .where((test) => map((e) => e.subject.name)
            .toSet()
            .intersection(test.subjectsNames.toSet())
            .isNotEmpty)
        .toList();
  }
}

class Fact {
  String title;
  String value;
  void Function()? onTap;

  Fact({required this.title, required this.value, this.onTap});
}

extension GradeCalculation on Grade {
  double changeInAverage(List<Grade> grades) {
    List<Grade> gradesBeforeGrade =
        grades.where((grade) => !addedDate.isBefore(grade.addedDate)).toList();
    return gradesBeforeGrade.average -
        gradesBeforeGrade.where((grade) => grade != this).toList().average;
  }
}

extension CalendarFilters on List<CalendarEvent> {
  List<CalendarEvent> get tests {
    return where((event) =>
        event.type != CalendarEventTypes.homework &&
        event.type != CalendarEventTypes.other).toList();
  }

  Map<DateTime, List<CalendarEvent>> sortPerDay() {
    Map<DateTime, List<CalendarEvent>> calPerDay = {};
    List<DateTime> days = map((e) => DateUtils.dateOnly(e.start)).toList();
    for (DateTime day in days) {
      calPerDay.addAll({
        day: where((e) => DateUtils.dateOnly(e.start).isAtSameMomentAs(day))
            .toList()
      });
    }
    return calPerDay;
  }
}

extension CalculationsOnAllSchoolYears on List<SchoolYear> {
  List<Grade> get allGrades {
    return expand((y) => y.grades).toList()
      ..sort((Grade a, Grade b) => b.addedDate.millisecondsSinceEpoch
          .compareTo(a.addedDate.millisecondsSinceEpoch));
  }

  List<SchoolYear> filterRelatedSubjectGrades(Subject subject,
      {calculateable = false}) {
    return calculateable
        ? where((sY) => sY.grades.numericalGrades
            .relatedSubjectGrades(subject)
            .isNotEmpty).toList()
        : where((sY) => sY.grades.useable
            .toList()
            .relatedSubjectGrades(subject)
            .isNotEmpty).toList();
  }
}

extension CalculationsOnSchoolYear on SchoolYear {
  double get average => grades.average;
}

extension IsSomething on String {
  bool get isBase64 {
    try {
      base64.decode(this);
      return true;
    } catch (e) {
      return false;
    }
  }
}

extension CountDownString on DateTime {
  String countdownString(BuildContext context) {
    if (difference(DateTime.now()).inMilliseconds.isNegative) {
      if (DateTime.now().difference(this).inMinutes < 60) {
        //Minutes
        return "${(DateTime.now().difference(this).inMinutes).round()} ${AppLocalizations.of(context)!.minutes}";
      } else if ((DateTime.now().difference(this).inHours) < 24) {
        //Hours
        return "${(DateTime.now().difference(this).inHours).round()} ${AppLocalizations.of(context)!.hours}";
      } else {
        //Days
        return "${(DateTime.now().difference(this).inHours / 24).round()} ${AppLocalizations.of(context)!.days}";
      }
    } else {
      if (difference(DateTime.now()).inMinutes < 60) {
        //Minutes
        return "${(difference(DateTime.now()).inMinutes).round()} ${AppLocalizations.of(context)!.minutes}";
      } else if (difference(DateTime.now()).inHours < 24) {
        //Hours
        return "${(difference(DateTime.now()).inHours).round()} ${AppLocalizations.of(context)!.hours}";
      } else {
        //Days
        return "${(difference(DateTime.now()).inHours / 24).round()} ${AppLocalizations.of(context)!.days}";
      }
    }
  }
}

Future<List<T>> progressWait<T>(
    List<Future<T>> futures, void Function(int completed, int total) progress) {
  int total = futures.length;
  int completed = 0;
  void complete() {
    completed++;
    progress(completed, total);
  }

  return Future.wait<T>(
      [for (var future in futures) future.whenComplete(complete)]);
}

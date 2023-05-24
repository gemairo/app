import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';

import 'package:silvio/screens/subject.dart';
import 'package:silvio/widgets/card.dart';
import 'package:silvio/widgets/charts/barchart_subjects_min_max.dart';
import 'package:silvio/widgets/charts/barchart_subjects_average.dart';
import 'package:silvio/widgets/charts/barchart_subjects_weight.dart';
import 'package:silvio/widgets/filter.dart';
import 'package:silvio/widgets/avatars.dart';
import 'package:silvio/widgets/navigation.dart';

class SubjectsListView extends StatefulWidget {
  const SubjectsListView({super.key});

  @override
  State<SubjectsListView> createState() => _SubjectsListView();
}

class _SubjectsListView extends State<SubjectsListView> {
  bool rounded = false;
  @override
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);

    void changeRounded(bool bool) => setState(() {
          rounded = bool;
        });

    List<Grade> grades =
        acP.schoolYear.grades.useable.onlyFilterd(acP.activeFilters);

    List<Widget> widgets = [
      ...grades.subjects.map((e) => ListTile(
            title: Text(e.name),
            leading: GradeAvatar(
              decimalDigits: rounded ? 0 : 2,
              gradeString:
                  e.grades.average.isNaN ? "-" : e.grades.average.toString(),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () {
              if (acP.schoolYear.grades.subjects
                  .where((sub) => sub.id == e.id)
                  .isNotEmpty) {
                Navigate().to(
                    context,
                    SubjectStatisticsView(
                      subject: acP.schoolYear.grades.subjects
                          .firstWhere((sub) => sub.id == e.id),
                    ),
                    "SubjectStatistics/${e.id}/${e.name}");
              }
            },
          ))
    ];

    return ListView(padding: const EdgeInsets.only(bottom: 16), children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CarouselSlider(
              items: [
                SilvioCard(
                    title: Text(AppLocalizations.of(context)!.averages),
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 0),
                        child: BarChartSubjectsAverage(
                          subjects: grades.numericalGrades.subjects,
                          rounded: rounded,
                        ))),
                SilvioCard(
                    title: Text(AppLocalizations.of(context)!.minMax),
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 0),
                        child: BarChartSubjectsMinMax(
                          subjects: grades.numericalGrades.subjects,
                        ))),
                SilvioCard(
                    title: Text(AppLocalizations.of(context)!
                        .averageWeight),
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 0),
                        child: BarChartSubjectsWeight(
                          subjects: grades.numericalGrades.subjects,
                        ))),
              ],
              options: CarouselOptions(
                  height: 175 + 8 + 48,
                  enlargeCenterPage: true,
                  scrollDirection: Axis.vertical,
                  enlargeFactor: .4,
                  viewportFraction: 1))),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: FilterChips(
            extraButtons: [
              FilterChip(
                  label: Text(AppLocalizations.of(context)!.rounded),
                  onSelected: changeRounded,
                  selected: rounded)
            ],
            grades: acP.schoolYear.grades,
          )),
      SilvioCardList(children: widgets)
    ]);
  }
}

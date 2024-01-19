import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gemairo/apis/saaf.dart';
import 'package:gemairo/widgets/bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';
import 'package:gemairo/widgets/ads.dart';

import 'package:gemairo/widgets/card.dart';
import 'package:gemairo/widgets/appbar.dart';
import 'package:gemairo/widgets/facts_header.dart';
import 'package:gemairo/widgets/filter.dart';
import 'package:gemairo/widgets/charts/barchart_frequency.dart';
import 'package:gemairo/widgets/charts/linechart_grades.dart';
import 'package:gemairo/widgets/cards/grade_calculations.dart';
import 'package:gemairo/widgets/cards/list_grade.dart';
import 'package:gemairo/widgets/cards/list_schoolyear.dart';
import 'package:gemairo/widgets/cards/list_test.dart';

class SubjectStatisticsView extends StatefulWidget {
  const SubjectStatisticsView({super.key, required this.subject});

  final Subject subject;

  @override
  State<SubjectStatisticsView> createState() => _SubjectStatisticsView();
}

class _SubjectStatisticsView extends State<SubjectStatisticsView> {
  void update() {
    setState(() {});
  }

  void addOrRemoveBadge(bool value, GradeListBadges badge) {
    if (value == true) {
      config.activeBadges.add(badge);
    } else {
      config.activeBadges.remove(badge);
    }
    setState(() {});
  }

  @override
  void initState() {
    Saaf.instance.handleNavigate(widget.subject.name);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);
    List<Grade> grades = widget.subject.grades.onlyFilterd(acP.activeFilters());
    List<CalendarEvent> tests = acP.person.calendarEvents.tests
        .where((test) => test.subjectsNames.contains(widget.subject.name))
        .toList();

    List<Widget> widgets = [
      if (grades.numericalGrades.length > 1)
        StaggeredGridTile.fit(
            crossAxisCellCount: 2,
            child: GemairoCard(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LineChartGrades(grades: grades, showAverage: true),
            ))),
      StaggeredGridTile.extent(
        crossAxisCellCount: 1,
        mainAxisExtent: 250,
        child: RelatedSchoolYearsCard(
          subject: widget.subject,
        ),
      ),
      StaggeredGridTile.extent(
        crossAxisCellCount: 1,
        mainAxisExtent: 250,
        child: UpcomingTestsCard(
          calendarEvents: tests,
        ),
      ),
      if (grades.numericalGrades.isNotEmpty) ...[
        StaggeredGridTile.fit(
            crossAxisCellCount: 2,
            child: SizedBox(
                height: 250,
                child: GemairoCard(
                    title: Text(AppLocalizations.of(context)!.whatShouldIGet),
                    child: Expanded(
                        child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: GradeCalculate(
                          context: context,
                          grades: grades,
                          calcNewAverage: false),
                    ))))),
        StaggeredGridTile.fit(
            crossAxisCellCount: 2,
            child: SizedBox(
                height: 250,
                child: GemairoCard(
                  title: Text(AppLocalizations.of(context)!
                      .whatIsGoingToBeMyNewAverage),
                  child: Expanded(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: GradeCalculate(
                        context: context, grades: grades, calcNewAverage: true),
                  )),
                ))),
        StaggeredGridTile.fit(
            crossAxisCellCount: 2,
            child: GemairoCard(
                title: Text(AppLocalizations.of(context)!.histogram),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: BarChartFrequency(grades: grades),
                ))),
      ],
    ];

    return Scaffold(
        appBar: GemairoAppBar(
          title: widget.subject.name,
        ),
        body: BottomBanner(
          child: ListView(children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FactsHeader(
                  grades: grades.useable,
                )),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: FilterChips(
                  grades: widget.subject.grades,
                )),
            GemairoCardList(
              maxCrossAxisExtent: 250,
              children: widgets,
            ),
            if (grades.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(AppLocalizations.of(context)!.grades),
                  leading: Icon(Icons.numbers),
                  trailing: GradeListOptions(
                    addOrRemoveBadge: addOrRemoveBadge,
                  ),
                ),
              ),
            ...grades
                .sortByDate((e) => e.addedDate, doNotSort: true)
                .entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(children: [
                      ListTile(
                        title: Text(e.key,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                        dense: true,
                      ),
                      ...e.value.map((e) => GradeTile(
                            grade: e,
                            grades: grades,
                            onTap: () => showGemairoModalBottomSheet(children: [
                              GradeInformation(
                                context: context,
                                grade: e,
                                grades: grades,
                                showGradeCalculate: true,
                              )
                            ], context: context),
                          ))
                    ]),
                  ),
                )
          ]),
        ));
  }
}

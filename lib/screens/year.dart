import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:silvio/widgets/announcements.dart';
import 'package:silvio/widgets/cards/list_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';

import 'package:silvio/widgets/card.dart';
import 'package:silvio/widgets/facts_header.dart';
import 'package:silvio/widgets/filter.dart';
import 'package:silvio/widgets/charts/barchart_frequency.dart';
import 'package:silvio/widgets/charts/linechart_grades.dart';
import 'package:silvio/widgets/cards/list_grade.dart';

class SchoolYearStatisticsView extends StatefulWidget {
  const SchoolYearStatisticsView({super.key});

  @override
  State<SchoolYearStatisticsView> createState() => _SchoolYearStatisticsView();
}

class _SchoolYearStatisticsView extends State<SchoolYearStatisticsView> {
  List<Announcement> announcements = [];

  loadAnnoucements() async {
    announcements = await getAnnouncements();
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
    super.initState();
    loadAnnoucements();
  }

  @override
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);
    List<Grade> allGrades =
        acP.schoolYear.grades.onlyFilterd(acP.activeFilters());
    List<Grade> grades = allGrades.useable;

    List<Widget> widgets = [
      ...announcements.map((announcement) => StaggeredGridTile.fit(
          crossAxisCellCount: 2,
          child: AnnouncementCard(announcement: announcement))),
      if (grades.isNotEmpty) ...[
        if (grades.numericalGrades.length > 1)
          StaggeredGridTile.fit(
              crossAxisCellCount: 2,
              child: SilvioCard(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LineChartGrades(
                  grades: grades,
                  showAverage: true,
                ),
              ))),
        StaggeredGridTile.extent(
          mainAxisExtent: 250,
          crossAxisCellCount: 1,
          child: SizedBox(
            height: 250,
            child: RecentGradeCard(
              grades: grades,
            ),
          ),
        ),
        StaggeredGridTile.extent(
          mainAxisExtent: 250,
          crossAxisCellCount: 1,
          child: SizedBox(
              height: 250,
              child: UpcomingTestsCard(
                calendarEvents: acP.person.calendarEvents,
              )),
        ),
        if (grades.numericalGrades.isNotEmpty)
          StaggeredGridTile.fit(
              crossAxisCellCount: 2,
              child: SilvioCard(
                  title: Text(AppLocalizations.of(context)!.histogram),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: BarChartFrequency(
                      context: context,
                      grades: grades,
                    ),
                  ))),
        StaggeredGridTile.fit(
            crossAxisCellCount: 4,
            child: SilvioCard(
                title: Text(AppLocalizations.of(context)!.grades),
                trailing: GradeListOptions(
                  addOrRemoveBadge: addOrRemoveBadge,
                ),
                child: GradeList(
                    context: context,
                    showGradeCalculate: true,
                    grades: allGrades
                        .where((grade) => grade.type == GradeType.grade)
                        .toList())))
      ],
    ];

    return ListView(padding: const EdgeInsets.only(bottom: 16), children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FactsHeader(
            grades: grades.useable,
          )),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: FilterChips(
            grades: acP.schoolYear.grades,
          )),
      SilvioCardList(
        maxCrossAxisExtent: 250,
        children: widgets,
      )
    ]);
  }
}

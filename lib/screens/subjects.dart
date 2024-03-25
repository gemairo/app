import 'dart:math';

import 'package:collection/collection.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/apis/ads.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';
import 'package:gemairo/screens/subject.dart';
import 'package:gemairo/widgets/ads.dart';
import 'package:gemairo/widgets/avatars.dart';
import 'package:gemairo/widgets/card.dart';
import 'package:gemairo/widgets/charts/barchart_subjects_average.dart';
import 'package:gemairo/widgets/charts/barchart_subjects_min_max.dart';
import 'package:gemairo/widgets/charts/barchart_subjects_weight.dart';
import 'package:gemairo/widgets/filter.dart';
import 'package:gemairo/widgets/global/skeletons.dart';
import 'package:gemairo/widgets/navigation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class SubjectsListView extends StatefulWidget {
  const SubjectsListView({super.key});

  @override
  State<SubjectsListView> createState() => _SubjectsListView();
}

class _SubjectsListView extends State<SubjectsListView> {
  bool rounded = false;

  @override
  void initState() {
    super.initState();
    Ads.instance?.handleNavigate('subjects');
  }

  @override
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);

    void changeRounded(bool bool) => setState(() {
          rounded = bool;
        });

    List<Grade> grades =
        acP.schoolYear.grades.useable.onlyFilterd(acP.activeFilters());

    List<Widget> widgets = [
      ...grades.subjects.map((subject) => ListTile(
            title: Text(subject.name),
            leading: GradeAvatar(
              decimalDigits: rounded ? 0 : null,
              gradeString: subject.grades.average.isNaN
                  ? "-"
                  : subject.roundOnDecimals != null
                      ? ((subject.grades.average *
                                      pow(10, subject.roundOnDecimals!))
                                  .truncate() /
                              pow(10, subject.roundOnDecimals!))
                          .toString()
                      : subject.grades.average.toString(),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            trailing: Wrap(
              spacing: 8,
              children: [
                if (subject.grades.sufficientSafety > 1 &&
                    subject.grades.numericalGrades.isNotEmpty &&
                    subject.warningEnabled &&
                    acP.schoolYear.warningEnabled)
                  Tooltip(
                      triggerMode: TooltipTriggerMode.tap,
                      showDuration: const Duration(minutes: 60),
                      richMessage: TextSpan(children: [
                        TextSpan(
                            text: AppLocalizations.of(context)!
                                .sufficientSafety1),
                        TextSpan(
                          text: subject.grades
                              .map((g) => g.weight)
                              .average
                              .displayNumber(decimalDigits: 2),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                            text: AppLocalizations.of(context)!
                                .sufficientSafety2),
                        TextSpan(
                            text: subject.grades.sufficientSafety
                                .displayNumber(decimalDigits: 2),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                            text:
                                AppLocalizations.of(context)!.sufficientSafety3)
                      ]),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        foregroundColor:
                            Theme.of(context).colorScheme.onBackground,
                        child: Icon(
                          subject.grades.sufficientSafety <
                                  config.sufficientFrom
                              ? Icons.info_outline
                              : Icons.warning_amber_outlined,
                          color: subject.grades.sufficientSafety >
                                  subject.grades.average
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      )),
                CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).colorScheme.onBackground,
                    child: const Icon(Icons.navigate_next)),
              ],
            ),
            onTap: () {
              if (acP.schoolYear.grades.subjects
                  .where((sub) => sub.id == subject.id)
                  .isNotEmpty) {
                Navigate().to(
                    context,
                    SubjectStatisticsView(
                      subject: acP.schoolYear.grades.subjects
                          .firstWhere((sub) => sub.id == subject.id),
                    ),
                    "SubjectStatistics/${subject.id}/${subject.name}");
              }
            },
          ))
    ];

    bool showLeaderboard = Ads.instance != null &&
        FirebaseRemoteConfig.instance.getBool('ads_subjects_leaderboard');
    if (widgets.length >= 8) {
      if (!showLeaderboard && Ads.instance != null) {
        widgets.insert(6, Ads.instance!.bannerAd(context));
      } else {
        showLeaderboard = true;
      }
    }

    return ScaffoldSkeleton(
        onRefresh: () async {
          AccountProvider acP =
              Provider.of<AccountProvider>(context, listen: false);
          await acP.account.api.refreshAll(acP.person);
          acP.changeAccount(null);
        },
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GemairoCard(
              title: Text(AppLocalizations.of(context)!.averages),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 0),
                child: BarChartSubjectsAverage(
                  subjects: grades.numericalGrades.subjects,
                  rounded: rounded,
                ),
              ),
            ),
          ),
          if (Ads.instance != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Ads.instance?.bannerAd(context),
            ),
          ],
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
          GemairoCardList(children: widgets),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(AppLocalizations.of(context)!.subjectGraphs),
              leading: const Icon(Icons.analytics_outlined),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GemairoCard(
              title: Text(AppLocalizations.of(context)!.minMax),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 0),
                child: BarChartSubjectsMinMax(
                  subjects: grades.numericalGrades.subjects,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (Ads.instance != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Ads.instance?.bannerAd(context),
            ),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GemairoCard(
              title: Text(AppLocalizations.of(context)!.averageWeight),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 0),
                child: BarChartSubjectsWeight(
                  subjects: grades.numericalGrades.subjects,
                ),
              ),
            ),
          ),
          if (showLeaderboard && Ads.instance != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              margin: const EdgeInsets.only(top: 10),
              height: 300,
              child: const Advertisement(size: AdSize.mediumRectangle),
            ),
        ]);
  }
}

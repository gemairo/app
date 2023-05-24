import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:silvio/widgets/avatars.dart';
import 'package:silvio/widgets/card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';
import 'package:silvio/widgets/bottom_sheet.dart';
import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/widgets/cards/grade_calculations.dart';

class GradeList extends StatefulWidget {
  const GradeList(
      {super.key,
      required context,
      this.grades = const [],
      this.warnings = const [],
      this.showGradeCalculate = false});

  final List<Grade> grades;
  final bool showGradeCalculate;
  final List<String> warnings;
  @override
  State<StatefulWidget> createState() => _GradeList();
}

class _GradeList extends State<GradeList> {
  int loadedAmount = 99;

  @override
  Widget build(BuildContext context) {
    List<Grade> grades = widget.grades.take(loadedAmount).toList();
    // int loadedAds = 0;
    // int showAdEveryNth = 10;
    // int maxAds = 5;
    return Column(
      children: [
        MasonryGridView.extent(
          primary: false,
          shrinkWrap: true,
          cacheExtent: double.maxFinite,
          itemCount: grades.length,
          // itemCount: grades.length + (grades.length~/showAdEveryNth).floor(),
          maxCrossAxisExtent: 600,
          itemBuilder: (context, index) {
            // if (index % 11 == 10) {
            //   loadedAds++;
            //   return loadedAds <= maxAds ? const Advertisement(size: AdSize.banner,) : Container();
            // } else {

            Grade grade = grades[index]; //grades[index - (index ~/ 11)];
            List<Grade> subjectGrades = config.activeBadges
                    .contains(GradeListBadges.changeInAverageSubject)
                ? grades
                    .where((lgrade) => lgrade.subject.id == grade.subject.id)
                    .toList()
                : [];

            return Opacity(
                opacity: grade.isEnabled ? 1 : .5,
                child: ListTile(
                    title: Text(grade.subject.name),
                    subtitle: grade.description != ""
                        ? Text(grade.description)
                        : null,
                    onTap: () => showSilvioModalBottomSheet(children: [
                          GradeInformation(
                            context: context,
                            grade: grade,
                            grades: widget.grades,
                            warnings: widget.warnings,
                            showGradeCalculate: widget.showGradeCalculate,
                          )
                        ], context: context),
                    leading: Column(children: [
                      GradeAvatar(
                        gradeString: grade.gradeString,
                        isSufficient: grade.isSufficient,
                      )
                    ]),
                    trailing: config.activeBadges.isNotEmpty
                        ? Wrap(
                            direction: Axis.vertical,
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                                if (config.activeBadges
                                    .contains(GradeListBadges.date))
                                  Badge(
                                      label: Text(DateFormat.yMd()
                                          .format(grade.addedDate))),
                                if (config.activeBadges
                                    .contains(GradeListBadges.weight))
                                  Badge(
                                      label: Text(
                                          "${grade.weight.displayNumber()}x")),
                                if (config.activeBadges
                                        .contains(GradeListBadges.pta) &&
                                    grade.isPTA == true)
                                  const Badge(
                                    label: Text(
                                      "PTA",
                                    ),
                                  ),
                                if (config.activeBadges.contains(
                                        GradeListBadges.changeInAverage) &&
                                    grades.isNotEmpty &&
                                    !grade.changeInAverage(grades).isNaN)
                                  changeInAverageBadge(context,
                                      grade.changeInAverage(grades), grades),
                                if (subjectGrades.isNotEmpty &&
                                    !grade.changeInAverage(subjectGrades).isNaN)
                                  changeInAverageBadge(
                                      context,
                                      grade.changeInAverage(subjectGrades),
                                      subjectGrades)
                              ])
                        : null));
          },
        ),
        if (widget.grades.useable.length > loadedAmount)
          Center(
              child: TextButton.icon(
            onPressed: () {
              setState(() {
                loadedAmount += 100;
              });
            },
            label: Text(AppLocalizations.of(context)!.loadMore),
            icon: const Icon(Icons.expand_more),
          ))
      ],
    );
  }
}

class GradeListOptions extends StatelessWidget {
  const GradeListOptions({super.key, required this.addOrRemoveBadge});

  final void Function(bool, GradeListBadges) addOrRemoveBadge;

  @override
  Widget build(BuildContext context) {
    String gradeListBadgesName(GradeListBadges badge) {
      switch (badge) {
        case GradeListBadges.pta:
          return AppLocalizations.of(context)!.showPTA;
        case GradeListBadges.date:
          return AppLocalizations.of(context)!.showDate;
        case GradeListBadges.weight:
          return AppLocalizations.of(context)!.showWeight;
        case GradeListBadges.changeInAverage:
          return AppLocalizations.of(context)!.showChangeInAverage;
        case GradeListBadges.changeInAverageSubject:
          return AppLocalizations.of(context)!.showChangeInSubjectAverage;
        default:
          return "";
      }
    }

    return MenuAnchor(
      menuChildren: [
        ...GradeListBadges.values.map((e) => CheckboxMenuButton(
            onChanged: (bool? value) => addOrRemoveBadge(value ?? false, e),
            value: config.activeBadges.contains(e),
            child: Text(gradeListBadgesName(e))))
      ],
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
        );
      },
    );
  }
}

class GradeInformation extends StatefulWidget {
  const GradeInformation(
      {super.key,
      required context,
      this.grades = const [],
      required this.grade,
      this.warnings = const [],
      this.showGradeCalculate = false});

  final List<Grade> grades;
  final Grade grade;
  final List<String> warnings;
  final bool showGradeCalculate;

  @override
  State<GradeInformation> createState() => _GradeInformation();
}

class _GradeInformation extends State<GradeInformation> {
  bool alsoGradesAfter = false;
  bool isRefreshing = false;
  bool subjectCalculate = true;
  @override
  Widget build(BuildContext context) {
    bool differentSubjects = !widget.grades
        .map((grade) => grade.subject.id)
        .every((id) => id == widget.grade.subject.id);
    List<Grade> grades = subjectCalculate
        ? widget.grades
            .where((grade) => grade.subject.id == widget.grade.subject.id)
            .toList()
        : widget.grades;

    List<String> warnings = List.of(widget.warnings);
    if (differentSubjects && !subjectCalculate) {
      warnings
          .add(AppLocalizations.of(context)!.warningNonSubjectSpecificGrades);
    }
    if (Provider.of<AccountProvider>(context).person.activeFilters.isNotEmpty) {
      warnings.add(AppLocalizations.of(context)!.warningfilterActive);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ListTile(
        title: Text(widget.grade.subject.name),
        subtitle: Text(widget.grade.description),
        trailing:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          if (widget.grade.isPTA == true)
            Badge(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              label: Text(
                "PTA",
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          if (grades.isNotEmpty && !widget.grade.changeInAverage(grades).isNaN)
            changeInAverageBadge(
                context, widget.grade.changeInAverage(grades), grades),
        ]),
        leading: GradeAvatar(
          gradeString: widget.grade.gradeString,
          isSufficient: widget.grade.isSufficient,
        ),
      ),
      ListTile(
        title: Text(DateFormat.yMMMMd('nl')
            .add_jm()
            .format(widget.grade.addedDate.toLocal())),
        leading: const Icon(Icons.calendar_today),
      ),
      ListTile(
        title: Text(widget.grade.weight.displayNumber()),
        leading: const Icon(Icons.balance),
      ),
      ListTile(
        title: Text(
            "${widget.grade.schoolQuarter?.name} (${widget.grade.schoolQuarter?.shortname})"),
        leading: const Icon(Icons.calendar_month),
      ),
      ListTile(
        title: Text(widget.grade.teacherCode ?? ""),
        leading: const Icon(Icons.supervisor_account),
      ),
      if (grades.isNotEmpty &&
          grades.numericalGrades.isNotEmpty &&
          widget.showGradeCalculate) ...[
        const Divider(),
        ...warnings.map(
          (warning) => ListTile(
              title: Text(AppLocalizations.of(context)!.warning(warning)),
              leading: Icon(
                Icons.warning_amber_outlined,
                color: Theme.of(context).colorScheme.error,
              )),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: StaggeredGrid.extent(
              maxCrossAxisExtent: 450,
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
              children: [
                SilvioCard(
                    title:
                        Text(AppLocalizations.of(context)!.whatShouldIGetRedo),
                    elevation: 2,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                      child: GradeCalculate(
                          context: context,
                          grades: grades
                              .where((lGrade) =>
                                  lGrade != widget.grade &&
                                  !(!alsoGradesAfter &&
                                      !lGrade.addedDate
                                          .isBefore(widget.grade.addedDate)))
                              .toList(),
                          preFillWeight: widget.grade.weight,
                          calcNewAverage: false),
                    )),
                SilvioCard(
                    title: Text(AppLocalizations.of(context)!
                        .whatIsGoingToBeMyNewAverageRedo),
                    elevation: 2,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                      child: GradeCalculate(
                          context: context,
                          grades: grades
                              .where((lGrade) =>
                                  lGrade != widget.grade &&
                                  !(!alsoGradesAfter &&
                                      !lGrade.addedDate
                                          .isBefore(widget.grade.addedDate)))
                              .toList(),
                          preFillWeight: widget.grade.weight,
                          calcNewAverage: true),
                    )),
              ]),
        )
      ],
      const Divider(),
      ListTile(
        title: Text(AppLocalizations.of(context)!.gradeSettings),
      ),
      if (differentSubjects)
        SwitchListTile(
          secondary: const Icon(Icons.book_outlined),
          value: subjectCalculate,
          onChanged: (value) => setState(() {
            subjectCalculate = value;
          }),
          title: Text(AppLocalizations.of(context)!.caluclateWithFoundSubject),
          subtitle:
              Text(AppLocalizations.of(context)!.caluclateWithFoundSubjectExpl),
        ),
      if (grades.isNotEmpty &&
          grades.numericalGrades.isNotEmpty &&
          widget.showGradeCalculate)
        SwitchListTile(
          secondary: const Icon(Icons.history),
          value: alsoGradesAfter,
          onChanged: (value) => setState(() {
            alsoGradesAfter = value;
          }),
          title: Text(AppLocalizations.of(context)!.useLaterReciviedGrades),
          subtitle:
              Text(AppLocalizations.of(context)!.useLaterReciviedGradesExpl),
        ),
      SwitchListTile(
        secondary: const Icon(Icons.calculate_outlined),
        value: widget.grade.isEnabled,
        onChanged: (value) {
          widget.grade.isEnabled = value;
          setState(() {});
          Provider.of<AccountProvider>(context, listen: false)
              .changeAccount(null);
        },
        title: Text(AppLocalizations.of(context)!.useThisGradeForCalculations),
      ),
      ListTile(
        leading: const Icon(Icons.download),
        title: Text(AppLocalizations.of(context)!.reloadGrade),
        trailing: Wrap(children: [
          IconButton(
            onPressed: () async {
              setState(() {
                isRefreshing = true;
              });
              final AccountProvider acP =
                  Provider.of<AccountProvider>(context, listen: false);
              await acP.account.api.refreshGrade(acP.person, widget.grade);
              acP.account.save();
              setState(() {
                isRefreshing = false;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<AccountProvider>(context, listen: false)
                    .changeAccount(null);
              });
            },
            icon: CircleAvatar(
                child: isRefreshing
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.refresh)),
          )
        ]),
      )
    ]);
  }
}

Badge changeInAverageBadge(context, double value, List<Grade> grades) {
  return Badge(
    backgroundColor: value.isNegative
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.primaryContainer,
    label: RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.labelSmall,
        children: [
          WidgetSpan(
            child: value.isNegative
                ? Transform.rotate(
                    angle: 90 * math.pi / 180,
                    child: Icon(
                      Icons.arrow_outward,
                      size: 14,
                      color: Theme.of(context).textTheme.labelSmall?.color,
                    ))
                : Icon(Icons.arrow_outward,
                    size: 14,
                    color: Theme.of(context).textTheme.labelSmall?.color),
          ),
          TextSpan(
            text: value.displayNumber(decimalDigits: 2),
          ),
        ],
      ),
    ),
  );
}

class RecentGradeCard extends StatelessWidget {
  const RecentGradeCard({super.key, required this.grades});

  final List<Grade> grades;

  @override
  Widget build(BuildContext context) {
    List<Grade> recentGrades = grades
        .where(
          (grade) => DateTime.now().difference(grade.addedDate).inDays < 7,
        )
        .toList();
    return CarouselCard(
      title: AppLocalizations.of(context)!.recentGrades,
      children: recentGrades.isNotEmpty
          ? recentGrades
              .map((grade) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        onTap: () => showSilvioModalBottomSheet(children: [
                              GradeInformation(
                                context: context,
                                grade: grade,
                                grades: grades,
                                showGradeCalculate: true,
                              )
                            ], context: context),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: GradeAvatar(
                                      gradeString: grade.gradeString,
                                      isSufficient: grade.isSufficient),
                                )),
                            Text(
                              grade.subject.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              AppLocalizations.of(context)!.sometimeAgo(
                                  grade.addedDate.countdownString(context)),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
                            )
                          ],
                        )),
                  ))
              .toList()
          : [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.not_interested,
                        color: Theme.of(context).colorScheme.outline,
                        size: 32,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.noRecentGrades,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            ],
    );
  }
}

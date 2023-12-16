import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gemairo/widgets/avatars.dart';
import 'package:gemairo/widgets/card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';
import 'package:gemairo/widgets/bottom_sheet.dart';
import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/widgets/cards/grade_calculations.dart';

class GradeList extends StatefulWidget {
  const GradeList(
      {super.key,
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
          maxCrossAxisExtent: 640,
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
                    title: Text(
                      grade.subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: grade.description != ""
                        ? Text(
                            grade.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: () => showGemairoModalBottomSheet(children: [
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
                                  changeInAverageBadge(
                                      context, grade.changeInAverage(grades)),
                                if (subjectGrades.isNotEmpty &&
                                    !grade.changeInAverage(subjectGrades).isNaN)
                                  changeInAverageBadge(context,
                                      grade.changeInAverage(subjectGrades))
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
  bool alsoGradesAfter = true;
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

    List<Grade> afterOptionGrades = grades
        .where((lGrade) =>
            lGrade != widget.grade &&
            !(!alsoGradesAfter &&
                !lGrade.addedDate.isBefore(widget.grade.addedDate)))
        .toList();

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
            changeInAverageBadge(context, widget.grade.changeInAverage(grades)),
        ]),
        leading: GradeAvatar(
          gradeString: widget.grade.gradeString,
          isSufficient: widget.grade.isSufficient,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: GemairoCard(
            isFilled: true,
            title: Text(AppLocalizations.of(context)!.information),
            child: Column(
              children: [
                ListTile(
                  title: Text(AppLocalizations.of(context)!.gradeAddedDate),
                  subtitle: Text(DateFormat.yMMMMd('nl')
                      .add_jm()
                      .format(widget.grade.addedDate.toLocal())),
                  leading: const Icon(Icons.access_time),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.weight),
                  subtitle: Text(widget.grade.weight.displayNumber()),
                  leading: const Icon(Icons.balance),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.period),
                  subtitle: Text(
                      "${widget.grade.schoolQuarter?.name} (${widget.grade.schoolQuarter?.shortname})"),
                  leading: const Icon(Icons.calendar_month),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.teacher),
                  subtitle: Text(widget.grade.teacherCode ?? ""),
                  leading: const Icon(Icons.supervisor_account),
                ),
              ],
            )),
      ),
      if (grades.isNotEmpty &&
          grades.numericalGrades.isNotEmpty &&
          widget.showGradeCalculate) ...[
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GemairoCard(
              isFilled: false,
              child: ListTile(
                leading: const Icon(Icons.redo_outlined),
                title: Text(AppLocalizations.of(context)!.resit),
              ),
            )),
        if (afterOptionGrades.getNewGrade(
                    config.sufficientFrom, widget.grade.weight) >
                widget.grade.grade &&
            grades.average < config.sufficientFrom)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: GemairoCard(
                isFilled: true,
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: Text(AppLocalizations.of(context)!.gradeForPass),
                  subtitle: Text(afterOptionGrades
                      .getNewGrade(config.sufficientFrom, widget.grade.weight)
                      .displayNumber()),
                ),
              )),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GemairoCard(
                isFilled: true,
                trailing: warnings.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Tooltip(
                          triggerMode: TooltipTriggerMode.tap,
                          showDuration: const Duration(minutes: 60),
                          message: warnings
                              .map((e) =>
                                  AppLocalizations.of(context)!.warning(e))
                              .join("\n"),
                          child: Icon(
                            Icons.warning_amber_outlined,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ))
                    : null,
                title: Text(AppLocalizations.of(context)!.whatShouldIGetRedo),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: GradeCalculate(
                      context: context,
                      grades: afterOptionGrades,
                      preFillWeight: widget.grade.weight,
                      calcNewAverage: false),
                ))),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GemairoCard(
                isFilled: true,
                trailing: warnings.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Tooltip(
                          triggerMode: TooltipTriggerMode.tap,
                          showDuration: const Duration(minutes: 60),
                          message: warnings
                              .map((e) =>
                                  AppLocalizations.of(context)!.warning(e))
                              .join("\n"),
                          child: Icon(
                            Icons.warning_amber_outlined,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ))
                    : null,
                title: Text(AppLocalizations.of(context)!
                    .whatIsGoingToBeMyNewAverageRedo),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: GradeCalculate(
                      context: context,
                      grades: afterOptionGrades,
                      preFillWeight: widget.grade.weight,
                      calcNewAverage: true),
                ))),
      ],
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: GemairoCard(
            isFilled: false,
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(AppLocalizations.of(context)!.gradeSettings),
            ),
          )),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: GemairoCard(
              isFilled: true,
              child: Column(children: [
                if (differentSubjects)
                  SwitchListTile(
                    secondary: const Icon(Icons.book_outlined),
                    value: subjectCalculate,
                    onChanged: (value) => setState(() {
                      subjectCalculate = value;
                    }),
                    title: Text(AppLocalizations.of(context)!
                        .caluclateWithFoundSubject),
                    subtitle: Text(AppLocalizations.of(context)!
                        .caluclateWithFoundSubjectExpl),
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
                    title: Text(
                        AppLocalizations.of(context)!.useLaterReciviedGrades),
                    subtitle: Text(AppLocalizations.of(context)!
                        .useLaterReciviedGradesExpl),
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
                    title: Text(AppLocalizations.of(context)!
                        .useThisGradeForCalculations),
                    subtitle: Text(AppLocalizations.of(context)!
                        .useThisGradeForCalculationsExpl)),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(AppLocalizations.of(context)!.reloadGrade),
                  subtitle: Text(AppLocalizations.of(context)!.reloadGradeExpl),
                  trailing: Wrap(children: [
                    IconButton(
                      onPressed: () async {
                        setState(() {
                          isRefreshing = true;
                        });
                        final AccountProvider acP =
                            Provider.of<AccountProvider>(context,
                                listen: false);
                        await acP.account.api
                            .refreshGrade(acP.person, widget.grade);
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          child: isRefreshing
                              ? CircularProgressIndicator(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                )
                              : const Icon(Icons.refresh)),
                    )
                  ]),
                )
              ]))),
    ]);
  }
}

Badge changeInAverageBadge(context, double value) {
  return Badge(
    backgroundColor: value.isNegative
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.primaryContainer,
    label: RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.labelSmall,
        children: [
          WidgetSpan(
            child: RotatedBox(
                quarterTurns: value.isNegative ? 1 : 0,
                child: Icon(
                    size: ((Theme.of(context).textTheme.labelSmall?.fontSize ??
                            12) *
                        MediaQuery.of(context).textScaleFactor *
                        1.2),
                    Icons.arrow_outward)),
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
                            const BorderRadius.all(Radius.circular(32)),
                        onTap: () => showGemairoModalBottomSheet(children: [
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

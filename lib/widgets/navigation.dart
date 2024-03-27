import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemairo/apis/magister.dart';
import 'package:gemairo/screens/search.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';

import 'package:gemairo/screens/subject.dart';
import 'package:gemairo/screens/subjects.dart';
import 'package:gemairo/screens/year.dart';

List<NavigationDestination> appBarDestinations(BuildContext context) => [
      NavigationDestination(
        tooltip: AppLocalizations.of(context)!.yearViewExpl,
        icon: const Icon(Icons.auto_awesome_outlined),
        label: AppLocalizations.of(context)!.yearView,
        selectedIcon: const Icon(Icons.auto_awesome),
      ),
      NavigationDestination(
        tooltip: AppLocalizations.of(context)!.subjectsViewExpl,
        icon: const Icon(Icons.book_outlined),
        label: AppLocalizations.of(context)!.subjects,
        selectedIcon: const Icon(Icons.book),
      ),
      NavigationDestination(
        tooltip: AppLocalizations.of(context)!.searchExpl,
        icon: const Icon(Icons.search_outlined),
        label: AppLocalizations.of(context)!.searchView,
        selectedIcon: const Icon(Icons.search),
      ),
    ];

List<NavigationRailDestination> navRailDestinations(BuildContext context) =>
    appBarDestinations(context)
        .map(
          (destination) => NavigationRailDestination(
            icon: Tooltip(
              message: destination.label,
              child: destination.icon,
            ),
            selectedIcon: Tooltip(
              message: destination.label,
              child: destination.selectedIcon,
            ),
            label: Text(destination.label),
          ),
        )
        .toList();

class GemairoNavigationRail extends StatelessWidget {
  const GemairoNavigationRail({
    super.key,
    this.selectedIndex = 0,
    this.onSelectItem,
  });

  final void Function(int)? onSelectItem;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ));

    return NavigationRail(
      labelType: NavigationRailLabelType.selected,
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Icon(
          IconData(0xf201, fontFamily: "Gemairo"),
          size: 24 * 0.8,
        ),
      ),
      destinations: navRailDestinations(context),
      groupAlignment: 0,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelectItem,
    );
  }
}

class GemairoNavigationDrawer extends StatelessWidget {
  const GemairoNavigationDrawer({
    super.key,
    this.selectedIndex = 0,
    this.onSelectItem,
  });

  final void Function(int)? onSelectItem;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ));

    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelectItem,
      children: [
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconData(0xf201, fontFamily: "Gemairo")),
                Text(
                  "  Gemairo",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                )
              ],
            )),
        ...navRailDestinations(context)
            .map((dest) => NavigationDrawerDestination(
                icon: dest.icon,
                selectedIcon: dest.selectedIcon,
                label: dest.label))
            .toList()
      ],
    );
  }
}

class GemairoNavigationBar extends StatelessWidget {
  const GemairoNavigationBar({
    super.key,
    this.screenIndex = 0,
    this.onSelectItem,
  });

  final int screenIndex;
  final void Function(int)? onSelectItem;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor:
          Theme.of(context).navigationBarTheme.backgroundColor,
    ));

    return NavigationBar(
      destinations: appBarDestinations(context),
      selectedIndex: screenIndex,
      onDestinationSelected: onSelectItem,
    );
  }
}

class ScreensSwitch extends StatelessWidget {
  const ScreensSwitch(
      {super.key,
      required this.index,
      required this.swipeEnabled,
      this.controller});
  final int index;
  final bool swipeEnabled;
  final PageController? controller;

  @override
  Widget build(BuildContext context) {
    if (swipeEnabled && config.swipeNavigation && controller != null) {
      return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: PageView(
            controller: controller,
            children: const [
              SchoolYearStatisticsView(),
              SubjectsListView(),
              SearchView()
            ],
          ));
    } else {
      return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Builder(
            key: ValueKey<int>(index),
            builder: (context) {
              switch (index) {
                case 0:
                  return const SchoolYearStatisticsView();
                case 1:
                  return const SubjectsListView();
                case 2:
                  return const SearchView();
                default:
                  return const SchoolYearStatisticsView();
              }
            },
          ));
    }
  }
}

void changeSchoolYear(BuildContext context, {required int newid}) {
  //Clear filters and change the active school year.
  final AccountProvider acP =
      Provider.of<AccountProvider>(context, listen: false);
  acP.changeSchoolYear(newid);

  if (acP.person.activeSchoolYear.grades.isEmpty) {
    //No grades, show message
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => FetchWeightsScreen(
              account: acP.account,
              customContinue: () {
                Navigator.of(context).pop();
                acP.changeSchoolYear(acP.person.activeSchoolYear.id);
              },
              forcedEnabledId: acP.person.activeSchoolYear.id,
            )));
  }

  //If the user is viewing a subject that also exists in the new school year Gemairo opens the page on that subject
  if (ModalRoute.of(context)!.settings.name != null &&
      ModalRoute.of(context)!.settings.name!.contains("SubjectStatistics")) {
    //A subject view is open.
    List<Subject> sameSubjects = acP.person.activeSchoolYear.grades.subjects
        .where((subject) =>
            subject.name ==
            ModalRoute.of(context)!.settings.name!.split("/")[2])
        .toList();

    if (sameSubjects.isNotEmpty) {
      //A subject with the same name has been found
      Navigate().replace(
          context,
          SubjectStatisticsView(
            subject: sameSubjects.first,
          ),
          "SubjectStatistics/${sameSubjects.first.id}/${sameSubjects.first.name}");
    } else {
      //A subject with the same name has not been found, returning to yearly stats.
      Navigator.pop(context);
    }
  }
}

void changeProfile(BuildContext context, {required int newid}) {
  final AccountProvider acP =
      Provider.of<AccountProvider>(context, listen: false);
  acP.changeAccount(newid);

  if (acP.person.activeSchoolYear.grades.isEmpty) {
    //No grades, show message
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => FetchWeightsScreen(
              account: acP.account,
              customContinue: () {
                Navigator.of(context).pop();
                acP.changeSchoolYear(acP.person.activeSchoolYear.id);
              },
              forcedEnabledId: acP.person.activeSchoolYear.id,
            )));
  }

  //Is the subject view open?
  if (ModalRoute.of(context)!.settings.name != null &&
      ModalRoute.of(context)!.settings.name!.contains("SubjectStatistics")) {
    //Check if new active profile has same subject as opened.
    Person newActiveProfile = AccountManager()
        .personList
        .firstWhere((person) => person.uuid == newid);
    List<Subject> sameSubjects = newActiveProfile
        .activeSchoolYear.grades.subjects
        .where((subject) =>
            subject.name ==
            ModalRoute.of(context)!.settings.name!.split("/")[2])
        .toList();

    if (sameSubjects.isNotEmpty) {
      //A subject with the same name has been found

      //Current active QuarterCode filters are compared to the new possible QuarterCode filters
      Set<String> activeQuarterCodeFilters = newActiveProfile.activeFilters
          .where((filter) => filter.type == FilterTypes.quarterCode)
          .map((e) => e.filter.toString())
          .toSet();

      Set<String> newPossibleQuarterCodes = sameSubjects.first.grades
          .map((e) => e.schoolQuarter!.id.toString())
          .toSet();

      Set<String> toBeDisabledFilters =
          activeQuarterCodeFilters.difference(newPossibleQuarterCodes);

      //Removing all the filters that are not usefull
      newActiveProfile.activeFilters.removeWhere((filter) =>
          filter.type == FilterTypes.quarterCode &&
          toBeDisabledFilters.contains(filter.filter));

      Navigate().replace(
          context,
          SubjectStatisticsView(
            subject: sameSubjects.first,
          ),
          "SubjectStatistics/${sameSubjects.first.id}/${sameSubjects.first.name}");
    } else {
      //A subject with the same name has not been found, returning to yearly stats.
      Navigator.pop(context);
    }
  }
}

class Navigate {
  static String oldName = "";

  void to(BuildContext context, Widget route, String name) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => route, settings: RouteSettings(name: name)));
  }

  void replace(BuildContext context, Widget route, String name) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => route, settings: RouteSettings(name: name)));
  }

  void replaceAll<T extends Object?>(
      BuildContext context, Widget route, String name) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => route, settings: RouteSettings(name: name)));
  }
}

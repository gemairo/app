import 'package:flutter/material.dart';
import 'package:gemairo/apis/ads.dart';
import 'package:gemairo/screens/career.dart';
import 'package:gemairo/widgets/bottom_sheet.dart';
import 'package:gemairo/widgets/card.dart';
import 'package:gemairo/widgets/filter.dart';
import 'package:gemairo/widgets/global/skeletons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';

import 'package:gemairo/widgets/cards/list_grade.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchView();
}

class _SearchView extends State<SearchView> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Ads.instance?.handleNavigate('search');
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
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);
    List<Grade> useable = acP.person.allGrades.onlyFilterd([
      if (controller.text != "" || acP.person.activeFilters.isEmpty)
        Filter(
            name: "SearchValue",
            type: FilterTypes.inputString,
            filter: controller.text),
      ...acP.activeFilters(isGlobal: true)
    ]);

    void textfieldToFilter() => setState(() {
          if (controller.text != "") {
            acP.addToFilter(
                Filter(
                    name: "SearchValue",
                    type: FilterTypes.inputString,
                    filter: controller.text),
                isGlobal: true);
          }
          controller.clear();
        });

    return ScaffoldSkeleton(
      onRefresh: () async {
        AccountProvider acP =
            Provider.of<AccountProvider>(context, listen: false);
        await acP.account.api.refreshAll(acP.person);
        acP.changeAccount(null);
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: GemairoCard(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: TextField(
                controller: controller,
                onChanged: (value) => setState(() {}),
                onTapOutside: (event) =>
                    FocusScope.of(context).requestFocus(FocusNode()),
                onSubmitted: (value) =>
                    value != "" ? textfieldToFilter() : null,
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Wrap(children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            controller.clear();
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                      GradeListOptions(
                        addOrRemoveBadge: addOrRemoveBadge,
                      )
                    ]),
                    border: InputBorder.none,
                    hintText: AppLocalizations.of(context)!
                        .searchForGradesdescriptionsAndTeachers,
                    filled: false),
              ),
            ),
          ),
        ),
        FilterChips(
          isGlobal: true,
          grades: acP.person.allGrades,
          extraButtons: [
            if (controller.text != "")
              FilterChip(
                  label: Text(AppLocalizations.of(context)!.add),
                  avatar: Icon(Icons.add,
                      color: Theme.of(context).colorScheme.primary),
                  onSelected: (value) => textfieldToFilter(),
                  selected: false),
            FilterChip(
                label: Text(AppLocalizations.of(context)!.seeStatistics),
                avatar: Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onSelected: (value) {
                  textfieldToFilter();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CareerOverview(),
                      ));
                },
                selected: false)
          ],
        ),
        const SizedBox(height: 10),
        ...useable
            .sortByDate((e) => e.addedDate, doNotSort: true)
            .entries
            .map(
              (e) => Column(children: [
                ListTile(
                  title: Text(e.key,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary)),
                  dense: true,
                ),
                ...e.value.map((e) => GradeTile(
                      grade: e,
                      grades: useable,
                      onTap: () => showGemairoModalBottomSheet(children: [
                        GradeInformation(
                          context: context,
                          grade: e,
                          grades: useable,
                          showGradeCalculate: true,
                        )
                      ], context: context),
                    ))
              ]),
            )
            .toList(),
      ],
    );
  }
}

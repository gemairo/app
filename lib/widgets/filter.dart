import 'package:flutter/material.dart';
import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';
import 'package:silvio/widgets/bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FilterChips extends StatefulWidget {
  const FilterChips(
      {super.key,
      this.grades = const [],
      this.isGlobal = false,
      this.extraButtons = const []});

  final List<Grade> grades;
  final bool isGlobal;
  final List<FilterChip> extraButtons;

  @override
  State<FilterChips> createState() => _FilterChips();
}

class _FilterChips extends State<FilterChips> {
  @override
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);
    List<Filter> activeFilters = acP.activeFilters(isGlobal: widget.isGlobal);
    List<Grade> quaters = widget.isGlobal
        ? []
        : widget.grades.unique((Grade gr) => gr.schoolQuarter?.id).toList()
      ..sort((a, b) => (b.schoolQuarter?.shortname ?? "")
          .toLowerCase()
          .compareTo(a.schoolQuarter?.shortname.toLowerCase() ?? ""));

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(spacing: 8, children: [
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: ActionChip(
                key: ValueKey<bool>(activeFilters.isNotEmpty),
                backgroundColor: activeFilters.isNotEmpty
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null,
                side: activeFilters.isNotEmpty
                    ? const BorderSide(style: BorderStyle.none)
                    : null,
                avatar: const Icon(Icons.filter_list),
                label: Text(AppLocalizations.of(context)!.filter),
                onPressed: () {
                  //Open filters
                  showSilvioModalBottomSheet(children: [
                    FilterMenu(
                      grades: widget.grades,
                      isGlobal: widget.isGlobal,
                    ),
                  ], context: context);
                },
              )),
          ...widget.extraButtons,
          if (activeFilters
              .map((f) => f.type)
              .contains(FilterTypes.inputString))
            ...activeFilters
                .where((filter) => filter.type == FilterTypes.inputString)
                .map(
              (filter) {
                return InputChip(
                  label: Text(filter.filter),
                  selected: true,
                  onDeleted: () {
                    setState(() {
                      acP.removeFromFilterWhere((activefilter) =>
                          activefilter.filter == filter.filter &&
                          activefilter.type == FilterTypes.inputString);
                    });
                  },
                );
              },
            ),
          if (widget.grades.useable.map((g) => g.isPTA).contains(true) &&
              widget.grades.useable.map((g) => g.isPTA).contains(false))
            FilterChip(
              label: const Text("PTA"),
              selected: activeFilters.map((f) => f.name).contains("PTA"),
              onSelected: (bool value) {
                setState(() {
                  if (value) {
                    acP.addToFilter(
                        Filter(
                            name: "PTA", type: FilterTypes.pta, filter: "PTA"),
                        isGlobal: widget.isGlobal);
                  } else {
                    acP.removeFromFilterWhere((filter) => filter.name == "PTA");
                  }
                });
              },
            ),
          ...quaters.map((sQ) => SilvioFilterChip(context,
              isGlobal: widget.isGlobal,
              filter: Filter(
                  name: sQ.schoolQuarter?.shortname ?? "*",
                  type: FilterTypes.quarterCode,
                  filter: sQ.schoolQuarter?.id.toString())))
        ]));
  }
}

class FilterMenu extends StatefulWidget {
  const FilterMenu({super.key, required this.grades, this.isGlobal = false});

  final List<Grade> grades;
  final bool isGlobal;

  @override
  State<FilterMenu> createState() => _FilterMenu();
}

class Filters {
  String? addition;
  List<Grade> quaters;
  List<Grade> subjects;
  List<Grade> teachers;

  Filters(
      {this.quaters = const [],
      this.subjects = const [],
      this.teachers = const [],
      this.addition});
}

class _FilterMenu extends State<FilterMenu> {
  final filterTextController = TextEditingController();

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);

    List<Map<String, List<Grade>>> gradesPerSchoolyear = widget.isGlobal
        ? acP.person.schoolYears
            .map((e) => {
                  e.groupCode: e.grades
                      .where((grade) => widget.grades.contains(grade))
                      .toList()
                })
            .toList()
        : [];

    List<Filters> filters = widget.isGlobal
        ? [
            ...gradesPerSchoolyear.map((e) => Filters(
                addition: e.keys.first,
                quaters: e.values.first.useable
                    .unique((Grade gr) => gr.schoolQuarter?.id)
                  ..sort((a, b) => (b.schoolQuarter?.shortname ?? "")
                      .toLowerCase()
                      .compareTo(
                          a.schoolQuarter?.shortname.toLowerCase() ?? "")),
                subjects: e.values.first.useable
                    .unique((Grade gr) => gr.subject.id)
                  ..sort((a, b) => a.subject.name.compareTo(b.subject.name)),
                teachers: e.values.first.useable
                    .where((g) => g.teacherCode != null)
                    .toList()
                    .unique((Grade gr) => gr.teacherCode)
                  ..sort((a, b) => a.teacherCode!.compareTo(b.teacherCode!))))
          ]
        : [
            Filters(
                quaters: widget.grades.useable
                    .unique((Grade gr) => gr.schoolQuarter?.id)
                  ..sort((a, b) => (b.schoolQuarter?.shortname ?? "")
                      .toLowerCase()
                      .compareTo(
                          a.schoolQuarter?.shortname.toLowerCase() ?? "")),
                subjects: widget.grades.useable
                    .unique((Grade gr) => gr.subject.id)
                  ..sort((a, b) => a.subject.name.compareTo(b.subject.name)),
                teachers: widget.grades.useable
                    .where((g) => g.teacherCode != null)
                    .toList()
                    .unique((Grade gr) => gr.teacherCode)
                  ..sort((a, b) => a.teacherCode!.compareTo(b.teacherCode!)))
          ];

    List<Filter> activeFilters = acP.activeFilters(isGlobal: widget.isGlobal);

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.filters,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            trailing: IconButton(
                onPressed: () {
                  acP.removeFromFilterWhere(
                      (f) => widget.isGlobal ? true : !f.isGlobal);
                },
                icon: const Icon(Icons.undo)),
            dense: true,
          ),
          if (filters.length > 1 || filters.first.quaters.length > 1)
            ...filters.map((filter) => SilvioFilterChipList(
                    title: AppLocalizations.of(context)!.periods +
                        (filter.addition != null
                            ? " (${filter.addition})"
                            : ""),
                    icon: const Icon(Icons.calendar_month),
                    widgets: [
                      ...filter.quaters.map((Grade grade) => SilvioFilterChip(
                          context,
                          isGlobal: widget.isGlobal,
                          filter: Filter(
                              name: grade.schoolQuarter?.shortname ?? "*",
                              type: FilterTypes.quarterCode,
                              filter: grade.schoolQuarter?.id.toString())))
                    ])),
          if (filters.length > 1 || filters.first.subjects.length > 1)
            ...filters.map((filter) => SilvioFilterChipList(
                    title: AppLocalizations.of(context)!.subjects +
                        (filter.addition != null
                            ? " (${filter.addition})"
                            : ""),
                    icon: const Icon(Icons.book_outlined),
                    widgets: [
                      ...filter.subjects.map((Grade grade) => SilvioFilterChip(
                          context,
                          isGlobal: widget.isGlobal,
                          filter: Filter(
                              name: grade.subject.name,
                              type: FilterTypes.subject,
                              filter: grade.subject.id.toString())))
                    ])),
          if (filters.length > 1 || filters.first.teachers.length > 1)
            ...filters.map((filter) => SilvioFilterChipList(
                    title: AppLocalizations.of(context)!.teachers +
                        (filter.addition != null
                            ? " (${filter.addition})"
                            : ""),
                    icon: const Icon(Icons.supervisor_account),
                    widgets: [
                      ...filter.teachers.map((Grade grade) => SilvioFilterChip(
                          context,
                          isGlobal: widget.isGlobal,
                          filter: Filter(
                              name: grade.teacherCode!,
                              type: FilterTypes.teacher,
                              filter: grade.teacherCode!)))
                    ])),
          SilvioFilterChipList(
              title: AppLocalizations.of(context)!.dateRange,
              icon: const Icon(Icons.date_range_outlined),
              widgets: [
                ActionChip(
                  label: Text(AppLocalizations.of(context)!.add),
                  avatar: const Icon(Icons.add),
                  onPressed: () async {
                    DateTimeRange? pickedRange = await showDateRangePicker(
                      context: context,
                      firstDate: widget.grades
                              .onlyFilterd(activeFilters)
                              .isNotEmpty
                          ? widget.grades
                              .onlyFilterd(activeFilters
                                  .where((f) => f.type != FilterTypes.dateRange)
                                  .toList())
                              .last
                              .addedDate
                          : DateTime.parse("1970-01-01T00:00:00.0000000Z"),
                      lastDate: widget.grades
                              .onlyFilterd(activeFilters)
                              .isNotEmpty
                          ? widget.grades
                              .onlyFilterd(activeFilters
                                  .where((f) => f.type != FilterTypes.dateRange)
                                  .toList())
                              .first
                              .addedDate
                          : DateTime.now(),
                      currentDate: DateTime.now(),
                    );
                    if (pickedRange != null) {
                      setState(() {
                        acP.addToFilter(
                            Filter(
                                name:
                                    "${DateFormat.yMd('nl').format(pickedRange.start)} - ${DateFormat.yMd('nl').format(pickedRange.end)}", //2020/12/12 - 2020/12/13
                                type: FilterTypes.dateRange,
                                filter: pickedRange),
                            isGlobal: widget.isGlobal);
                      });
                    }
                  },
                ),
                ...activeFilters
                    .where((filter) => filter.type == FilterTypes.dateRange)
                    .map((filter) => InputChip(
                          label: Text(filter.name),
                          selected: true,
                          onDeleted: () {
                            setState(() {
                              acP.removeFromFilterWhere((activefilter) =>
                                  activefilter.filter == filter.filter &&
                                  activefilter.type == FilterTypes.dateRange);
                            });
                          },
                        ))
              ]),
          if (activeFilters
                  .map((f) => f.type)
                  .contains(FilterTypes.inputString) ||
              widget.grades.useable.map((g) => g.isPTA).contains(true) &&
                  widget.grades.useable.map((g) => g.isPTA).contains(false))
            SilvioFilterChipList(
                title: AppLocalizations.of(context)!.other,
                icon: const Icon(Icons.filter_alt_outlined),
                widgets: [
                  if (widget.grades.useable
                          .map((g) => g.isPTA)
                          .contains(true) &&
                      widget.grades.useable
                          .map((g) => g.isPTA)
                          .contains(false)) ...[
                    FilterChip(
                      label: const Text("PTA"),
                      selected:
                          activeFilters.map((f) => f.name).contains("PTA"),
                      onSelected: (bool value) {
                        setState(() {
                          if (value) {
                            acP.addToFilter(
                                Filter(
                                    name: "PTA",
                                    type: FilterTypes.pta,
                                    filter: "PTA"),
                                isGlobal: widget.isGlobal);
                          } else {
                            acP.removeFromFilterWhere(
                                (filter) => filter.name == "PTA");
                          }
                        });
                      },
                    ),
                  ],
                  if (activeFilters
                      .map((f) => f.type)
                      .contains(FilterTypes.inputString))
                    ...activeFilters
                        .where(
                            (filter) => filter.type == FilterTypes.inputString)
                        .map(
                      (filter) {
                        return InputChip(
                          label: Text(filter.filter),
                          selected: true,
                          onDeleted: () {
                            setState(() {
                              acP.removeFromFilterWhere((activefilter) =>
                                  activefilter.filter == filter.filter &&
                                  activefilter.type == FilterTypes.inputString);
                            });
                          },
                        );
                      },
                    )
                ]),
          ListTile(
              leading: const SizedBox(
                  height: double.infinity, child: Icon(Icons.search)),
              title: TextField(
                controller: filterTextController,
                onTapOutside: (event) =>
                    FocusScope.of(context).requestFocus(FocusNode()),
                decoration: InputDecoration(
                    filled: false,
                    isDense: true,
                    hintText: AppLocalizations.of(context)!.filterFor,
                    suffix: TextButton.icon(
                        onPressed: () {
                          if (filterTextController.text == "") return;
                          setState(() {
                            acP.addToFilter(
                              Filter(
                                  name: "TextSearch",
                                  type: FilterTypes.inputString,
                                  filter: filterTextController.text),
                              isGlobal: widget.isGlobal,
                            );
                            filterTextController.clear();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context)!.add))),
                onSubmitted: (string) {
                  if (string == "") return;
                  setState(() {
                    acP.addToFilter(
                      Filter(
                          name: "TextSearch",
                          type: FilterTypes.inputString,
                          filter: string),
                      isGlobal: widget.isGlobal,
                    );
                    filterTextController.clear();
                  });
                },
              ))
        ]));
  }
}

class SilvioFilterChipList extends StatelessWidget {
  const SilvioFilterChipList(
      {super.key, required this.title, this.icon, this.widgets = const []});

  final String title;
  final Icon? icon;
  final List<Widget> widgets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
            leading: icon,
            title: Text(
              title,
            )),
        Wrap(spacing: 8, children: widgets),
      ],
    );
  }
}

class SilvioFilterChip extends StatefulWidget {
  const SilvioFilterChip(context,
      {super.key, required this.filter, this.isGlobal = false});

  final Filter filter;
  final bool isGlobal;

  @override
  State<SilvioFilterChip> createState() => _SilvioFilterChip();
}

class _SilvioFilterChip extends State<SilvioFilterChip> {
  @override
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);
    List<Filter> activeFilters = acP.activeFilters(isGlobal: widget.isGlobal);
    return FilterChip(
      label: Text(widget.filter.name),
      selected:
          activeFilters.map((e) => e.filter).contains(widget.filter.filter),
      onSelected: (bool value) {
        setState(() {
          if (value) {
            if (!activeFilters
                .map((e) => e.filter)
                .contains(widget.filter.filter)) {
              acP.addToFilter(
                widget.filter,
                isGlobal: widget.isGlobal,
              );
            }
          } else {
            acP.removeFromFilterWhere(
                (afilter) => afilter.filter == widget.filter.filter);
          }
        });
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:silvio/widgets/card.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';
import 'package:silvio/widgets/bottom_sheet.dart';

class TestList extends StatelessWidget {
  const TestList({super.key, required context, this.calendarEvents = const []});
  final List<CalendarEvent> calendarEvents;

  @override
  Widget build(BuildContext context) {
    // initializeDateFormatting('nl');
    return Column(children: [
      ...calendarEvents.tests
          .where((test) => test.end.isAfter(DateTime.now()))
          .toList()
          .sortPerDay()
          .entries
          .take(10)
          .map((day) => ListTile(
                title: Text(
                  DateFormat.yMMMMEEEEd('nl').format(day.key.toLocal()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Column(
                  children: [
                    ...day.value.map((test) => ListTile(
                        title: Text(
                          test.subjectsNames.join(", "),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        leading: CircleAvatar(
                            radius: 25,
                            child: Text(
                              test.infoTypeString(context, short: true),
                            )),
                        subtitle: Text(
                          test.description?.split('\n')[0] ?? "",
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => showSilvioModalBottomSheet(children: [
                              EventInformation(context: context, event: test)
                            ], context: context),
                        trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Badge(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                label: Text(
                                  test.start.countdownString(context),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                            ])))
                  ],
                ),
              ))
    ]);
  }
}

class EventInformation extends StatelessWidget {
  const EventInformation({super.key, required context, required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ListTile(
        title: Text(event.subjectsNames.join(", ")),
        subtitle: Text(
            "${event.startHour}: ${event.infoTypeString(context)} in ${event.locations.join(", ")}"),
        trailing:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Badge(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            label: Text(
              event.start.countdownString(context),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ]),
        leading: CircleAvatar(
            foregroundColor: event.isFinished
                ? Theme.of(context).colorScheme.onTertiaryContainer
                : null,
            radius: 25,
            backgroundColor: event.isFinished
                ? Theme.of(context).colorScheme.tertiaryContainer
                : null,
            child: Text(
              event.infoTypeString(context, short: true),
            )),
      ),
      ListTile(
        title: Text(
            DateFormat.yMMMMd('nl').add_jm().format(event.start.toLocal())),
        leading: const Icon(Icons.calendar_today),
      ),
      ListTile(
        title: Text(event.infoTypeString(context)),
        leading: const Icon(Icons.type_specimen),
      ),
      if (event.teacherNames.isNotEmpty)
        ListTile(
          title: Text(event.teacherNames.join(", ")),
          leading: const Icon(Icons.supervisor_account),
        ),
      if (event.description != null && event.description != "")
        ListTile(
          title: Text(event.description!),
          leading: const Icon(Icons.text_fields),
        ),
    ]);
  }
}

class UpcomingTestsCard extends StatelessWidget {
  const UpcomingTestsCard({super.key, required this.calendarEvents});

  final List<CalendarEvent> calendarEvents;

  @override
  Widget build(BuildContext context) {
    List<CalendarEvent> tests = calendarEvents.tests
        .where((test) => test.end.isAfter(DateTime.now()))
        .toList();

    return CarouselCard(
      title: AppLocalizations.of(context)!.oncomingTests,
      children: tests.isNotEmpty
          ? tests
              .map((event) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(32)),
                        onTap: () => showSilvioModalBottomSheet(children: [
                              EventInformation(
                                context: context,
                                event: event,
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
                                  child: CircleAvatar(
                                      radius: 25,
                                      child: Text(
                                        event.infoTypeString(context,
                                            short: true),
                                      )),
                                )),
                            Text(
                              event.subjectsNames.join(", "),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              "in ${event.start.countdownString(context)}",
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
                      AppLocalizations.of(context)!.noOncomingTests,
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

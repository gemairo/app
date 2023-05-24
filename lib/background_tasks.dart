part of 'main.dart';

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    Hive.close();
    return;
  }
  print('[BackgroundFetch] Headless event received.');
  await initHive();
  await Hive.openBox<Config>('config');
  await Hive.openBox<Account>('accountList');
  await backgroundCheck();
  BackgroundFetch.finish(taskId);
  // Hive.close();
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

Future<void> backgroundCheck() async {
  if (config.enableNotifications != true) return;
  List<Account> accountsToCheck = AccountManager().accountsList;

  await Future.forEach(accountsToCheck, (account) async {
    Api api = account.api;

    await Future.forEach(
        account.profiles.where((person) => person.config.useForGradeCheck),
        (person) async {
      //Save current grade list
      List<Grade> beforeFetchLatestGrades =
          List.of(person.schoolYears.allGrades.useable).toList();
      //Refresh grade list
      await Future.wait(person.schoolYears.map(
          (SchoolYear sY) => api.refreshSchoolYear(person, sY, (i, t) {})));
      //Save new grade list
      List<Grade> afterFetchLatestGrades =
          List.of(person.schoolYears.allGrades.useable);
      List<Grade> difference = afterFetchLatestGrades
        ..removeWhere((grade) =>
            beforeFetchLatestGrades.map((e) => e.id).contains(grade.id));
      if (difference.isNotEmpty) {
        print(
            "Er zijn ${difference.length} nieuwe cijfers voor ${person.firstName}");
        FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();
        bool showPersonName = (AccountManager()
                .personList
                .where((person) => person.config.useForGradeCheck)
                .toList()
                .length >
            1);
        await flutterLocalNotificationsPlugin.show(
            person.uuid,
            'Nieuwe cijfers in Silvio',
            difference.length == 1 ||
                    difference.subjects.every(
                        (subject) => subject.id == difference.first.subject.id)
                ? 'Er is een nieuw cijfer van ${difference.first.subject.name} beschikbaar${showPersonName ? " voor ${person.firstName}" : ""} '
                : 'Er zijn ${difference.length} nieuwe cijfers beschikbaar${showPersonName ? " voor ${person.firstName}" : ""}',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                  "SilvioGrades", "Nieuwe cijfers",
                  channelDescription:
                      "Ontvang een bericht zodra er een nieuw cijfer beschikbaar is!",
                  importance: Importance.high,
                  priority: Priority.high,
                  groupKey: "SilvioGrades",
                  icon: 'notification'),
              iOS: DarwinNotificationDetails(threadIdentifier: "SilvioGrades"),
            ),
            payload: "${person.uuid}-grade");
      }
    });

    await Future.forEach(
        account.profiles.where((person) => person.config.useForTestCheck),
        (person) async {
      //Save current test list
      List<CalendarEvent> beforeFetchTests =
          List.of(person.calendarEvents.tests).toList();
      //Refresh tests list
      await api.refreshCalendarEvents(person);
      //Save new test list
      List<CalendarEvent> afterFetchTests =
          List.of(person.calendarEvents.tests).toList();
      List<CalendarEvent> difference = afterFetchTests
        ..removeWhere((event) =>
            beforeFetchTests.map((e) => e.id).contains(event.id));
      if (difference.isNotEmpty) {
        FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();
        bool showPersonName = (AccountManager()
                .personList
                .where((person) => person.config.useForTestCheck)
                .toList()
                .length >
            1);
        await flutterLocalNotificationsPlugin.show(
            person.uuid,
            'Silvio heeft nieuwe toetsen gevonden',
            difference.length == 1 ||
                    difference.map((e) => e.subjectsNames).every(
                        (subject) => subject == difference.first.subjectsNames)
                ? 'Er is een nieuw toets van ${difference.first.subjectsNames.join(" ")} beschikbaar${showPersonName ? " voor ${person.firstName}" : ""} '
                : 'Er zijn ${difference.length} nieuwe cijfers beschikbaar${showPersonName ? " voor ${person.firstName}" : ""}',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                  "SilvioTests", "Nieuwe toetsen",
                  channelDescription:
                      "Ontvang een bericht zodra er een nieuwe toets gevonden is!",
                  importance: Importance.high,
                  priority: Priority.high,
                  groupKey: "SilvioTests",
                  icon: 'notification'),
              iOS: DarwinNotificationDetails(threadIdentifier: "SilvioTests"),
            ),
            payload: "${person.uuid}-test");
      }
    });
  });
}

Future<void> initPlatformState() async {
  // Configure BackgroundFetch.
  int status = await BackgroundFetch.configure(
      BackgroundFetchConfig(
          minimumFetchInterval: 30,
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.ANY), (String taskId) async {
    print("[BackgroundFetch] Event received $taskId");
    await backgroundCheck();
    BackgroundFetch.finish(taskId);
  }, (String taskId) async {
    print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
    BackgroundFetch.finish(taskId);
  });
  print('[BackgroundFetch] configure success: $status');
  //Load latestdata on opening
  backgroundCheck();
}

void loadLatestData() {
  List<Account> accountsToCheck = AccountManager().accountsList;
  Future.forEach(accountsToCheck, (account) async {
    Api api = account.api;
    Future.forEach(account.profiles, (person) async {
      await Future.wait(person.schoolYears.map(
          (SchoolYear sY) => api.refreshSchoolYear(person, sY, (i, t) {})));
      api.refreshCalendarEvents(person);
    });
  });
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:silvio/apis/abstact_api.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/main.dart';
import 'package:hive/hive.dart';

Random random = Random();

String _generateRandomString(length) {
  var r = Random.secure();
  var chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  return Iterable.generate(length, (_) => chars[r.nextInt(chars.length)])
      .join();
}

class RandomAccount implements Api {
  @override
  Account account;
  RandomAccount(this.account);

  @override
  late bool isOnline = false;

  @override
  Future<void> refreshAll(Person person) async {}

  @override
  Future refreshGrade(Person person, Grade grade) async {
    grade = randomGrade(grade.subject);
  }

  @override
  Widget? buildConfig(BuildContext context, {required Person person}) {
    return null;
  }

  @override
  Widget buildLogin(BuildContext context) {
    account.apiType = AccountAPITypes.random;
    account.accountType = AccountTypes.other;
    account.apiStorage = null;
    account.id = random.nextInt(99999);
    account.profiles = List.generate(2, (index) {
      List<Subject> subjects =
          List.generate(random.nextInt(5) + 5, (index) => randomSubject());
      return Person(
          id: random.nextInt(99999),
          firstName: "Random",
          lastName: index.toString())
        ..config = (PersonConfig()..activeSchoolYearId = 0)
        ..rawSchoolYears = List.generate(
            5,
            (index) => SchoolYear(
                start: DateTime.now().add(Duration(days: 365 * index)),
                end: DateTime.now().add(Duration(days: 365 * (index + 1))),
                groupCode: index.toString(),
                groupName: "Klas $index",
                id: index,
                studyCode: "studyCode")
              ..grades = List.generate(
                  100,
                  (index) =>
                      randomGrade(subjects[random.nextInt(subjects.length)])))
        ..calendarEvents = List.generate(
            5,
            (index) => CalendarEvent(
                start: DateTime.now().add(Duration(
                    days: random.nextInt(12), hours: random.nextInt(24))),
                locations: ["12G"],
                end: DateTime.now().add(Duration(
                    days: random.nextInt(12), hours: random.nextInt(24))),
                endHour: 0,
                id: random.nextInt(999),
                isFinished: random.nextBool(),
                startHour: 0,
                subjectsNames: subjects
                    .map((e) => e.name)
                    .take(random.nextInt(2) + 1)
                    .toList(),
                teacherNames: ["Wod"],
                type: CalendarEventTypes.values[random.nextInt(6)]));
    });
    Hive.box<Account>('accountList').add(account);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const Start(),
      ));
    });
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Future<void> refreshCalendarEvents(Person person) async {}

  @override
  Future<void> refreshProfilePicture(Person person) async {}

  @override
  Future<void> refreshSchoolYear(Person person, SchoolYear schoolYear,
      void Function(int completed, int total) progress) async {}

  @override
  Future<void> logout() async {}
}

Subject randomSubject() {
  return Subject(
      code: _generateRandomString(3),
      name: _generateRandomString(6),
      id: random.nextInt(99999));
}

Grade randomGrade(Subject subject) {
  return Grade(
      gradeString: ((random.nextInt(90) + 10) / 10).toString(),
      weight: random.nextInt(3).toDouble() + 1,
      subject: subject,
      description: "Description for a ${subject.name} grade",
      addedDate: DateTime.now().subtract(Duration(days: random.nextInt(250))),
      counts: true,
      id: random.nextInt(9999),
      type: GradeType.grade,
      teacherCode: subject.name,
      schoolQuarter: SchoolQuarter(
          shortname: "SE",
          end: DateTime.now(),
          id: 0,
          name: "School examen",
          start: DateTime.now()),
      isPTA: random.nextBool(),
      sufficient: random.nextBool());
}

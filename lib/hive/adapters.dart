import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/apis/random.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:silvio/apis/abstact_api.dart';
import 'package:silvio/apis/magister.dart';
import 'package:silvio/apis/local_file.dart';
import 'package:silvio/apis/somtoday.dart';

part 'adapters.g.dart';

@HiveType(typeId: 1)
class Account extends HiveObject {
  @HiveField(0)
  int id;
  int get uuid => "$id${apiStorage?.baseUrl}$apiType".hashCode;
  @HiveField(1)
  late AccountTypes accountType;
  @HiveField(2)
  ApiStorage? apiStorage = ApiStorage();
  @HiveField(3)
  List<Person> profiles = [];
  @HiveField(4)
  Person? get activeProfile => profiles.isNotEmpty &&
          profiles.map((e) => e.uuid).contains(config.activeProfileId)
      ? profiles.firstWhere((profile) => profile.uuid == config.activeProfileId)
      : null;

  @HiveField(5)
  late AccountAPITypes apiType;
  Api get api {
    switch (apiType) {
      case AccountAPITypes.magister:
        return Magister(this);
      case AccountAPITypes.localFile:
        return LocalFile(this);
      case AccountAPITypes.somToDay:
        return SomToDay(this);
      case AccountAPITypes.random:
        return RandomAccount(this);
      default:
        return LocalFile(this);
    }
  }

  @HiveField(6)
  DateTime dateOfBirth = DateTime.now();
  late bool underAgeOfConsent =
      (DateTime.now().difference(dateOfBirth).inDays / 365) < 16;

  Account({this.id = 0});

  Account get copy {
    Account objectInstance = Account(id: id);
    objectInstance.accountType = accountType;
    objectInstance.apiStorage = apiStorage;
    objectInstance.profiles = profiles;
    objectInstance.apiType = apiType;
    return objectInstance;
  }
}

@HiveType(typeId: 2)
enum AccountTypes {
  @HiveField(0)
  student,
  @HiveField(1)
  parent,
  @HiveField(2)
  other
}

@HiveType(typeId: 3)
enum AccountAPITypes {
  @HiveField(0)
  localFile,
  @HiveField(1)
  magister,
  @HiveField(2)
  somToDay,
  @HiveField(3)
  random
}

@HiveType(typeId: 4)
class ApiStorage {
  @HiveField(1)
  String? accessToken;
  @HiveField(2)
  String? refreshToken;
  @HiveField(3)
  String? idToken;
  @HiveField(4)
  int? expiry;
  @HiveField(5)
  String baseUrl = "";
}

@HiveType(typeId: 5)
class Person {
  @HiveField(0)
  String firstName = "";
  @HiveField(1)
  String lastName = "";
  @HiveField(2)
  int id;
  int get uuid => "$id${parentAccount?.uuid}".hashCode;
  @HiveField(3)
  String? profilePicture;
  @HiveField(4)
  List<SchoolYear> rawSchoolYears = [];
  @HiveField(5)
  List<CalendarEvent> calendarEvents = [];
  @HiveField(6)
  PersonConfig config = PersonConfig();
  List<Filter> activeFilters = [];

  List<SchoolYear> get schoolYears =>
      rawSchoolYears.where((sY) => sY.isEnabled).toList();
  SchoolYear get activeSchoolYear {
    return schoolYears
            .firstWhereOrNull((p) => p.id == config.activeSchoolYearId) ??
        schoolYears.firstOrNull ??
        rawSchoolYears.first;
  }

  List<Grade> get allGrades => schoolYears.expand((y) => y.grades).toList();

  Account? get parentAccount => AccountManager()
      .accountsList
      .firstWhereOrNull((account) => account.profiles.contains(this));
  void save() => parentAccount!.save();

  Person({
    required this.id,
    required this.firstName,
    this.lastName = "",
    this.profilePicture
  });
}

@HiveType(typeId: 6)
class PersonConfig {
  @HiveField(0)
  late int activeSchoolYearId;
  @HiveField(1)
  bool useForGradeCheck = true;
  @HiveField(2, defaultValue: false)
  bool useForTestCheck = false;
}

enum FilterTypes { quarterCode, subject, teacher, inputString, pta, dateRange }

class Filter {
  late String name;
  late FilterTypes type;
  late dynamic filter;

  Filter({required this.name, required this.type, required this.filter});
}

@HiveType(typeId: 7)
class Grade {
  @HiveField(0)
  String gradeString;
  double get grade => double.tryParse(gradeString.replaceAll(',', '.')) ?? -1;
  @HiveField(1)
  double weight;
  @HiveField(2)
  Subject subject;
  @HiveField(3)
  String description;
  @HiveField(4)
  DateTime addedDate;
  @HiveField(5)
  bool isPTA;
  @HiveField(6)
  String? teacherCode;
  @HiveField(7)
  GradeType type;
  @HiveField(8)
  bool counts;
  @HiveField(9)
  bool sufficient;
  bool get isSufficient =>
      (num.tryParse(gradeString.replaceAll(',', '.')) != null)
          ? config.sufficientFrom <= grade
          : sufficient;
  @HiveField(10)
  SchoolQuarter? schoolQuarter;
  @HiveField(11)
  int id;
  @HiveField(12)
  bool isEnabled;

  Grade(
      {required this.gradeString,
      required this.weight,
      required this.subject,
      this.description = "",
      required this.addedDate,
      required this.counts,
      required this.id,
      this.isEnabled = true,
      required this.isPTA,
      this.schoolQuarter,
      required this.sufficient,
      this.teacherCode = "Unknown",
      this.type = GradeType.other});
}

@HiveType(typeId: 8)
enum GradeType {
  @HiveField(0)
  grade,
  @HiveField(1)
  average,
  @HiveField(2)
  other
}

@HiveType(typeId: 9)
class Subject {
  @HiveField(0)
  String code;
  @HiveField(1)
  String name;
  @HiveField(2)
  int? id;
  List<Grade> grades = [];

  Subject({required this.code, this.id, required this.name});

  Subject get copy {
    return Subject(code: code, name: name, id: id)..grades = grades;
  }
}

@HiveType(typeId: 10)
class SchoolQuarter {
  @HiveField(0)
  DateTime start;
  @HiveField(1)
  DateTime end;
  @HiveField(2)
  int id;
  @HiveField(3)
  String shortname;
  @HiveField(4)
  String name;

  SchoolQuarter({
    required this.shortname,
    required this.end,
    required this.id,
    required this.name,
    required this.start,
  });
}

@HiveType(typeId: 11)
class SchoolYear {
  @HiveField(0)
  late DateTime start;
  @HiveField(1)
  late DateTime end;
  @HiveField(2)
  late int id;
  @HiveField(3)
  late String groupCode;
  @HiveField(4)
  late String groupName;
  @HiveField(5)
  late String studyCode;
  @HiveField(6)
  List<Grade> grades = [];
  @HiveField(7)
  List<SchoolQuarter> schoolQuarters = [];
  @HiveField(8)
  bool isEnabled;

  SchoolYear(
      {required this.start,
      required this.end,
      required this.groupCode,
      required this.groupName,
      required this.id,
      this.isEnabled = true,
      required this.studyCode});
}

@HiveType(typeId: 12)
class CalendarEvent {
  @HiveField(0)
  late DateTime start;
  @HiveField(1)
  late DateTime end;
  @HiveField(2)
  late int startHour;
  @HiveField(3)
  late int endHour;
  @HiveField(4)
  late List<String> subjectsNames;
  @HiveField(5)
  late String? description;
  @HiveField(6)
  late List<String> locations;
  @HiveField(7)
  late List<String> teacherNames;
  @HiveField(8)
  late bool isFinished;
  @HiveField(9)
  late int id;
  @HiveField(10)
  late CalendarEventTypes type;

  CalendarEvent(
      {required this.start,
      required this.locations,
      this.description,
      required this.end,
      required this.endHour,
      required this.id,
      required this.isFinished,
      required this.startHour,
      required this.subjectsNames,
      required this.teacherNames,
      required this.type});

  String infoTypeString(context, {bool short = false}) {
    switch (type) {
      case CalendarEventTypes.homework:
        return short ? "HW" : AppLocalizations.of(context)!.homework;
      case CalendarEventTypes.test:
        return short ? "PW" : AppLocalizations.of(context)!.test;
      case CalendarEventTypes.exam:
        return short ? "T" : AppLocalizations.of(context)!.exam;
      case CalendarEventTypes.writtenExam:
        return short ? "SO" : AppLocalizations.of(context)!.writtenExam;
      case CalendarEventTypes.oralExam:
        return short ? "MO" : AppLocalizations.of(context)!.oralExam;
      case CalendarEventTypes.assignment:
        return short ? "PO" : AppLocalizations.of(context)!.assignment;
      default:
        return '?';
    }
  }
}

@HiveType(typeId: 13)
enum CalendarEventTypes {
  @HiveField(0)
  homework,
  @HiveField(1)
  test,
  @HiveField(2)
  exam,
  @HiveField(3)
  writtenExam,
  @HiveField(4)
  oralExam,
  @HiveField(5)
  assignment,
  @HiveField(6)
  other
}

Config get config {
  if (Hive.box<Config>('config').isEmpty) {
    Hive.box<Config>('config').add(Config());
  }
  return Hive.box<Config>('config').getAt(0)!;
}

@HiveType(typeId: 14)
class Config extends HiveObject {
  @HiveField(0)
  bool enableNotifications = false;
  @HiveField(1)
  bool darkMode = false;
  @HiveField(2)
  bool autoDarkMode = true;
  @HiveField(3)
  bool useMaterialYou = false;
  @HiveField(4)
  int activeMaterialYouColorInt = const Color(0xff6750a4).value;
  @HiveField(5)
  double sufficientFrom = 5.5;
  @HiveField(6)
  int? activeProfileId;
  @HiveField(7)
  String? usedLocaleCode;
  @HiveField(8)
  bool noAds = false;
  @HiveField(9, defaultValue: [])
  List<GradeListBadges> activeBadges = [];
}

@HiveType(typeId: 15)
enum GradeListBadges {
  @HiveField(0)
  pta,
  @HiveField(1)
  date,
  @HiveField(2)
  weight,
  @HiveField(3)
  changeInAverage,
  @HiveField(4)
  changeInAverageSubject
}
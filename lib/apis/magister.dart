import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:silvio/apis/abstact_api.dart';
import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';
import 'package:silvio/main.dart';
import 'package:silvio/widgets/card.dart';
import 'package:silvio/widgets/facts_header.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide CalendarEvent;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pointycastle/export.dart' as castle;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'package:silvio/apis/magister/screens/terms.dart';
part 'package:silvio/apis/magister/screens/login.dart';
part 'package:silvio/apis/magister/screens/config.dart';
part 'package:silvio/apis/magister/translate.dart';
part 'package:silvio/apis/magister/api.dart';

class Magister implements Api {
  @override
  Account account;
  Magister(this.account);

  late MagisterApi api = MagisterApi(account);

  @override
  late bool isOnline = true;

  @override
  Widget? buildConfig(BuildContext context, {required Person person}) {
    return null;
  }

  @override
  Widget buildLogin(BuildContext context) {
    return const Terms();
  }

  @override
  Future<void> refreshAll(Person person) async {
    await Future.wait([
      Future.wait(person.schoolYears.map(
          (SchoolYear sY) => api.refreshSchoolYear(person, sY, (i, t) {}))),
      api.refreshCalendarEvents(person),
      api.setSchoolYears(person)
    ]);
  }

  @override
  Future<void> refreshCalendarEvents(Person person) async {
    dynamic futures = await Future.wait([
      api.dio.get(
          "/api/personen/${person.id}/afspraken?status=1&tot=${DateTime.now().add(const Duration(days: 60)).toIso8601String()}&van=${DateTime.now().toIso8601String()}"),
      api.dio.get(
          "/api/personen/${person.id}/opdrachten?skip=0&top=250&einddatum=${DateTime.now().add(const Duration(days: 60)).toIso8601String()}&startdatum=${DateTime.now().toIso8601String()}"),
    ]);

    person.calendarEvents = (futures[0].data["Items"] as List)
        .map((event) => magisterCalendarEvent(event)!)
        .toList();

    person.calendarEvents.addAll((futures[1].data["Items"] as List)
        .map((assignment) => magisterAssignmentToCalendarEvent(assignment)!)
        .toList());

    for (CalendarEvent event in person.calendarEvents) {
      if (event.description != null) {
        event.description = event.description!
            .replaceAll('<br>', '\n')
            .replaceAll('</p>', '\n')
            .replaceAll('&nbsp;', ' ')
            .replaceAll(RegExp(r'<[^<>]+>'), '') //Remove remaining HTML tags
            .replaceAll(RegExp(r'^\s+|\s+$'),
                ''); //Remove whitespace at beginning and the end of the description
      }

      person.calendarEvents.sort((CalendarEvent a, CalendarEvent b) => a
          .start.millisecondsSinceEpoch
          .compareTo(b.start.millisecondsSinceEpoch));
    }

    if (account.isInBox) account.save();
  }

  @override
  Future<void> refreshGrade(Person person, Grade grade) async {
    SchoolYear schoolYear = person.schoolYears.firstWhere(
        (sY) => sY.grades.map((grade) => grade.id).contains(grade.id));

    dynamic newGradeData = await Future.wait([
      api.dio.get(
          "api/personen/${account.id}/aanmeldingen/${schoolYear.id}/cijfers/extracijferkolominfo/${grade.id}"),
      api.dio.get(
          "api/personen/${person.id}/aanmeldingen/${schoolYear.id}/cijfers/cijferoverzichtvooraanmelding?actievePerioden=false&alleenBerekendeKolommen=false&alleenPTAKolommen=false&peildatum=${schoolYear.end.toIso8601String()}"),
    ]);

    var rawNewGrade = (newGradeData[1].data["Items"] as List)
        .firstWhere((g) => g['CijferKolom']?["Id"] == grade.id);

    rawNewGrade["CijferKolom"]["KolomOmschrijving"] =
        newGradeData[0].data["WerkInformatieOmschrijving"] == ""
            ? newGradeData[0].data["KolomOmschrijving"]
            : newGradeData[0].data["WerkInformatieOmschrijving"] ??
                newGradeData[0].data["KolomOmschrijving"];
    rawNewGrade["CijferKolom"]["Weging"] = newGradeData[0].data["Weging"];

    Grade newGrade = magisterGrade(
        schoolYear.schoolQuarters.firstWhereOrNull(
            (sQ) => sQ.id == rawNewGrade["CijferPeriode"]?["Id"]),
        rawNewGrade)!;

    grade.addedDate = newGrade.addedDate;
    grade.counts = newGrade.counts;
    grade.description = newGrade.description;
    grade.gradeString = newGrade.gradeString;
    grade.isPTA = newGrade.isPTA;
    grade.schoolQuarter = newGrade.schoolQuarter;
    grade.subject = newGrade.subject;
    grade.teacherCode = newGrade.teacherCode;
    grade.type = newGrade.type;
    grade.weight = newGrade.weight;
  }

  @override
  Future<void> refreshProfilePicture(Person person) async {
    var img = (await api.dio.get(
      "api/leerlingen/${person.id}/foto",
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => [200, 404].contains(status),
      ),
    ));

    late String image;
    if (img.statusCode == 200) {
      image = base64Encode(img.data);
    }

    person.profilePicture = image;
    if (account.isInBox) account.save();
  }

  @override
  Future<void> refreshSchoolYear(Person person, SchoolYear schoolYear,
      void Function(int completed, int total) progress) async {
    //Get new grades from Magister
    List<dynamic> cijferoverzichtvooraanmelding = (await api.dio.get(
            "api/personen/${person.id}/aanmeldingen/${schoolYear.id}/cijfers/cijferoverzichtvooraanmelding?actievePerioden=false&alleenBerekendeKolommen=false&alleenPTAKolommen=false&peildatum=${schoolYear.end.toIso8601String()}"))
        .data["Items"];

    //Remove grades that do not exist on Magisters servers anymore
    schoolYear.grades.removeWhere((Grade grade) =>
        !cijferoverzichtvooraanmelding
            .map((e) => e["CijferKolom"]["Id"])
            .contains(grade.id));

    //Remove useless grades
    cijferoverzichtvooraanmelding.removeWhere((grade) =>
        !grade.keys.contains("CijferKolom") ||
        grade["CijferKolom"]["KolomSoort"] != 1);

    //Refresh grades that have been changed
    List toRemove = [];
    for (var rawGrade in cijferoverzichtvooraanmelding) {
      Grade? connectedGrade = schoolYear.grades.firstWhereOrNull(
          (grade) => grade.id == rawGrade["CijferKolom"]["Id"]);
      //If the grade already exists and the dates from Magister and the local database do not match, refresh the grade.
      if (DateTime.parse(rawGrade["DatumIngevoerd"] ??
                  rawGrade["ingevoerdOp"] ??
                  "1970-01-01T00:00:00.0000000Z")
              .toUtc() !=
          connectedGrade?.addedDate) {
        if (connectedGrade != null) refreshGrade(person, connectedGrade);
      }
      //If grade already exists in local database make the grade for removal
      if (connectedGrade != null &&
          rawGrade["CijferKolom"]["Id"] == connectedGrade.id) {
        toRemove.add(rawGrade);
      }
    }

    //Remove grades that were marked for removal
    cijferoverzichtvooraanmelding
        .removeWhere((rawGrade) => toRemove.contains(rawGrade));

    Future<void> addExtraData(Map<String, dynamic> grade) async {
      Map<String, dynamic> extracijferkolominfo = (await api.dio.get(
              "api/personen/${person.id}/aanmeldingen/${schoolYear.id}/cijfers/extracijferkolominfo/${grade["CijferKolom"]["Id"]}"))
          .data;

      grade["CijferKolom"]["KolomOmschrijving"] =
          extracijferkolominfo["WerkInformatieOmschrijving"] == ""
              ? extracijferkolominfo["KolomOmschrijving"]
              : extracijferkolominfo["WerkInformatieOmschrijving"] ??
                  extracijferkolominfo["KolomOmschrijving"];
      grade["CijferKolom"]["Weging"] = extracijferkolominfo["Weging"];
    }

    //For every grade in the schoolYear, get the weight and description
    await progressWait(
      [...cijferoverzichtvooraanmelding.map((e) => addExtraData(e))],
      progress,
    );

    //Convert all Magister grades to Silvio grades
    schoolYear.grades.addAll(cijferoverzichtvooraanmelding
        .map((cijfer) => magisterGrade(
            schoolYear.schoolQuarters.firstWhereOrNull(
                (sQ) => sQ.id == cijfer["CijferPeriode"]?["Id"]),
            cijfer)!)
        .where((cijfer) => cijfer.id > 0)
        .toList()
      ..sort((Grade a, Grade b) => a.addedDate.millisecondsSinceEpoch
          .compareTo(b.addedDate.millisecondsSinceEpoch))
      ..reversed.toList());

    if (account.isInBox) account.save();
  }

  @override
  Future<void> logout() async {
    await api.dio.get(
        'https://accounts.magister.net/connect/endsession?id_token_hint=${api.account.apiStorage!.idToken}');
  }
}

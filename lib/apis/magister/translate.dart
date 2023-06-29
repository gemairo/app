part of 'package:silvio/apis/magister.dart';

Grade? magisterGrade(SchoolQuarter? schoolQuarter, [Map? gotGrade]) {
  if (gotGrade != null) {
    String gradeType = (gotGrade["kolom"]?["type"] ??
        gotGrade["type"] ??
        (gotGrade['CijferKolom']?["KolomSoort"] == 1 ? "cijfer" : "Other") ??
        "Other");
    return Grade(
        addedDate: DateTime.parse(gotGrade["DatumIngevoerd"] ??
                gotGrade["ingevoerdOp"] ??
                "1970-01-01T00:00:00.0000000Z")
            .toUtc(),
        gradeString: gotGrade["CijferStr"] ?? gotGrade["waarde"] ?? "",
        counts: gotGrade["TeltMee"] ?? true,
        description: gotGrade["omschrijving"] ??
            gotGrade["kolom"]?["omschrijving"] ??
            gotGrade['CijferKolom']?["KolomOmschrijving"] ??
            "",
        id: gotGrade['CijferKolom']?["Id"] ?? -1,
        isPTA: gotGrade["CijferKolom"]?["IsPTAKolom"] ?? false,
        teacherCode: gotGrade["Docent"],
        type: gradeType == "cijfer"
            ? GradeType.grade
            : gradeType == "gemmiddelde"
                ? GradeType.average
                : GradeType.other,
        weight: gotGrade["kolom"]?["weegfactor"] ??
            gotGrade['CijferKolom']?['Weging'] ??
            gotGrade["weegfactor"] ??
            0,
        subject: magisterSubject(gotGrade["Vak"] ?? gotGrade["vak"])!,
        sufficient: gotGrade["IsVoldoende"] ?? gotGrade["isVoldoende"],
        schoolQuarter: schoolQuarter);
  }
  return null;
}

Subject? magisterSubject([Map? subject]) {
  if (subject != null) {
    return Subject(
        rawCode: subject["Afkorting"] ?? subject["code"],
        id: subject["Id"],
        rawName: (subject["Omschrijving"] ??
                subject["omschrijving"] ??
                subject["Naam"] ??
                "leeg")
            .toString()
            .capitalize());
  }
  return null;
}

SchoolQuarter? magisterSchoolQuarter([Map? per]) {
  if (per != null) {
    return SchoolQuarter(
      start: DateTime.parse(per["begin"] ?? "1970-01-01T00:00:00.0000000Z")
          .toUtc(),
      end: DateTime.parse(per["einde"] ?? "1970-01-01T00:00:00.0000000Z")
          .toUtc(),
      id: per["id"] ?? per["Id"],
      shortname: per["code"] ?? per["Code"],
      name: per["omschrijving"],
    );
  }
  return null;
}

SchoolYear? magisterSchoolYear([Map? year]) {
  if (year != null) {
    return SchoolYear(
        start: DateTime.parse(
          year["begin"] ?? "1970-01-01T00:00:00.0000000Z",
        ).toUtc(),
        end: DateTime.parse(year["einde"] ?? "1970-01-01T00:00:00.0000000Z")
            .toUtc(),
        id: year["id"],
        groupCode: year["groep"]["code"],
        groupName: year["groep"]["omschrijving"],
        studyCode: year["studie"]["code"],
        isEnabled: year["isHoofdAanmelding"],
        warningEnabled: DateTime.now().isBefore(
            DateTime.parse(year["einde"] ?? "1970-01-01T00:00:00.0000000Z")
                .toUtc()));
  }
  return null;
}

CalendarEvent? magisterAssignmentToCalendarEvent([Map? event]) {
  return CalendarEvent(
      locations: ["Magister"],
      description: event?["Omschrijving"],
      id: event?["Id"],
      isFinished: event?["Afgesloten"] ?? false,
      start: DateTime.parse(
              event?["InleverenVoor"] ?? "1970-01-01T00:00:00.0000000Z")
          .toUtc(),
      end: DateTime.parse(
              event?["InleverenVoor"] ?? "1970-01-01T00:00:00.0000000Z")
          .toUtc()
          .add(const Duration(hours: 1)),
      startHour: 0,
      endHour: 0,
      subjectsNames: [
        "${event?["Titel"] ?? ""} ${event?["Vak"] != null && event?["Vak"] != "" ? "(${event?["Vak"]})" : ""}"
      ],
      teacherNames: [], //Dankjewel Magister
      type: CalendarEventTypes.assignment);
}

CalendarEvent? magisterCalendarEvent([Map? event]) {
  if (event != null) {
    //MagIcal personal changes
    if (event["Aantekening"] != null &&
        (event["Aantekening"] as String).isBase64) {
      try {
        Map<String, dynamic> magIcal =
            jsonDecode(utf8.decode(base64.decode(event["Aantekening"])));
        event["Status"] = magIcal["Status"] != null &&
                magIcal["originalStatus"] == event["Status"]
            ? num.parse(magIcal["Status"])
            : event["Status"];
        event["InfoType"] = magIcal["InfoType"] != null &&
                magIcal["originalInfoType"] == event["InfoType"]
            ? num.parse(magIcal["InfoType"])
            : event["InfoType"];
        event["Lokalen"] = magIcal["Lokatie"] != null &&
                magIcal["originalLokatie"] ==
                    event["Lokalen"]
                        .map<String>((lokaal) => lokaal["Naam"].toString())
                        .toList()
                        .first
            ? [magIcal["Lokatie"]]
            : event["Lokalen"];
        event["Inhoud"] = magIcal["Inhoud"] != null &&
                magIcal["originalInhoud"] == event["Inhoud"]
            ? magIcal["Inhoud"]
            : event["Inhoud"];
        // ignore: empty_catches
      } catch (e) {
        //Whoops, no magIcal was used for this event...
      }
    }

    CalendarEventTypes generateType(status, infoType) {
      if (status != 4 && status != 5) {
        switch (infoType) {
          case 1:
            return CalendarEventTypes.homework;
          case 2:
            return CalendarEventTypes.test;
          case 3:
            return CalendarEventTypes.exam;
          case 4:
            return CalendarEventTypes.writtenExam;
          case 5:
            return CalendarEventTypes.oralExam;
          default:
            return CalendarEventTypes.other;
        }
      } else {
        return CalendarEventTypes.other;
      }
    }

    return CalendarEvent(
        locations: event["Lokalen"]
            .map<String>((lokaal) => lokaal["Naam"].toString())
            .toList(),
        description: event["Inhoud"] ?? "",
        end: DateTime.parse(event["Einde"] ?? "1970-01-01T00:00:00.0000000Z")
            .toUtc(),
        endHour: event["LesuurTotMet"] ?? 0,
        id: event["Id"],
        isFinished: event["Afgerond"],
        start: DateTime.parse(event["Start"] ?? "1970-01-01T00:00:00.0000000Z")
            .toUtc(),
        startHour: event["LesuurVan"] ?? event["LesuurTotMet"] ?? 0,
        subjectsNames: event["Vakken"].isNotEmpty
            ? event["Vakken"]
                .map<String>((vak) => vak["Naam"].toString().capitalize())
                .toList()
            : [event["Omschrijving"].split(" - ")[0]],
        teacherNames: event["Docenten"]
            .map<String>((teacher) => teacher["Naam"].toString())
            .toList(),
        type: generateType(event["Status"], event["InfoType"]));
  }
  return null;
}

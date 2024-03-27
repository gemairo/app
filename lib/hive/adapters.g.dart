// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adapters.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 1;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      id: fields[0] as int,
    )
      ..accountType = fields[1] as AccountTypes
      ..apiStorage = fields[2] as ApiStorage?
      ..profiles = (fields[3] as List).cast<Person>()
      ..apiType = fields[5] as AccountAPITypes
      ..dateOfBirth = fields[6] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountType)
      ..writeByte(2)
      ..write(obj.apiStorage)
      ..writeByte(3)
      ..write(obj.profiles)
      ..writeByte(5)
      ..write(obj.apiType)
      ..writeByte(6)
      ..write(obj.dateOfBirth)
      ..writeByte(4)
      ..write(obj.activeProfile);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ApiStorageAdapter extends TypeAdapter<ApiStorage> {
  @override
  final int typeId = 4;

  @override
  ApiStorage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiStorage()
      ..accessToken = fields[1] as String?
      ..refreshToken = fields[2] as String?
      ..idToken = fields[3] as String?
      ..expiry = fields[4] as int?
      ..baseUrl = fields[5] as String;
  }

  @override
  void write(BinaryWriter writer, ApiStorage obj) {
    writer
      ..writeByte(5)
      ..writeByte(1)
      ..write(obj.accessToken)
      ..writeByte(2)
      ..write(obj.refreshToken)
      ..writeByte(3)
      ..write(obj.idToken)
      ..writeByte(4)
      ..write(obj.expiry)
      ..writeByte(5)
      ..write(obj.baseUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiStorageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PersonAdapter extends TypeAdapter<Person> {
  @override
  final int typeId = 5;

  @override
  Person read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Person(
      id: fields[2] as int,
      firstName: fields[0] as String,
      lastName: fields[1] as String,
      profilePicture: fields[3] as String?,
    )
      ..rawSchoolYears = (fields[4] as List).cast<SchoolYear>()
      ..calendarEvents = (fields[5] as List).cast<CalendarEvent>()
      ..config = fields[6] as PersonConfig;
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.firstName)
      ..writeByte(1)
      ..write(obj.lastName)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.profilePicture)
      ..writeByte(4)
      ..write(obj.rawSchoolYears)
      ..writeByte(5)
      ..write(obj.calendarEvents)
      ..writeByte(6)
      ..write(obj.config);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PersonConfigAdapter extends TypeAdapter<PersonConfig> {
  @override
  final int typeId = 6;

  @override
  PersonConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersonConfig()
      ..activeSchoolYearId = fields[0] as int
      ..useForGradeCheck = fields[1] as bool
      ..useForTestCheck = fields[2] == null ? true : fields[2] as bool
      ..supportsAssignments = fields[3] == null ? true : fields[3] as bool;
  }

  @override
  void write(BinaryWriter writer, PersonConfig obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.activeSchoolYearId)
      ..writeByte(1)
      ..write(obj.useForGradeCheck)
      ..writeByte(2)
      ..write(obj.useForTestCheck)
      ..writeByte(3)
      ..write(obj.supportsAssignments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GradeAdapter extends TypeAdapter<Grade> {
  @override
  final int typeId = 7;

  @override
  Grade read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Grade(
      gradeString: fields[0] as String,
      weight: fields[1] as double,
      subject: fields[2] as Subject,
      description: fields[3] as String,
      addedDate: fields[4] as DateTime,
      counts: fields[8] as bool,
      id: fields[11] as int,
      isEnabled: fields[12] as bool,
      isPTA: fields[5] as bool,
      schoolQuarter: fields[10] as SchoolQuarter?,
      sufficient: fields[9] as bool,
      teacherCode: fields[6] as String?,
      type: fields[7] as GradeType,
    );
  }

  @override
  void write(BinaryWriter writer, Grade obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.gradeString)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.addedDate)
      ..writeByte(5)
      ..write(obj.isPTA)
      ..writeByte(6)
      ..write(obj.teacherCode)
      ..writeByte(7)
      ..write(obj.type)
      ..writeByte(8)
      ..write(obj.counts)
      ..writeByte(9)
      ..write(obj.sufficient)
      ..writeByte(10)
      ..write(obj.schoolQuarter)
      ..writeByte(11)
      ..write(obj.id)
      ..writeByte(12)
      ..write(obj.isEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubjectAdapter extends TypeAdapter<Subject> {
  @override
  final int typeId = 9;

  @override
  Subject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subject(
      rawCode: fields[0] as String,
      id: fields[2] as int?,
      rawName: fields[1] as String,
      customCode: fields[3] as String?,
      customName: fields[4] as String?,
      warningEnabled: fields[6] == null ? true : fields[6] as bool,
      roundOnDecimals: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.rawCode)
      ..writeByte(1)
      ..write(obj.rawName)
      ..writeByte(3)
      ..write(obj.customCode)
      ..writeByte(4)
      ..write(obj.customName)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(5)
      ..write(obj.roundOnDecimals)
      ..writeByte(6)
      ..write(obj.warningEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SchoolQuarterAdapter extends TypeAdapter<SchoolQuarter> {
  @override
  final int typeId = 10;

  @override
  SchoolQuarter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SchoolQuarter(
      shortname: fields[3] as String,
      end: fields[1] as DateTime,
      id: fields[2] as int,
      name: fields[4] as String,
      start: fields[0] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SchoolQuarter obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.start)
      ..writeByte(1)
      ..write(obj.end)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.shortname)
      ..writeByte(4)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolQuarterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SchoolYearAdapter extends TypeAdapter<SchoolYear> {
  @override
  final int typeId = 11;

  @override
  SchoolYear read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SchoolYear(
      start: fields[0] as DateTime,
      end: fields[1] as DateTime,
      groupCode: fields[3] as String,
      groupName: fields[4] as String,
      id: fields[2] as int,
      isEnabled: fields[8] as bool,
      studyCode: fields[5] as String,
      warningEnabled: fields[9] == null ? true : fields[9] as bool,
    )
      ..grades = (fields[6] as List).cast<Grade>()
      ..schoolQuarters = (fields[7] as List).cast<SchoolQuarter>();
  }

  @override
  void write(BinaryWriter writer, SchoolYear obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.start)
      ..writeByte(1)
      ..write(obj.end)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.groupCode)
      ..writeByte(4)
      ..write(obj.groupName)
      ..writeByte(5)
      ..write(obj.studyCode)
      ..writeByte(6)
      ..write(obj.grades)
      ..writeByte(7)
      ..write(obj.schoolQuarters)
      ..writeByte(8)
      ..write(obj.isEnabled)
      ..writeByte(9)
      ..write(obj.warningEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolYearAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalendarEventAdapter extends TypeAdapter<CalendarEvent> {
  @override
  final int typeId = 12;

  @override
  CalendarEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarEvent(
      start: fields[0] as DateTime,
      locations: (fields[6] as List).cast<String>(),
      description: fields[5] as String?,
      end: fields[1] as DateTime,
      endHour: fields[3] as int,
      id: fields[9] as int,
      isFinished: fields[8] as bool,
      startHour: fields[2] as int,
      subjectsNames: (fields[4] as List).cast<String>(),
      teacherNames: (fields[7] as List).cast<String>(),
      type: fields[10] as CalendarEventTypes,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarEvent obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.start)
      ..writeByte(1)
      ..write(obj.end)
      ..writeByte(2)
      ..write(obj.startHour)
      ..writeByte(3)
      ..write(obj.endHour)
      ..writeByte(4)
      ..write(obj.subjectsNames)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.locations)
      ..writeByte(7)
      ..write(obj.teacherNames)
      ..writeByte(8)
      ..write(obj.isFinished)
      ..writeByte(9)
      ..write(obj.id)
      ..writeByte(10)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConfigAdapter extends TypeAdapter<Config> {
  @override
  final int typeId = 14;

  @override
  Config read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Config()
      ..enableNotifications = fields[0] as bool
      ..darkMode = fields[1] as bool
      ..autoDarkMode = fields[2] as bool
      ..useMaterialYou = fields[3] as bool
      ..activeMaterialYouColorInt = fields[4] as int
      ..sufficientFrom = fields[5] as double
      ..activeProfileId = fields[6] as int?
      ..usedLocaleCode = fields[7] as String?
      ..noAds = fields[8] as bool
      ..activeBadges = fields[9] == null
          ? [GradeListBadges.weight]
          : (fields[9] as List).cast<GradeListBadges>()
      ..autoScrollCarousel = fields[10] == null ? true : fields[10] as bool
      ..swipeNavigation = fields[11] == null ? true : fields[11] as bool;
  }

  @override
  void write(BinaryWriter writer, Config obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.enableNotifications)
      ..writeByte(1)
      ..write(obj.darkMode)
      ..writeByte(2)
      ..write(obj.autoDarkMode)
      ..writeByte(3)
      ..write(obj.useMaterialYou)
      ..writeByte(4)
      ..write(obj.activeMaterialYouColorInt)
      ..writeByte(5)
      ..write(obj.sufficientFrom)
      ..writeByte(6)
      ..write(obj.activeProfileId)
      ..writeByte(7)
      ..write(obj.usedLocaleCode)
      ..writeByte(8)
      ..write(obj.noAds)
      ..writeByte(9)
      ..write(obj.activeBadges)
      ..writeByte(10)
      ..write(obj.autoScrollCarousel)
      ..writeByte(11)
      ..write(obj.swipeNavigation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccountTypesAdapter extends TypeAdapter<AccountTypes> {
  @override
  final int typeId = 2;

  @override
  AccountTypes read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountTypes.student;
      case 1:
        return AccountTypes.parent;
      case 2:
        return AccountTypes.other;
      default:
        return AccountTypes.student;
    }
  }

  @override
  void write(BinaryWriter writer, AccountTypes obj) {
    switch (obj) {
      case AccountTypes.student:
        writer.writeByte(0);
        break;
      case AccountTypes.parent:
        writer.writeByte(1);
        break;
      case AccountTypes.other:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTypesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccountAPITypesAdapter extends TypeAdapter<AccountAPITypes> {
  @override
  final int typeId = 3;

  @override
  AccountAPITypes read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountAPITypes.localFile;
      case 1:
        return AccountAPITypes.magister;
      case 2:
        return AccountAPITypes.somToDay;
      case 3:
        return AccountAPITypes.random;
      default:
        return AccountAPITypes.localFile;
    }
  }

  @override
  void write(BinaryWriter writer, AccountAPITypes obj) {
    switch (obj) {
      case AccountAPITypes.localFile:
        writer.writeByte(0);
        break;
      case AccountAPITypes.magister:
        writer.writeByte(1);
        break;
      case AccountAPITypes.somToDay:
        writer.writeByte(2);
        break;
      case AccountAPITypes.random:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountAPITypesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GradeTypeAdapter extends TypeAdapter<GradeType> {
  @override
  final int typeId = 8;

  @override
  GradeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GradeType.grade;
      case 1:
        return GradeType.average;
      case 2:
        return GradeType.other;
      default:
        return GradeType.grade;
    }
  }

  @override
  void write(BinaryWriter writer, GradeType obj) {
    switch (obj) {
      case GradeType.grade:
        writer.writeByte(0);
        break;
      case GradeType.average:
        writer.writeByte(1);
        break;
      case GradeType.other:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalendarEventTypesAdapter extends TypeAdapter<CalendarEventTypes> {
  @override
  final int typeId = 13;

  @override
  CalendarEventTypes read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CalendarEventTypes.homework;
      case 1:
        return CalendarEventTypes.test;
      case 2:
        return CalendarEventTypes.exam;
      case 3:
        return CalendarEventTypes.writtenExam;
      case 4:
        return CalendarEventTypes.oralExam;
      case 5:
        return CalendarEventTypes.assignment;
      case 6:
        return CalendarEventTypes.other;
      default:
        return CalendarEventTypes.homework;
    }
  }

  @override
  void write(BinaryWriter writer, CalendarEventTypes obj) {
    switch (obj) {
      case CalendarEventTypes.homework:
        writer.writeByte(0);
        break;
      case CalendarEventTypes.test:
        writer.writeByte(1);
        break;
      case CalendarEventTypes.exam:
        writer.writeByte(2);
        break;
      case CalendarEventTypes.writtenExam:
        writer.writeByte(3);
        break;
      case CalendarEventTypes.oralExam:
        writer.writeByte(4);
        break;
      case CalendarEventTypes.assignment:
        writer.writeByte(5);
        break;
      case CalendarEventTypes.other:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventTypesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GradeListBadgesAdapter extends TypeAdapter<GradeListBadges> {
  @override
  final int typeId = 15;

  @override
  GradeListBadges read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GradeListBadges.pta;
      case 1:
        return GradeListBadges.date;
      case 2:
        return GradeListBadges.weight;
      case 3:
        return GradeListBadges.changeInAverage;
      case 4:
        return GradeListBadges.changeInAverageSubject;
      default:
        return GradeListBadges.pta;
    }
  }

  @override
  void write(BinaryWriter writer, GradeListBadges obj) {
    switch (obj) {
      case GradeListBadges.pta:
        writer.writeByte(0);
        break;
      case GradeListBadges.date:
        writer.writeByte(1);
        break;
      case GradeListBadges.weight:
        writer.writeByte(2);
        break;
      case GradeListBadges.changeInAverage:
        writer.writeByte(3);
        break;
      case GradeListBadges.changeInAverageSubject:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeListBadgesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

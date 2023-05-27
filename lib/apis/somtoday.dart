import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';
import 'package:silvio/widgets/card.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'abstact_api.dart';
import 'package:pointycastle/export.dart' as castle;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'package:silvio/apis/somtoday/api.dart';
part 'package:silvio/apis/somtoday/screens/config.dart';
part 'package:silvio/apis/somtoday/screens/login.dart';
part 'package:silvio/apis/somtoday/screens/school_picker.dart';
part 'package:silvio/apis/somtoday/screens/terms.dart';
part 'package:silvio/apis/somtoday/translate.dart';

class SomToDay implements Api {
  @override
  Account account;
  SomToDay(this.account);

  late SomToDayApi api = SomToDayApi(account);

  @override
  late bool isOnline = true;

  @override
  Widget? buildConfig(BuildContext context, {required Person person}) {
    return null;
  }

  @override
  Widget buildLogin(BuildContext context) {
    return Terms(account);
  }

  @override
  Future<void> refreshAll(Person person) async {}

  @override
  Future<void> refreshCalendarEvents(Person person) async {
    // TODO: implement refreshCalendarEvents
  }

  @override
  Future<void> refreshGrade(Person person, Grade grade) async {
    // TODO: implement refreshGrade
  }

  @override
  Future<void> refreshProfilePicture(Person person) async {
    var img = (await api.dio.get(
      "/rest/v1/leerlingen?additional=pasfoto",
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => [200, 404].contains(status),
      ),
    ));

    person.profilePicture = img.data["items"].where((item) =>
        item["links"]
            .where((link) => link["type"] == "leerling.RLeerling")["id"] ==
        person.id)["additionalObjects"]["pasfoto"]["datauri"];
    if (account.isInBox) account.save();
  }

  @override
  Future<void> refreshSchoolYear(Person person, SchoolYear schoolYear,
      void Function(int completed, int total) progress) async {
    // TODO: implement refreshSchoolYear
  }

  @override
  Future<void> logout() async {
    // TODO: implement logout
  }
}

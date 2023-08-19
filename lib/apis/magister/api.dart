part of 'package:silvio/apis/magister.dart';

class MagisterApi extends Magister {
  MagisterApi(super.account);

  late Dio dio = Dio(
    BaseOptions(
        baseUrl: account.apiStorage?.baseUrl ?? "",
        headers: {"authorization": "Bearer ${account.apiStorage?.accessToken}"},
        connectTimeout: const Duration(seconds: 15)),
  )..interceptors.addAll([
      InterceptorsWrapper(
        onError: (e, handler) async {
          if (e.response?.data != null && e.response?.statusCode == 429) {
            debugPrint(
                "Limit reached... Please wait ${e.response?.data["secondsLeft"]} seconds.");
            await Future.delayed(
                Duration(seconds: e.response?.data["secondsLeft"]));
            //redo request
            await dio.fetch(e.requestOptions).then(
              (r) => handler.resolve(r),
              onError: (e) {
                debugPrint("retry failed");
                handler.next(e);
              },
            );
          } else {
            handler.next(e);
          }
        },
      ),
      InterceptorsWrapper(
        onError: (e, handler) async {
          if (e.response?.data != null &&
              e.response?.data["error"] == "invalid_grant") {
            rootScaffoldMessengerKey.currentState?.removeCurrentSnackBar();
            rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
              content: Text("No connection to Magister could be made"),
            ));

            rootScaffoldMessengerKey.currentState?.clearSnackBars();
            rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
              duration: const Duration(hours: 4),
              showCloseIcon: true,
              content: const Text("Connection failed, please login again"),
              action: SnackBarAction(
                  label: "Login",
                  onPressed: () => navigatorKey.currentState?.push(
                      MaterialPageRoute(
                          builder: (context) =>
                              SignIn(alreadyExistingAccount: account)))),
            ));

            return handler.reject(DioException(
              requestOptions: e.requestOptions,
              error:
                  "Dit account is uitgelogd, verwijder je account en log opnieuw in. (Spijt me zeer hier is nog geen automatische support voor)",
              response: e.response,
            ));
            // MagisterLogin().launch(main.appState.context, (tokenSet, _) {
            //   account.saveTokens(tokenSet);
            //   if (account.isInBox) account.save();
            // }, title: "Account is uitgelogd");
            // return dio.request(e.requestOptions.path, options: e.requestOptions as Options);
          }
          handler.next(e);
        },
      ),
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint("request: ${options.uri.pathSegments.last}");
          if (account.apiStorage!.accessToken == null ||
              DateTime.now().millisecondsSinceEpoch >
                  account.apiStorage!.expiry!) {
            debugPrint("Accestoken expired");
            await refreshToken().onError((e, stack) {
              handler.reject(e as DioException);
              return;
            });
          }

          options.baseUrl = account.apiStorage!.baseUrl;

          options.headers["Authorization"] =
              "Bearer ${account.apiStorage!.accessToken}";

          return handler.next(options);
        },
        onError: (e, handler) async {
          var options = e.requestOptions;

          Future<void> retry() => dio.fetch(options).then(
                (r) => handler.resolve(r),
                onError: (e) => handler.reject(e),
              );

          if (e.response?.data == "SecurityToken Expired") {
            debugPrint("Request failed, token is invalid");

            if (options.headers["Authorization"] !=
                "Bearer ${account.apiStorage!.accessToken}") {
              options.headers["Authorization"] =
                  "Bearer ${account.apiStorage!.accessToken}";

              return await retry();
            }

            return await refreshToken().then((_) => retry()).onError(
                  (e, stack) => handler.reject(e as DioException),
                );
          }

          return handler.next(e);
        },
      ),
      QueuedInterceptorsWrapper(
        onError: (e, handler) async {
          int tries = 0;
          if (e.type == DioExceptionType.unknown ||
              e.type == DioExceptionType.connectionTimeout) {
            Future<void> retry() async {
              await dio.fetch(e.requestOptions).then(
                (r) => handler.resolve(r),
                onError: (e) async {
                  if (tries < 3) {
                    tries++;
                    await retry();
                  } else {
                    handler.reject(e);
                  }
                },
              );
            }

            await retry();
          } else {
            handler.next(e);
          }
        },
      ),
    ]);

  Future<void> refreshToken() async {
    await Dio(BaseOptions(
      contentType: Headers.formUrlEncodedContentType,
    ))
        .post<Map>(
      "https://accounts.magister.net/connect/token",
      data:
          "refresh_token=${account.apiStorage!.refreshToken}&client_id=M6LOAPP&grant_type=refresh_token",
    )
        .then((res) async {
      saveTokens(res.data!);
      if (account.isInBox) account.save();
    }).catchError((err) {
      throw err;
    });
  }

  void saveTokens(tokenSet) {
    account.apiStorage!.accessToken = tokenSet["access_token"];
    account.apiStorage!.refreshToken = tokenSet["refresh_token"];
    account.apiStorage!.idToken ??= tokenSet["id_token"];
    account.apiStorage!.expiry =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;
  }

  Future<void> setTenant() async {
    Map body = (await Dio().get(
            "https://magister.net/.well-known/host-meta.json?rel=magister-api",
            options: Options(headers: {
              "Authorization": "Bearer ${account.apiStorage!.accessToken}"
            })))
        .data;
    account.apiStorage!.baseUrl =
        "https://${Uri.parse(body["links"].first["href"]).host}/";
  }

  Future<void> setSchoolYears(Person person) async {
    List apiSchoolYears = (await dio
            .get("api/leerlingen/${person.id}/aanmeldingen?begin=1970-01-01"))
        .data["items"];

    //Remove already existing schoolyears
    List<SchoolYear> newFoundSchoolYears = apiSchoolYears
        .map((e) => magisterSchoolYear(e)!)
        .toList()
      ..removeWhere(
          (sY) => person.rawSchoolYears.map((e) => e.id).contains(sY.id));

    //Add the new found schoolyears
    person.rawSchoolYears = List.from(person.rawSchoolYears)
      ..addAll(newFoundSchoolYears);
    if (account.isInBox) account.save();
  }

  Future<void> setSchoolQuarters(Person person, SchoolYear schoolYear) async {
    List perioden =
        (await dio.get("/api/aanmeldingen/${schoolYear.id}/cijfers/perioden"))
            .data["items"];
    schoolYear.schoolQuarters = List.from(schoolYear.schoolQuarters)
      ..addAll(perioden.map((sQua) => magisterSchoolQuarter(sQua)!).toList()
        ..removeWhere((sQua) =>
            schoolYear.schoolQuarters.map((e) => e.id).contains(sQua.id)));
    schoolYear.schoolQuarters
        .sort((SchoolQuarter a, SchoolQuarter b) => a.id.compareTo(b.id));
    if (account.isInBox) account.save();
  }

  Future<void> setAccountDetails() async {
    Map res = (await dio.get("api/account")).data;
    account.accountType = res["Groep"].first["Naam"] == "Leerling"
        ? AccountTypes.student
        : res["Groep"].first["Naam"] == "Ouder"
            ? AccountTypes.parent
            : AccountTypes.other;
    account.id = res["Persoon"]["Id"];
    account.dateOfBirth = DateTime.parse(
        res["Persoon"]["Geboortedatum"] ?? DateTime.now().toIso8601String());

    Future<void> initPerson(Person person) async {
      await refreshProfilePicture(person);
      await refreshCalendarEvents(person);
      await setSchoolYears(person);

      person.config.activeSchoolYearId = person.schoolYears.first.id;
      account.profiles.add(person);
      config.save();
    }

    switch (account.accountType) {
      case AccountTypes.student:
        await initPerson(Person(
            id: res["Persoon"]["Id"],
            firstName:
                res["Persoon"]["Roepnaam"] ?? res["Persoon"]["Voorletters"],
            lastName: res["Persoon"]["Achternaam"]));
        break;
      case AccountTypes.parent:
        Map children = (await dio
                .get("api/personen/${account.id}/kinderen?openData=%27%27"))
            .data;
        for (var child in children["Items"]) {
          await initPerson(Person(
              id: child["Id"],
              firstName: child["Roepnaam"] ?? child["Voorletters"],
              lastName: child["Achternaam"]));
        }
        break;
      default:
    }

    if (account.isInBox) account.save();
  }
}

Map? preFill;
String codeVerifier = generateRandomString();

String generateRandomString() {
  var r = Random.secure();
  var chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  return Iterable.generate(50, (_) => chars[r.nextInt(chars.length)]).join();
}

String generateLoginURL() {
  String generateRandomBase64(length) {
    var r = Random.secure();
    var chars = 'abcdef0123456789';
    return Iterable.generate(length, (_) => chars[r.nextInt(chars.length)])
        .join();
  }

  String nonce = generateRandomBase64(32);
  String state = generateRandomString();
  String codeChallenge = base64Url
      .encode(castle.SHA256Digest()
          .process(Uint8List.fromList(codeVerifier.codeUnits)))
      .replaceAll('=', '');
  String str =
      "https://accounts.magister.net/connect/authorize?client_id=M6LOAPP&redirect_uri=m6loapp%3A%2F%2Foauth2redirect%2F&scope=openid%20profile%20offline_access%20magister.mobile%20magister.ecs&response_type=code%20id_token&state=$state&nonce=$nonce&code_challenge=$codeChallenge&code_challenge_method=S256";
  if (preFill != null) {
    str +=
        "&acr_values=tenant:${preFill?["tenant"]}&prompt=select_account&login_hint=${preFill?['username']}";
  }
  return str;
}

Future<Map?> getTokenSet(String url) async {
  if (url.startsWith("refreshtoken")) {
    Account tempAccount = Account();

    tempAccount.apiStorage!.refreshToken =
        url.replaceFirst("refreshtoken=", "");
    await Magister(tempAccount).api.refreshToken();

    return {
      "access_token": tempAccount.apiStorage!.accessToken,
      "refresh_token": tempAccount.apiStorage!.refreshToken,
    };
  } else {
    String? code =
        Uri.parse(url.replaceFirst("#", "?")).queryParameters["code"];

    Response<Map> res = await Dio().post(
      "https://accounts.magister.net/connect/token",
      options: Options(
        contentType: "application/x-www-form-urlencoded",
      ),
      data:
          "code=$code&redirect_uri=m6loapp://oauth2redirect/&client_id=M6LOAPP&grant_type=authorization_code&code_verifier=$codeVerifier",
    );
    return res.data;
  }
}

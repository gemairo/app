part of 'package:silvio/apis/somtoday.dart';

class SomToDayApi extends SomToDay {
  SomToDayApi(super.account);

  late Dio dio = Dio(
    BaseOptions(
        baseUrl: account.apiStorage?.baseUrl ?? "",
        headers: {"authorization": "Bearer ${account.apiStorage?.accessToken}"},
        connectTimeout: const Duration(seconds: 15)),
  )..interceptors.addAll([
      InterceptorsWrapper(
        onError: (e, handler) async {
          if (e.response?.data != null &&
              e.response?.data["error"] == "invalid_grant") {
            return handler.reject(DioError(
              requestOptions: e.requestOptions,
              error:
                  "Dit account is uitgelogd, verwijder je account en log opnieuw in. (Spijt me zeer hier is nog geen automatische support voor)",
              response: e.response,
            ));
          }
          handler.next(e);
        },
      ),
      QueuedInterceptorsWrapper(onRequest: (options, handler) async {
        if (account.apiStorage!.accessToken == null ||
            DateTime.now().millisecondsSinceEpoch >
                account.apiStorage!.expiry!) {
          debugPrint("Accestoken expired");
          await refreshToken().onError((e, stack) {
            handler.reject(e as DioError);
            return;
          });
        }

        options.baseUrl = account.apiStorage!.baseUrl;

        options.headers["Authorization"] =
            "Bearer ${account.apiStorage!.accessToken}";

        return handler.next(options);
      }, onError: (e, handler) async {
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
                (e, stack) => handler.reject(e as DioError),
              );
        }
      })
    ]);

  Future<void> setAccountDetails() async {
    Map res = (await dio.get("/rest/v1/account/")).data;
    account.accountType = AccountTypes.student;
    account.id = res["items"]["persoon"]["links"].first["id"];

    Future<void> initPerson(Person person) async {
      await Future.wait([
        refreshProfilePicture(person),
        refreshCalendarEvents(person),
        setSchoolYears(person)
      ]);

      person.config.activeSchoolYearId = person.schoolYears.first.id;
      account.profiles.add(person);
      config.save();
    }

    for (var item in res["items"]) {
      await initPerson(Person(
          id: item["persoon"]["links"].first["id"],
          firstName: item["persoon"]["roepnaam"] ?? "",
          lastName: item["persoon"]["achternaam"] ?? ""));
    }

    if (account.isInBox) account.save();
  }

  Future<void> refreshToken() async {
    await Dio(BaseOptions(
      contentType: Headers.formUrlEncodedContentType,
    ))
        .post<Map>(
      "https://somtoday.nl/oauth2/token",
      data:
          "refresh_token=${account.apiStorage!.refreshToken}&client_id=D50E0C06-32D1-4B41-A137-A9A850C892C2&grant_type=refresh_token",
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
    account.apiStorage!.expiry =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;
    account.apiStorage!.baseUrl = tokenSet["somtoday_api_url"];
  }

  Future<void> setSchoolYears(Person person) async {
    if (account.isInBox) account.save();
  }
}

Future<Map?> getTokenSet(String url) async {
  if (url.startsWith("refreshtoken")) {
    Account tempAccount = Account();

    tempAccount.apiStorage!.refreshToken =
        url.replaceFirst("refreshtoken=", "");
    await SomToDay(tempAccount).api.refreshToken();

    return {
      "access_token": tempAccount.apiStorage!.accessToken,
      "refresh_token": tempAccount.apiStorage!.refreshToken,
    };
  } else {
    String? code = Uri.parse(url).queryParameters["code"];

    Response<Map> res = await Dio().post(
      "https://somtoday.nl/oauth2/token",
      options: Options(
        contentType: "application/x-www-form-urlencoded",
      ),
      data:
          "code=$code&redirect_uri=somtodayleerling://oauth/callback&client_id=D50E0C06-32D1-4B41-A137-A9A850C892C2&grant_type=authorization_code&code_verifier=$codeVerifier",
    );
    return res.data;
  }
}

String _generateRandomString() {
  var r = Random.secure();
  var chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  return Iterable.generate(32, (_) => chars[r.nextInt(chars.length)]).join();
}

String codeVerifier = _generateRandomString();

String createURL(String uuid) {
  String codeChallenge = base64Url
      .encode(castle.SHA256Digest()
          .process(Uint8List.fromList(codeVerifier.codeUnits)))
      .replaceAll('=', '');
  return "https://somtoday.nl/oauth2/authorize?redirect_uri=somtodayleerling://oauth/callback&client_id=D50E0C06-32D1-4B41-A137-A9A850C892C2&response_type=code&prompt=login&scope=openid&code_challenge=$codeChallenge&code_challenge_method=S256&tenant_uuid=$uuid";
}

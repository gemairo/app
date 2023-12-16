part of 'package:gemairo/apis/magister.dart';

enum _LoginOptions {
  refresh,
  browser,
  token,
}

class SignIn extends StatelessWidget {
  const SignIn({super.key, this.alreadyExistingAccount});

  final Account? alreadyExistingAccount;

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<String> redirectUrl = ValueNotifier("");
    WebViewController webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains("#code")) {
              redirectUrl.value = request.url;
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.loginWith("Magister")),
          actions: [
            ValueListenableBuilder(
              valueListenable: redirectUrl,
              builder: (context, _, __) {
                if (redirectUrl.value != "") {
                  return Container();
                }

                return PopupMenuButton<_LoginOptions>(
                  onSelected: (value) async {
                    switch (value) {
                      case _LoginOptions.refresh:
                        webViewController.loadRequest(Uri.parse(
                            generateLoginURL(
                                tenant: alreadyExistingAccount
                                    ?.apiStorage?.baseUrl)));

                        break;
                      case _LoginOptions.browser:
                        await launchUrl(
                            Uri.parse(generateLoginURL(
                                tenant: alreadyExistingAccount
                                    ?.apiStorage?.baseUrl)),
                            mode: LaunchMode.externalNonBrowserApplication,
                            webViewConfiguration: const WebViewConfiguration(
                                enableDomStorage: false));
                        redirectUrl.value = (await linkStream.first)!;
                        break;
                      case _LoginOptions.token:
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      height: 50,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: IconButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            icon: const Icon(Icons.close)),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(16)),
                                          child: MobileScanner(
                                            controller: MobileScannerController(
                                                detectionSpeed: DetectionSpeed
                                                    .noDuplicates),
                                            onDetect: (capture) {
                                              final List<Barcode> barcodes =
                                                  capture.barcodes;
                                              for (final barcode in barcodes) {
                                                String stringjson = jsonDecode(
                                                    utf8.decode(base64.decode(
                                                        barcode.rawValue!)));
                                                Map<String, dynamic>
                                                    decodedjson =
                                                    jsonDecode(stringjson);
                                                if (decodedjson.containsValue(
                                                        "Magister") &&
                                                    decodedjson.containsKey(
                                                        "refresh_token")) {
                                                  Navigator.of(context).pop();
                                                  redirectUrl.value =
                                                      "refreshtoken=${decodedjson["refresh_token"]}";
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            });
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _LoginOptions.refresh,
                      child: Text(AppLocalizations.of(context)!.reload),
                    ),
                    if (!Platform.isIOS)
                      PopupMenuItem(
                        value: _LoginOptions.browser,
                        child:
                            Text(AppLocalizations.of(context)!.openInBrowser),
                      ),
                    PopupMenuItem(
                      value: _LoginOptions.token,
                      child: Text(AppLocalizations.of(context)!.loginWithQR),
                    )
                  ],
                );
              },
            )
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: redirectUrl,
          builder: (context, _, __) {
            if (redirectUrl.value == "") {
              WebViewCookieManager().clearCookies();

              return WebViewWidget(
                  controller: webViewController
                    ..loadRequest(Uri.parse(generateLoginURL(
                        tenant: alreadyExistingAccount?.apiStorage?.baseUrl))));
            }
            return alreadyExistingAccount != null
                ? ReloadAccount(
                    account: alreadyExistingAccount!, redirectUrl: redirectUrl)
                : FetchAccountInformation(redirectUrl: redirectUrl);
          },
        ));
  }
}

class ReloadAccount extends StatelessWidget {
  const ReloadAccount(
      {super.key, required this.account, required this.redirectUrl});

  final Account account;
  final ValueNotifier<String> redirectUrl;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future(() async {
        Account toBeFilledAccount = Account();
        Magister magister = Magister(toBeFilledAccount);
        toBeFilledAccount.apiType = AccountAPITypes.magister;
        magister.api.saveTokens(await getTokenSet(redirectUrl.value));
        await magister.api.setTenant();
        await magister.api.setAccountDetails();
        if (AccountManager()
            .accountsList
            .map((e) => e.uuid)
            .contains(toBeFilledAccount.uuid)) {
          //The account exists
          account.apiStorage = toBeFilledAccount.apiStorage;
          await account.save();
          return Future.value(true);
        } else {
          throw "Account not found, please try again with the correct account.";
        }
      }),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.popUntil(context, (r) => r.isFirst);
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Start(),
                ));
          });
        }
        if (snapshot.hasError) {
          return Center(
            child: ListTile(
              title: Text("${snapshot.error}"),
              subtitle: Text("${snapshot.stackTrace}"),
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(AppLocalizations.of(context)!
                    .whileAccountInformationFetched),
              )
            ],
          ),
        );
      },
    );
  }
}

class FetchAccountInformation extends StatelessWidget {
  const FetchAccountInformation({super.key, required this.redirectUrl});

  final ValueNotifier<String> redirectUrl;

  @override
  Widget build(BuildContext context) {
    Future<Account> account = Future(() async {
      Account toBeFilledAccount = Account();

      Magister magister = Magister(toBeFilledAccount);
      toBeFilledAccount.apiType = AccountAPITypes.magister;
      magister.api.saveTokens(await getTokenSet(redirectUrl.value));
      await magister.api.setTenant();
      await magister.api.setAccountDetails();

      if (AccountManager().alreadyExists(toBeFilledAccount, unsaved: true)) {
        //Account already exists
        throw toBeFilledAccount;
      } else {
        return Future.value(toBeFilledAccount);
      }
    });

    return FutureBuilder(
      future: account,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.popUntil(context, (r) => r.isFirst);
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GetGrades(account: snapshot.data!),
                ));
          });
        } else if (snapshot.hasError) {
          if (snapshot.error is Account) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GemairoCard(
                    title:
                        Text(AppLocalizations.of(context)!.accountExistWarning),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ((snapshot.error as Account)
                                  .apiStorage
                                  ?.refreshToken !=
                              null)
                          ? [
                              Text(AppLocalizations.of(context)!
                                  .accountExistExpl),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: QrImageView(
                                    dataModuleStyle: QrDataModuleStyle(
                                        dataModuleShape:
                                            QrDataModuleShape.square,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground),
                                    eyeStyle: QrEyeStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground),
                                    data: base64Encode(utf8.encode(jsonEncode(
                                        '{"refresh_token":"${(snapshot.error as Account).apiStorage!.refreshToken}","type":"Magister"}')))
                                    // "Dit is een Magister refreshtoken\n${n}",
                                    ),
                              ),
                            ]
                          : [],
                    )),
              ),
            );
          }
          return Center(
            child: ListTile(
              title: Text("${snapshot.error}"),
              subtitle: Text("${snapshot.stackTrace}"),
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(AppLocalizations.of(context)!
                    .whileAccountInformationFetched),
              )
            ],
          ),
        );
      },
    );
  }
}

class GetGrades extends StatelessWidget {
  const GetGrades({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    ValueNotifier<int> futures = ValueNotifier(0);
    ValueNotifier<Map<String, List<int>>> precentDone = ValueNotifier({});
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.loginWith("Magister")),
        bottom: const PreferredSize(
            preferredSize: Size(1, 2), child: LinearProgressIndicator()),
      ),
      body: FutureBuilder(
        future: Future(() async {
          await Future.doWhile(() async {
            await Future.delayed(const Duration(seconds: 1));
            if (futures.value ==
                account.profiles
                    .expand((profile) => profile.schoolYears)
                    .length) {
              return false;
            }
            return true;
          });
          return futures.value;
        }),
        builder: (context, waitForFutures) {
          //Success
          if (waitForFutures.hasData) {
            AccountManager().addAccount(account);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).popUntil((r) => r.isFirst);
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => SettingsReminder(account: account),
              ));
            });
            return const Center(child: CircularProgressIndicator());
          }

          //Getting all grades from Magister
          Magister magister = Magister(account);
          return Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    ValueListenableBuilder<Map<String, List<int>>>(
                      valueListenable: precentDone,
                      builder: (context, _, __) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                            height: 100,
                            child: FactCard(
                              value:
                                  "${precentDone.value.values.map((e) => e.first).sum.toInt()}/${precentDone.value.values.map((e) => e.last).sum.toInt()}",
                              extra: FactCardProgress(
                                  value: precentDone.value.values
                                          .map((e) => e.first)
                                          .sum /
                                      precentDone.value.values
                                          .map((e) => e.last)
                                          .sum),
                              title:
                                  AppLocalizations.of(context)!.fetchedGrades,
                            )),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              ...account.profiles
                                  .expand((profile) => profile.schoolYears)
                                  .map((SchoolYear sY) => ListTile(
                                        title: Text(
                                            "${sY.groupName} (${sY.groupCode})"),
                                        trailing: FutureBuilder(
                                            key: ValueKey(sY.id.toString()),
                                            future: Future.wait([
                                              magister.refreshSchoolYear(
                                                  account.profiles.firstWhere(
                                                      (profile) => profile
                                                          .schoolYears
                                                          .map((e) => e.id)
                                                          .contains(sY.id)),
                                                  sY, (completed, total) {
                                                precentDone
                                                    .value[sY.id.toString()] = [
                                                  completed,
                                                  total
                                                ];
                                                // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                                                precentDone.notifyListeners();
                                              })
                                            ]),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  futures.value++;
                                                });
                                                return const Icon(Icons.done);
                                              }
                                              if (snapshot.hasError) {
                                                return const Icon(
                                                    Icons.warning);
                                              } else {
                                                return ValueListenableBuilder<
                                                        Map<String, List<int>>>(
                                                    valueListenable:
                                                        precentDone,
                                                    builder: (context, _, __) =>
                                                        CircularProgressIndicator(
                                                          value: precentDone.value[sY
                                                                      .id
                                                                      .toString()] ==
                                                                  null
                                                              ? null
                                                              : precentDone
                                                                      .value[sY
                                                                          .id
                                                                          .toString()]!
                                                                      .first /
                                                                  precentDone
                                                                      .value[sY
                                                                          .id
                                                                          .toString()]!
                                                                      .last,
                                                        ));
                                              }
                                            }),
                                      ))
                            ])),
                      ),
                    ),
                  ],
                )),
          );
        },
      ),
    );
  }
}

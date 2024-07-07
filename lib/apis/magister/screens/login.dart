part of 'package:gemairo/apis/magister.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key, this.alreadyExistingAccount});

  final Account? alreadyExistingAccount;

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  ValueNotifier<Map<dynamic, dynamic>?> tokenSet = ValueNotifier(null);
  late Magister magister;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => setTokenSet());
  }

  Future<void> setTokenSet() async {
    tokenSet.value = await showMagisterLoginDialog(context)
        .onError((error, stackTrace) => null);
    //If the dialog was dismissed and no token was retrieved, return to the previous page.
    if (tokenSet.value == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) async => Navigator.of(context).pop());
    }
  }

  Future<Account> getAccount() async {
    Magister magister = Magister(Account()..apiType = AccountAPITypes.magister);
    magister.api.saveTokens(tokenSet.value);
    await magister.api.setTenant();
    await magister.api.setAccountDetails();

    //Check if the account already exists in storage
    if (AccountManager()
        .accountsList
        .map((e) => e.uuid)
        .contains(magister.account.uuid)) {
      //Write new tokenSet to account.
      Account existingAccount = AccountManager()
          .accountsList
          .firstWhere((e) => e.uuid == magister.account.uuid);
      await (existingAccount..apiStorage = magister.account.apiStorage).save();
      return existingAccount;
    } else {
      return magister.account;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionSkeleton(
      icon: Icons.person_search_rounded,
      title: AppLocalizations.of(context)!.loginWith("Magister"),
      subTitle: AppLocalizations.of(context)!.whileAccountInformationFetched,
      content: ValueListenableBuilder(
          valueListenable: tokenSet,
          builder: (context, value, widget) {
            return value == null
                ? const Center(child: LinearProgressIndicator())
                : FutureBuilder(
                    future: getAccount(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (snapshot.hasData) {
                        WidgetsBinding.instance.addPostFrameCallback(
                            (_) async => Navigator.of(context)
                                    .pushReplacement(MaterialPageRoute(
                                  builder: (context) => FetchWeightsScreen(
                                    account: snapshot.data!,
                                  ),
                                )));
                      }
                      return const Center(child: LinearProgressIndicator());
                    },
                  );
          }),
    );
  }
}

class FetchWeightsScreen extends StatefulWidget {
  const FetchWeightsScreen(
      {super.key,
      required this.account,
      this.forcedEnabledId,
      this.customContinue});

  final Account account;
  final int? forcedEnabledId;
  final void Function()? customContinue;

  @override
  State<FetchWeightsScreen> createState() => _FetchWeightsScreenState();
}

class _FetchWeightsScreenState extends State<FetchWeightsScreen> {
  Map<SchoolYear, ValueNotifier<Map<int, int>>> schoolyearsMap = {};
  Map<SchoolYear, ValueNotifier<Map<int, int>>> selected = {};
  bool isLoading = false;

  @override
  void initState() {
    schoolyearsMap = {
      for (var s
          in widget.account.profiles.expand<SchoolYear>((e) => e.schoolYears))
        s: ValueNotifier({0: 0})
    };
    if (widget.forcedEnabledId == null) {
      selected.addAll({schoolyearsMap.keys.first: schoolyearsMap.values.first});
    } else {
      selected.addAll(schoolyearsMap.entries
          .where((e) => e.key.id == widget.forcedEnabledId)
          .map<Map<SchoolYear, ValueNotifier<Map<int, int>>>>(
              (e) => {e.key: e.value})
          .first);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionSkeleton(
      title: AppLocalizations.of(context)!.unknownWeights,
      subTitle: AppLocalizations.of(context)!.unknownWeightsDesc,
      icon: Icons.balance_rounded,
      actions: [
        FilledButton.icon(
            onPressed: selected.isEmpty || isLoading
                ? null
                : () async {
                    setState(() {
                      isLoading = true;
                    });

                    // run one by one for smoother rate limiting
                    for (var entry in selected.entries) {
                      await widget.account.api.refreshSchoolYear(
                        widget.account.profiles.firstWhere(
                          (p) => p.schoolYears
                              .map((e) => e.id)
                              .contains(entry.key.id),
                        ),
                        entry.key,
                        (completed, total) {
                          entry.value.value = {completed: total};
                        },
                      );
                    }

                    setState(() {
                      isLoading = false;
                      selected.removeWhere((key, value) =>
                          value.value.keys.first ==
                          value.value.values.toList().first);
                    });
                  },
            icon: const Icon(Icons.sync),
            label: Text(AppLocalizations.of(context)!.getGrades)),
        FilledButton.icon(
          label: Text(AppLocalizations.of(context)!.gContinue),
          onPressed: (widget.account.profiles
                          .expand((e) => e.schoolYears)
                          .any((e) => e.grades.isNotEmpty) &&
                      widget.forcedEnabledId == null ||
                  widget.forcedEnabledId != null &&
                      widget.account.profiles
                          .expand((e) => e.schoolYears)
                          .firstWhere((e) => e.id == widget.forcedEnabledId)
                          .grades
                          .isNotEmpty)
              ? widget.customContinue ??
                  () {
                    AccountManager().addAccount(widget.account);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) =>
                            SettingsReminder(account: widget.account),
                      ));
                    });
                  }
              : null,
          icon: const Icon(Icons.navigate_next),
        ),
      ],
      content: Column(
          children: schoolyearsMap.entries
              .map((e) => Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: ValueListenableBuilder(
                      valueListenable: e.value,
                      builder: (context, value, widget) {
                        return SwitchListTile(
                            value: e.key.grades.isNotEmpty
                                ? true
                                : (value.keys.first / value.values.first == 1
                                    ? false
                                    : selected.keys.contains(e.key)),
                            title: Text(e.key.groupName),
                            subtitle: value.keys.first != 0
                                ? Text(
                                    "${value.keys.first}/${value.values.first}")
                                : null,
                            secondary: value.keys.first / value.values.first >
                                        0 &&
                                    value.keys.first / value.values.first < 1
                                ? CircularProgressIndicator(
                                    value:
                                        value.keys.first / value.values.first)
                                : const Icon(Icons.list),
                            onChanged: isLoading || e.key.grades.isNotEmpty
                                ? null
                                : (value) => setState(() {
                                      if (value) {
                                        selected.addAll({e.key: e.value});
                                      } else {
                                        selected.removeWhere(
                                          (key, value) => key.id == e.key.id,
                                        );
                                      }
                                    }));
                      })))
              .toList()),
    );
  }
}

///Returns a tokenset from Magister.
Future<Map<dynamic, dynamic>?> showMagisterLoginDialog(
    BuildContext context) async {
  ValueNotifier<Uri?> redirectUrl = ValueNotifier<Uri?>(null);

  //Settings for the webview (iOS & Android only)
  late WebViewController webViewController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.contains("#code")) {
            redirectUrl.value = Uri.parse(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );

  Future<void> loginWithBrowser({bool useWebview = true}) async {
    if (await WebviewWindow.isWebviewAvailable() &&
        useWebview &&
        !Platform.isIOS &&
        !Platform.isAndroid) {
      final webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
            windowWidth: 400,
            windowHeight: 640,
            title: 'Login met Magister',
            titleBarTopPadding: Platform.isMacOS ? 20 : 0,
            useWindowPositionAndSize: true),
      );
      webview
        ..launch(generateLoginURL())
        ..addOnUrlRequestCallback((requestUrl) {
          final uri = Uri.parse(requestUrl);
          if (uri.scheme == "m6loapp") {
            redirectUrl.value = uri;
            webview.close();
          }
        });
    } else {
      await launchUrl(Uri.parse(generateLoginURL()),
          mode: LaunchMode.externalNonBrowserApplication,
          webViewConfiguration:
              const WebViewConfiguration(enableDomStorage: false));
      AppLinks().allUriLinkStream.listen((uri) => redirectUrl.value = uri);
    }
  }

  if (!Platform.isAndroid && !Platform.isIOS) loginWithBrowser();

  Future<void> returnWithTokenSet(Uri redirectURL) async =>
      Navigator.of(context)
          .pop(await getTokenSet(redirectUrl.value.toString()));

  return await showDialog<Map<dynamic, dynamic>?>(
    context: context,
    useSafeArea: false,
    builder: (BuildContext context) {
      return Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Inloggen"),
              actions: (Platform.isAndroid ||
                      Platform
                          .isIOS) //Only iOS & Android are supported for logging in with a webview
                  ? [
                      IconButton(
                          onPressed: () => webViewController
                              .loadRequest(Uri.parse(generateLoginURL())),
                          icon: const Icon(Icons.refresh)),
                      IconButton(
                          onPressed: () => loginWithBrowser(),
                          icon: const Icon(Icons.open_in_browser))
                    ]
                  : [],
            ),
            body: SafeArea(
              child: ValueListenableBuilder(
                valueListenable: redirectUrl,
                builder: (context, value, child) {
                  if (value != null) {
                    //Redirect value has been set!
                    returnWithTokenSet(value);
                    return const Center(child: CircularProgressIndicator());
                  }
                  //Waiting for redirectUrl
                  if (Platform.isAndroid || Platform.isIOS) {
                    WebViewCookieManager().clearCookies();
                    return WebViewWidget(
                        controller: webViewController
                          ..loadRequest(Uri.parse(generateLoginURL())));
                  } else {
                    return AlertDialog(
                      title: const Text("Browser-login"),
                      content: const Text(
                          "Please login with the opened browser instance"),
                      actions: [
                        FilledButton.tonalIcon(
                            onPressed: () =>
                                loginWithBrowser(useWebview: false),
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text("Open in browser")),
                        FilledButton.icon(
                          onPressed: () => loginWithBrowser(),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text("Openen"),
                        )
                      ],
                    );
                  }
                },
              ),
            ),
          ));
    },
  );
}

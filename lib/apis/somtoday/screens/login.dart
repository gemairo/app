part of 'package:gemairo/apis/somtoday.dart';

enum _LoginOptions {
  refresh,
  browser,
  // token,
}

class _SignIn extends StatelessWidget {
  const _SignIn(this.account, this.schoolUUID);
  final Account account;
  final String schoolUUID;

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<String> redirectUrl = ValueNotifier("");
    WebViewController webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('?code')) {
              redirectUrl.value = request.url;
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.loginWith("SomToDay")),
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
                        webViewController
                            .loadRequest(Uri.parse(createURL(schoolUUID)));

                        break;
                      case _LoginOptions.browser:
                        await launchUrl(Uri.parse(createURL(schoolUUID)),
                            mode: LaunchMode.externalNonBrowserApplication,
                            webViewConfiguration: const WebViewConfiguration(
                                enableDomStorage: false));
                        // redirectUrl.value = (await linkStream.first)!;
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _LoginOptions.refresh,
                      child: Text(AppLocalizations.of(context)!.reload),
                    ),
                    PopupMenuItem(
                      value: _LoginOptions.browser,
                      child: Text(AppLocalizations.of(context)!.openInBrowser),
                    ),
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
                    ..loadRequest(Uri.parse(createURL(schoolUUID))));
            }
            return _FetchGrades(redirectUrl: redirectUrl, account: account);
          },
        ));
  }
}

class _FetchGrades extends StatefulWidget {
  const _FetchGrades({required this.redirectUrl, required this.account});

  final Account account;
  final ValueNotifier<String> redirectUrl;

  @override
  State<StatefulWidget> createState() => _FetchGradesState();
}

class _FetchGradesState extends State<_FetchGrades> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future(() async {
        SomToDay somtoday = SomToDay(widget.account);
        widget.account.apiType = AccountAPITypes.somToDay;
        somtoday.api.saveTokens(await getTokenSet(widget.redirectUrl.value));
        await somtoday.api.setAccountDetails();
        if (!AccountManager().alreadyExists(widget.account)) {
          return Future.value(widget.account);
        } else {
          throw "Account already exists";
        }
      }),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
        } else if (snapshot.hasError) {
          if (snapshot.error == "Account already exists") {
            //TODO: Share menu?
          }
          return Center(
            child: ListTile(
              title: Text("${snapshot.error}"),
              subtitle: Text("${snapshot.stackTrace}"),
            ),
          );
        }
        return Center(
          child: CircularProgressIndicator(
              semanticsLabel:
                  AppLocalizations.of(context)!.whileAccountInformationFetched),
        );
      },
    );
  }
}

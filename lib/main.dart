import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Person;
import 'package:gemairo/apis/abstact_api.dart';
import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/apis/saaf.dart';
import 'package:gemairo/firebase_options.dart';
import 'package:gemairo/hive/extentions.dart';
import 'package:gemairo/screens/login.dart';
import 'package:gemairo/widgets/ads.dart';
import 'package:gemairo/widgets/appbar.dart';
import 'package:gemairo/widgets/navigation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';

import 'hive/adapters.dart';

part 'background_tasks.dart';

Future<void> initHive() async {
  if (Platform.isLinux) {
    Hive.init("./tmp/");
  } else {
    await Hive.initFlutter();
  }

  if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ConfigAdapter());

  if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(SchoolYearAdapter());
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(SchoolQuarterAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(SubjectAdapter());
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(CalendarEventAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(GradeAdapter());

  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AccountAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(PersonAdapter());
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(PersonConfigAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ApiStorageAdapter());

  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountTypesAdapter());
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(AccountAPITypesAdapter());
  }
  if (!Hive.isAdapterRegistered(15)) {
    Hive.registerAdapter(GradeListBadgesAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(CalendarEventTypesAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(GradeTypeAdapter());
}

void main(args) async {
  //Desktop webview
  if (runWebViewTitleBarWidget(args)) {
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();

  await initHive();

  await Hive.openBox<Config>('config');
  await Hive.openBox<Account>('accountList');

  //Expand app behind navigation bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  if (Platform.isIOS || Platform.isAndroid) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseRemoteConfig.instance.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 5),
      minimumFetchInterval:
          kDebugMode ? Duration.zero : const Duration(hours: 1),
    ));
    await FirebaseRemoteConfig.instance.fetchAndActivate();
  }

  Box gemairoBox = await Hive.openBox('gemairo');
  int launches = gemairoBox.get('launches', defaultValue: 0);
  gemairoBox.put('launches', launches + 1);

  runApp(const Gemairo());

  //Backgound fetch is only supported on mobile platforms
  if (Platform.isIOS || Platform.isAndroid) {
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class Gemairo extends StatefulWidget {
  const Gemairo({Key? key}) : super(key: key);

  @override
  State<Gemairo> createState() => GemairoState();
  static GemairoState of(BuildContext context) =>
      context.findAncestorStateOfType<GemairoState>()!;
}

class GemairoState extends State<Gemairo> {
  @override
  void initState() {
    super.initState();
    if (Platform.isIOS || Platform.isAndroid) initPlatformState();
  }

  void update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      ColorScheme lightColorScheme;
      ColorScheme darkColorScheme;
      if (lightDynamic != null &&
          darkDynamic != null &&
          config.useMaterialYou) {
        //Using Material You colors set by Android S+ devices
        lightColorScheme = lightDynamic.harmonized();
        darkColorScheme = darkDynamic.harmonized();
      } else {
        //Not using Material You colors set by Android S+ devices
        lightColorScheme = ColorScheme.fromSeed(
          seedColor: Color(config.activeMaterialYouColorInt),
        ).harmonized();
        darkColorScheme = ColorScheme.fromSeed(
          seedColor: Color(config.activeMaterialYouColorInt),
          brightness: Brightness.dark,
        ).harmonized();
      }

      ThemeData theme({bool useDarkMode = false}) {
        ColorScheme colorScheme =
            useDarkMode ? darkColorScheme : lightColorScheme;
        return ThemeData(
            brightness: useDarkMode ? Brightness.dark : Brightness.light,
            colorScheme: colorScheme,
            platform: (Platform.isLinux || Platform.isMacOS)
                ? TargetPlatform.android
                : null,
            useMaterial3: true,
            tooltipTheme: TooltipThemeData(
              textStyle: TextStyle(color: colorScheme.onBackground),
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                    BorderSide(color: colorScheme.outline, width: 1)),
                color: colorScheme.background,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
            ),
            badgeTheme: BadgeThemeData(
                textColor: colorScheme.onPrimaryContainer,
                backgroundColor: colorScheme.primaryContainer),
            snackBarTheme: SnackBarThemeData(
                backgroundColor: colorScheme.surfaceVariant,
                closeIconColor: colorScheme.onSurfaceVariant,
                contentTextStyle:
                    TextStyle(color: colorScheme.onSurfaceVariant),
                actionBackgroundColor: colorScheme.primary));
      }

      return ChangeNotifierProvider(
          create: (context) => AccountProvider(),
          child: MaterialApp(
              navigatorKey: navigatorKey,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              title: 'Gemairo',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: config.usedLocaleCode != null
                  ? Locale(config.usedLocaleCode!)
                  : null,
              theme: theme(),
              darkTheme: theme(useDarkMode: true),
              themeMode: config.autoDarkMode
                  ? ThemeMode.system
                  : config.darkMode
                      ? ThemeMode.dark
                      : ThemeMode.light,
              home: const Start()));
    });
  }
}

class Start extends StatefulWidget {
  const Start({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _Start();
}

class _Start extends State<Start> {
  int screenIndex = 0;

  @override
  void initState() {
    super.initState();

    // AccountProvider acP = Provider.of<AccountProvider>(context, listen: false);
    // FirebaseAnalytics.instance.setUserProperty(
    //   name: 'api_provider',
    //   value: acP.account.apiType.toString(),
    // );

    if (AccountManager().personList.isNotEmpty &&
        AccountManager().getActive().profiles.isNotEmpty) {
      Saaf.instance
          ?.initialize()
          .then((_) => Saaf.instance?.handleTakeover(context));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      checkReview();
    });
  }

  checkReview() {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    Box gemairoBox = Hive.box('gemairo');
    int launches = gemairoBox.get('launches', defaultValue: 0);
    bool reviewed = gemairoBox.get('reviewed', defaultValue: false);
    if (launches > 0 &&
        (launches %
                FirebaseRemoteConfig.instance
                    .getInt('ask_review_every_x_launches') ==
            0) &&
        !reviewed) {
      final InAppReview inAppReview = InAppReview.instance;
      inAppReview.isAvailable().then(
        (bool available) async {
          if (available) {
            int i = 0;
            while (i < 5 && !mounted) {
              await Future.delayed(const Duration(seconds: 1));
              i++;
            }
            FirebaseAnalytics.instance.logEvent(
              name: 'REVIEW_popup_ask',
            );
            return showDialog<void>(
              context: navigatorKey.currentContext!,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  actionsAlignment: MainAxisAlignment.start,
                  title: Text(AppLocalizations.of(context)!.feedbackTitle),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        FirebaseAnalytics.instance.logEvent(
                          name: 'REVIEW_popup_dismiss',
                        );
                        gemairoBox.put("reviewed", true);
                      },
                      child: Text(AppLocalizations.of(context)!.feedbackNo),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        gemairoBox.put("reviewed", true);
                        FirebaseAnalytics.instance.logEvent(
                          name: 'REVIEW_popup_review',
                        );
                        inAppReview.requestReview();
                      },
                      child: Text(AppLocalizations.of(context)!.feedbackYes),
                    )
                  ],
                );
              },
            );
          } else {
            FirebaseAnalytics.instance.logEvent(
              name: 'REVIEW_popup_unavailable',
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (AccountManager().personList.isEmpty ||
          (AccountManager().personList.isNotEmpty &&
              AccountManager().getActive().profiles.isEmpty)) {
        return const LoginView();
      }

      String? getAppBarTitle(int screenIndex, BuildContext context) {
        switch (screenIndex) {
          case 0:
            return AppLocalizations.of(context)?.yearView;
          case 1:
            return AppLocalizations.of(context)?.subjectsView;
          case 2:
            return AppLocalizations.of(context)?.searchView;
          default:
            return null;
        }
      }

      if (constraints.maxWidth < 450) {
        final controller = PageController(
          initialPage: screenIndex,
        );

        controller.addListener(() {
          setState(() {
            screenIndex = controller.page?.round() ?? screenIndex;
          });
        });

        void handleScreenChanged(int selectedScreen) {
          controller.animateToPage(selectedScreen,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut);
        }

        return Scaffold(
          appBar: GemairoAppBar(title: getAppBarTitle(screenIndex, context)),
          body: BottomBanner(
              child: ScreensSwitch(
            index: screenIndex,
            swipeEnabled: true,
            controller: controller,
          )),
          bottomNavigationBar: GemairoNavigationBar(
            onSelectItem: handleScreenChanged,
            screenIndex: screenIndex,
          ),
        );
      } else {
        void handleScreenChanged(int selectedScreen) {
          setState(() {
            screenIndex = selectedScreen;
          });
        }

        return Scaffold(
          body: SafeArea(
            bottom: false,
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: constraints.maxWidth < 900
                        ? GemairoNavigationRail(
                            onSelectItem: handleScreenChanged,
                            selectedIndex: screenIndex,
                          )
                        : GemairoNavigationDrawer(
                            onSelectItem: handleScreenChanged,
                            selectedIndex: screenIndex,
                          )),
                if (constraints.maxWidth < 900)
                  const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                    child: Scaffold(
                        appBar: GemairoAppBar(
                            title: getAppBarTitle(screenIndex, context)),
                        body: BottomBanner(
                            child: ScreensSwitch(
                          index: screenIndex,
                          swipeEnabled: false,
                        )))),
              ],
            ),
          ),
        );
      }
    });
  }
}

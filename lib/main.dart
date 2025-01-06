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
        //
        // God knows why, but the dynamic_color package has gone haywire in
        // the latest version of flutter (3.22), so for now a workaround has to
        // be used to get the correct coloring. When this issue has been
        // resolved the following code can be removed
        //

        List<Color> extractAdditionalColours(ColorScheme scheme) => [
              scheme.surface,
              scheme.surfaceDim,
              scheme.surfaceBright,
              scheme.surfaceContainerLowest,
              scheme.surfaceContainerLow,
              scheme.surfaceContainer,
              scheme.surfaceContainerHigh,
              scheme.surfaceContainerHighest,
            ];

        ColorScheme insertAdditionalColours(
                ColorScheme scheme, List<Color> additionalColours) =>
            scheme.copyWith(
              surface: additionalColours[0],
              surfaceDim: additionalColours[1],
              surfaceBright: additionalColours[2],
              surfaceContainerLowest: additionalColours[3],
              surfaceContainerLow: additionalColours[4],
              surfaceContainer: additionalColours[5],
              surfaceContainerHigh: additionalColours[6],
              surfaceContainerHighest: additionalColours[7],
            );

        ColorScheme generateDynamicColourSchemes(ColorScheme scheme,
            [bool isDark = false]) {
          var base = ColorScheme.fromSeed(
              seedColor: scheme.primary,
              brightness: isDark ? Brightness.dark : Brightness.light);

          var additionalColours = extractAdditionalColours(base);

          return scheme =
              insertAdditionalColours(base, additionalColours).harmonized();
        }

        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;
        if (lightDynamic != null &&
            darkDynamic != null &&
            config.useMaterialYou) {
          //Using Material You colors set by Android S+ devices
          lightColorScheme = generateDynamicColourSchemes(lightDynamic);
          darkColorScheme = generateDynamicColourSchemes(darkDynamic, true);
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
                textStyle: TextStyle(color: colorScheme.onSurface),
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(
                      BorderSide(color: colorScheme.outline, width: 1)),
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              ),
              badgeTheme: BadgeThemeData(
                  textColor: colorScheme.onPrimaryContainer,
                  backgroundColor: colorScheme.primaryContainer),
              snackBarTheme: SnackBarThemeData(
                  backgroundColor: colorScheme.surfaceContainerHighest,
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
            home: Start(key: ValueKey(config.hashCode)),
          ),
        );
      },
    );
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
  late final ValueNotifier<int> screenIndex;
  late final PageController controller;

  @override
  void initState() {
    screenIndex = ValueNotifier(0);
    controller = PageController(
      initialPage: screenIndex.value,
    );

    super.initState();

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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void handleScreenChanged(int selectedScreen, {bool wasSwiped = false}) {
    if (selectedScreen != screenIndex.value) {
      screenIndex.value = selectedScreen;
      if (!wasSwiped) {
        controller.animateToPage(selectedScreen,
            duration: const Duration(milliseconds: 300),
            curve: Easing.standard);
      }
    }
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

      String? getAppBarTitle(BuildContext context, {required int index}) {
        switch (index) {
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

      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (constraints.maxWidth >= 600)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: ValueListenableBuilder(
                  valueListenable: screenIndex,
                  builder: (context, value, _) {
                    return constraints.maxWidth < 840
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: GemairoNavigationRail(
                              onSelectItem: handleScreenChanged,
                              selectedIndex: value,
                            ),
                          )
                        : GemairoNavigationDrawer(
                            onSelectItem: handleScreenChanged,
                            selectedIndex: value,
                          );
                  },
                ),
              ),
            Expanded(
              child: BottomBanner(
                placement: 'main',
                child: NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return <Widget>[
                      SliverOverlapAbsorber(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                            context),
                        sliver: GemairoAppBar(
                          forceElevated: innerBoxIsScrolled,
                          title: ValueListenableBuilder(
                            valueListenable: screenIndex,
                            builder: (context, value, _) {
                              return Text(getAppBarTitle(context,
                                  index: screenIndex.value)!);
                            },
                          ),
                        ),
                      ),
                    ];
                  },
                  body: Builder(
                    builder: (context) {
                      return ScreensSwitch(
                        key: ValueKey(config.swipeNavigation),
                        controller: controller,
                        index: screenIndex.value,
                        swipeEnabled: (constraints.maxWidth < 600),
                        direction: (constraints.maxWidth < 600)
                            ? Axis.horizontal
                            : Axis.vertical,
                        onChanged: (index) =>
                            handleScreenChanged(index, wasSwiped: true),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: constraints.maxWidth < 600
            ? ValueListenableBuilder(
                valueListenable: screenIndex,
                builder: (context, value, _) {
                  return GemairoNavigationBar(
                    onSelectItem: handleScreenChanged,
                    screenIndex: value,
                  ) as Widget;
                },
              )
            : null,
      );
    });
  }
}

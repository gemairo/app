import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:silvio/widgets/ads.dart';
import 'hive/adapters.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/apis/abstact_api.dart';
import 'package:silvio/hive/extentions.dart';

import 'package:silvio/screens/login.dart';
import 'package:silvio/widgets/appbar.dart';
import 'package:silvio/widgets/navigation.dart';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Person;

import 'package:background_fetch/background_fetch.dart';
part 'background_tasks.dart';

Future<void> initHive() async {
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ConfigAdapter());

  if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(SchoolYearAdapter());
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(SchoolQuarterAdapter());
  if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(SubjectAdapter());
  if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(CalendarEventAdapter());
  if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(GradeAdapter());

  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AccountAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(PersonAdapter());
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(PersonConfigAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ApiStorageAdapter());

  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountTypesAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AccountAPITypesAdapter());
  if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(GradeListBadgesAdapter());
  if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(CalendarEventTypesAdapter());
  if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(GradeTypeAdapter());
}

void main() async {
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

  WidgetsFlutterBinding.ensureInitialized();
  await AppTrackingTransparency.requestTrackingAuthorization();
  MobileAds.instance.initialize();
  final RequestConfiguration requestConfiguration = RequestConfiguration(
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes);
  MobileAds.instance.updateRequestConfiguration(requestConfiguration);

  runApp(const Silvio());
  if (!kIsWeb) {
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }
}

class Silvio extends StatefulWidget {
  const Silvio({Key? key}) : super(key: key);

  @override
  State<Silvio> createState() => SilvioState();
  static SilvioState of(BuildContext context) =>
      context.findAncestorStateOfType<SilvioState>()!;
}

class SilvioState extends State<Silvio> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) initPlatformState();
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
            useMaterial3: true,
            badgeTheme: BadgeThemeData(
                textColor: colorScheme.onPrimaryContainer,
                backgroundColor: colorScheme.primaryContainer));
      }

      return ChangeNotifierProvider(
          create: (context) => AccountProvider(),
          child: MaterialApp(
              title: 'Silvio',
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

  void handleScreenChanged(int selectedScreen) {
    setState(() {
      screenIndex = selectedScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (AccountManager().personList.isEmpty ||
          (AccountManager().personList.isNotEmpty &&
              AccountManager().getActive().profiles.isEmpty)) {
        return const LoginView();
      }

      if (constraints.maxWidth < 450) {
        return Scaffold(
          appBar: const SilvioAppBar(),
          body: BottomBanner(
              child: RefreshIndicator(
                  onRefresh: () async {
                    AccountProvider acP =
                        Provider.of<AccountProvider>(context, listen: false);
                    Api api = acP.account.api;
                    await Future.wait([
                      Future.wait(acP.person.schoolYears.map((SchoolYear sY) =>
                          api.refreshSchoolYear(acP.person, sY, (i, t) {}))),
                      api.refreshCalendarEvents(acP.person)
                    ]);
                    acP.changeAccount(null);
                  },
                  child: ScreensSwitch(index: screenIndex))),
          bottomNavigationBar: SilvioNavigationBar(
            onSelectItem: handleScreenChanged,
            screenIndex: screenIndex,
          ),
        );
      } else {
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
                        ? SilvioNavigationRail(
                            onSelectItem: handleScreenChanged,
                            selectedIndex: screenIndex,
                          )
                        : SilvioNavigationDrawer(
                            onSelectItem: handleScreenChanged,
                            selectedIndex: screenIndex,
                          )),
                if (constraints.maxWidth < 900)
                  const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                    child: Scaffold(
                        appBar: const SilvioAppBar(),
                        body: BottomBanner(
                            child: RefreshIndicator(
                                onRefresh: () async {
                                  AccountProvider acP =
                                      Provider.of<AccountProvider>(context,
                                          listen: false);
                                  Api api = acP.account.api;
                                  await Future.wait([
                                    Future.wait(acP.person.schoolYears.map(
                                        (SchoolYear sY) =>
                                            api.refreshSchoolYear(
                                                acP.person, sY, (i, t) {}))),
                                    api.refreshCalendarEvents(acP.person)
                                  ]);
                                  acP.changeAccount(null);
                                },
                                child: ScreensSwitch(index: screenIndex))))),
              ],
            ),
          ),
        );
      }
    });
  }
}

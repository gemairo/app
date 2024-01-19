import 'dart:convert';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';
import 'package:gemairo/main.dart';
import 'package:gemairo/widgets/ads.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saaf/saaf.dart' as saaf;

class Saaf {
  String app;
  bool initialized = false;
  late Box box;
  final String baseUrl = 'https://saaf-api.gemairo.app';

  Saaf._({required this.app});

  static final Map<String, Saaf> _saafInstances = {};

  factory Saaf._instanceFor({required String app}) {
    return _saafInstances.putIfAbsent(app, () {
      return Saaf._(app: app);
    });
  }

  static Saaf get instance {
    String defaultAppInstance = 'gemairo';
    return Saaf._instanceFor(app: defaultAppInstance);
  }

  saaf.AdRequest _adRequest = saaf.AdRequest(
    failedClasses: [],
    passedClasses: [],
    exclude: [],
    platform: Platform.isIOS ? 'ios' : 'android',
    saafVersion: 4,
  );
  saaf.AdRequest get adRequest => _adRequest;

  Future<void> initialize() async {
    // try {
    if (initialized == true) {
      return;
    }

    box = await Hive.openBox('saaf');
    initialized = true;
    await setAdRequest();
    // } catch (e) {}
  }

  Future<void> handleNavigate(String screenName) async {
    String unifiedName = mapClass(screenName);

    await FirebaseAnalytics.instance.logScreenView(screenName: unifiedName);
  }

  Future<saaf.AdRequest> setAdRequest({bool force = false}) async {
    if (_adRequest.passedClasses.isNotEmpty && !force) {
      return _adRequest;
    }

    List<String> bannerExclude =
        List<String>.from(box.get("bannerAdExclude", defaultValue: []));
    List<String> takeoverExclude =
        List<String>.from(box.get("takeoverAdExclude", defaultValue: []));

    List<String> exclude = [...bannerExclude, ...takeoverExclude];

    Person? person = AccountManager().getActive().activeProfile;

    //If there is no user info
    if (person == null) {
      _adRequest = saaf.AdRequest(
        failedClasses: [],
        passedClasses: [],
        exclude: [],
        platform: Platform.isIOS ? 'ios' : 'android',
        saafVersion: 4,
      );

      return _adRequest;
    }

    List<Grade> grades = person.activeSchoolYear.grades.useable;
    List<String> failedClasses = [];
    List<String> passedClasses = [];

    Map<String, List<RegExp>> classMappings = getClassMappings();

    print(classMappings);

    for (Subject subject in grades.useable.subjects) {
      String unifiedName = mapClass(subject.name, classMappings: classMappings);

      if (subject.grades.average.isNaN) {
        failedClasses.add(unifiedName);
        passedClasses.add(unifiedName);
        continue;
      }

      if (subject.grades.average >= config.sufficientFrom) {
        passedClasses.add(unifiedName);
      } else {
        failedClasses.add(unifiedName);
      }
    }

    print(failedClasses);
    print(passedClasses);

    _adRequest = saaf.AdRequest(
      failedClasses: failedClasses,
      passedClasses: passedClasses,
      exclude: exclude,
      platform: Platform.isIOS ? 'ios' : 'android',
      saafVersion: 4,
    );

    return _adRequest;
  }

  void onBannerClick(
    saaf.BannerAdResponse bannerAdResponse,
  ) async {
    FirebaseAnalytics.instance.logEvent(
      name: 'ADS_saaf_click',
      parameters: {'format': 'banner', 'id': bannerAdResponse.banner.id},
    );

    List<String> exclude =
        List<String>.from(box.get("bannerAdExclude", defaultValue: []));
    exclude.add(bannerAdResponse.banner.id);

    box.put("bannerAdExclude", exclude);

    setAdRequest(force: true);
  }

  void onTakeoverClick(saaf.TakeoverAdResponse takeoverAdResponse) async {
    FirebaseAnalytics.instance.logEvent(name: 'ADS_saaf_click', parameters: {
      'format': 'takeover',
      'id': takeoverAdResponse.takeover.id,
    });

    if (takeoverAdResponse.takeover.inAppNavigate is String) {
      // final DynamicLinkService _dynamicLinkService =
      //     locator<DynamicLinkService>();
      // _dynamicLinkService.handleDeepLink(
      //     Uri.parse(takeoverAdResponse.takeover.inAppNavigate!));
    }

    List<String> exclude =
        List<String>.from(box.get("takeoverAdExclude", defaultValue: []));
    exclude.add(takeoverAdResponse.takeover.id);

    box.put("takeoverAdExclude", exclude);

    setAdRequest(force: true);
  }

  Widget bannerAd(context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70.0 + 7.0 + 7.0),
      width: double.infinity,
      child: saaf.BannerAd(
        request: adRequest,
        onClick: onBannerClick,
        onReport: (_) {},
        onImpression: (_) {
          FirebaseAnalytics.instance.logEvent(
            name: 'ADS_saaf_impression',
            parameters: {'format': 'banner'},
          );
        },
        errorWidget: Container(
          constraints: const BoxConstraints(
            minHeight: 70.0 + 7.0 + 7.0,
          ),
          // height: 100,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Advertisement(
            size: AdSize.largeBanner,
          ),
        ),
        baseUrl: baseUrl,
        style: saaf.BannerAdStyle(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          titleColor: Theme.of(context).textTheme.titleLarge!.color!,
          textColor: Theme.of(context).textTheme.bodyMedium!.color!,
          primaryColor: Theme.of(context).colorScheme.primary,
          titleMaxLines: 2,
          subtitleMaxLines: 2,
        ),
      ),
    );
  }

  Future<void> handleTakeover(context) async {
    final takeoverAd = saaf.TakeoverAd(
      request: adRequest,
      onClick: onTakeoverClick,
      onReport: (_) {},
      onImpression: (saaf.TakeoverAdResponse adResponse) {
        FirebaseAnalytics.instance.logEvent(
          name: 'ADS_saaf_impression',
          parameters: {'format': 'takeover'},
        );

        List<String> exclude =
            List<String>.from(box.get("takeoverAdExclude", defaultValue: []));
        exclude.add(adResponse.takeover.id);
        box.put("bannerAdExclude", exclude);
      },
      baseUrl: baseUrl,
      style: saaf.TakeoverAdStyle(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        titleColor: Theme.of(context).textTheme.titleLarge!.color!,
        textColor: Theme.of(context).textTheme.bodyMedium!.color!,
        primaryColor: Theme.of(context).colorScheme.primary,
      ),
    );

    try {
      await takeoverAd.load();

      if (takeoverAd.isLoaded) {
        takeoverAd.show(context);
      }
    } catch (e) {
      // No ad found
    }
  }
}

Map<String, List<RegExp>> getClassMappings() {
  var jsonMap =
      json.decode(FirebaseRemoteConfig.instance.getString("class_mappings"));
  Map<String, List<RegExp>> classMappings = {};

  jsonMap.forEach((key, value) {
    List<String> regexStrings = List<String>.from(value);
    classMappings[key] = regexStrings
        .map((regexStr) => RegExp(regexStr, caseSensitive: false))
        .toList();
  });

  return classMappings;
}

String mapClass(String className, {Map<String, List<RegExp>>? classMappings}) {
  if (classMappings is! Map<String, List<RegExp>>) {
    // prevent unnececary fetching and calculation when running this in a loop, pass classMappings as parameter
    classMappings = getClassMappings();
  }

  String unifiedName = className;
  classMappings.forEach((key, regexList) {
    for (RegExp regex in regexList) {
      if (regex.hasMatch(className)) {
        unifiedName = key;
        print('SAAF Mapped "$className" to "$key"');
        break;
      }
    }
  });

  return unifiedName;
}

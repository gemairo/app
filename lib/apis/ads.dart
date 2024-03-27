import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gemairo/apis/saaf.dart';
import 'package:gemairo/widgets/ads.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class Ads {
  String app;
  bool initialized = false;
  int navigations = 0;
  InterstitialAd? _admobInterstitial;

  Ads._({required this.app});

  static const AdRequest request = AdRequest(
    contentUrl: 'https://gemairo.app/index.html',
    nonPersonalizedAds: false,
    keywords: [
      'school',
      'grades',
      'exams',
      'homework',
      'huiswerk',
      'school',
      'bijles',
      'examen',
      'tentamen',
      'magister',
      'somtoday',
      'cijfers',
      'middelbare',
    ],
  );

  static final Map<String, Ads> _adsInstances = {};

  factory Ads._instanceFor({required String app}) {
    return _adsInstances.putIfAbsent(app, () {
      return Ads._(app: app);
    });
  }

  static Ads? get instance {
    if (Platform.isAndroid || Platform.isIOS) {
      String defaultAppInstance = 'gemairo';
      return Ads._instanceFor(app: defaultAppInstance);
    }
    return null;
  }

  Future<void> initialize() async {
    if (initialized == true) {
      return;
    }

    initialized = true;
  }

  Future<void> handleNavigate(String screenName) async {
    navigations++;

    int showInterstitialEvery = FirebaseRemoteConfig.instance
        .getInt('ads_interstial_every_x_navigations');
    if (showInterstitialEvery != 0) {
      navigations++;

      if (navigations % showInterstitialEvery == 0) {
        showInterstitial();
      } else if ((navigations + 1) % showInterstitialEvery == 0) {
        loadIntersitial();
      }
    }

    String unifiedName = mapClass(screenName);
    await FirebaseAnalytics.instance
        .logScreenView(screenName: unifiedName, screenClass: unifiedName);
  }

  String getAdmobUnitId(String type) {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return {
          'banner': 'ca-app-pub-3940256099942544/6300978111',
          'static_banner': 'ca-app-pub-3940256099942544/6300978111',
          'leaderboard': 'ca-app-pub-3940256099942544/6300978111',
          'native': 'ca-app-pub-3940256099942544/2247696110',
          'interstitial': 'ca-app-pub-3940256099942544/1033173712',
          'app_open': 'ca-app-pub-3940256099942544/9257395921',
        }[type]!;
      } else {
        return {
          'banner': 'ca-app-pub-3940256099942544/2934735716',
          'static_banner': 'ca-app-pub-3940256099942544/2934735716',
          'leaderboard': 'ca-app-pub-3940256099942544/2934735716',
          'native': 'ca-app-pub-3940256099942544/3986624511',
          'interstitial': 'ca-app-pub-3940256099942544/4411468910',
          'app_open': 'ca-app-pub-3940256099942544/5575463023',
        }[type]!;
      }
    }

    try {
      var json =
          jsonDecode(FirebaseRemoteConfig.instance.getString('admob_ids'));
      Map<String, List<dynamic>> values = Map<String, List<dynamic>>.from(json);
      List<String> ids = List<String>.from(values[type]!);

      if (ids.isEmpty) {
        debugPrint('admob unit ids is empty');
        return '';
      }

      return ids[Random().nextInt(ids.length)];
    } catch (e) {
      debugPrint('admob ids config error');
      debugPrint(e.toString());
      return '';
    }
  }

  bool shouldShowSaaf() {
    Map<String, int> chances = Map<String, int>.from(
        jsonDecode(FirebaseRemoteConfig.instance.getString("ads_provider")));
    List<String> pool = [];
    chances.forEach((key, value) {
      for (int i = 0; i < value; i++) {
        pool.add(key);
      }
    });
    pool.shuffle();
    return pool[0] == 'saaf' ? true : false;
  }

  Widget bannerAd(BuildContext context, {AdSize size = AdSize.largeBanner}) {
    Widget googleAd = Container(
      constraints: BoxConstraints(
        minHeight: size == AdSize.banner ? 10 : 70.0 + 7.0 + 7.0,
      ),
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Advertisement(
        size: size,
      ),
    );

    if (shouldShowSaaf() == false) {
      return googleAd;
    }

    return Saaf.instance?.bannerAd(context, googleAd) ?? const SizedBox();
  }

  Future<void> showInterstitial() async {
    if (_admobInterstitial != null) {
      await _admobInterstitial!.show();
    }

    return;
  }

  Future<void> loadIntersitial() {
    return InterstitialAd.load(
      adUnitId: getAdmobUnitId("interstitial"),
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          // print('InterstitialAd loaded');
          _admobInterstitial = ad;

          _admobInterstitial!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) =>
                debugPrint('%ad onAdShowedFullScreenContent.'),
            onAdDismissedFullScreenContent: (InterstitialAd ad) async {
              // print('$ad onAdDismissedFullScreenContent.');
              await _admobInterstitial!.dispose();
            },
            onAdFailedToShowFullScreenContent: (_, error) async {
              debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
              await _admobInterstitial!.dispose();
            },
            onAdImpression: (InterstitialAd ad) {
              FirebaseAnalytics.instance.logEvent(
                name: 'ADS_external_impression_interstitial',
                parameters: {'provider': 'admob'},
              );
              debugPrint('$ad impression occurred.');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          FirebaseAnalytics.instance.logEvent(
            name: 'ADS_external_error_interstitial',
            parameters: {'provider': 'admob'},
          );
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  Future checkGDPRConsent() async {
    // gma.ConsentDebugSettings debugSettings = gma.ConsentDebugSettings(
    //   debugGeography: gma.DebugGeography.debugGeographyEea,
    //   testIdentifiers: ['00DC80A9-B62B-4236-A021-BE52621EDFBC'],
    // );
    // gma.ConsentRequestParameters params =
    //     gma.ConsentRequestParameters(consentDebugSettings: debugSettings);

    try {
      await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (e) {
      debugPrint(e.toString());
    }

    ConsentRequestParameters params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          loadGDPRForm();
        }
      },
      (error) {},
    );
  }

  Future loadGDPRForm() async {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        var status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show(
            (FormError? formError) {
              // Handle dismissal by reloading form
              loadGDPRForm();
            },
          );
        }
      },
      (formError) {
        debugPrint(formError.message);
      },
    );
  }
}

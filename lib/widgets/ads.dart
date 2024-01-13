import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/hive/adapters.dart';

class Advertisement extends StatefulWidget {
  const Advertisement({super.key, this.size = AdSize.fluid});

  final AdSize size;

  @override
  State<StatefulWidget> createState() => _Advertisement();
}

class _Advertisement extends State<Advertisement> {
  NativeAd? nativeAd;
  BannerAd? bannerAd;
  bool _nativeAdIsLoaded = false;

  String getAdmobUnitId(String type) {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return {
          'banner': 'ca-app-pub-3940256099942544/6300978111',
          'native': 'ca-app-pub-3940256099942544/2247696110',
          'interstitial': 'ca-app-pub-3940256099942544/1033173712',
          'app_open': 'ca-app-pub-3940256099942544/9257395921',
        }[type]!;
      } else {
        return {
          'banner': 'ca-app-pub-3940256099942544/2934735716',
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

  /// Loads a native ad.
  void loadAd({AdSize size = AdSize.fluid}) async {
    final String unitId = getAdmobUnitId('banner');

    if (unitId.isEmpty) return;

    final AccountProvider acP =
        Provider.of<AccountProvider>(context, listen: false);

    if ((await MobileAds.instance.getRequestConfiguration())
            .tagForUnderAgeOfConsent !=
        (acP.account.underAgeOfConsent
            ? TagForUnderAgeOfConsent.yes
            : TagForUnderAgeOfConsent.no)) {
      MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
          tagForUnderAgeOfConsent: (acP.account.underAgeOfConsent
              ? TagForUnderAgeOfConsent.yes
              : TagForUnderAgeOfConsent.no)));
    }
    bannerAd = BannerAd(
      size: size,
      adUnitId: unitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$BannerAd loaded.');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('$BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      loadAd(size: widget.size);
    });
  }

  @override
  Widget build(BuildContext context) {
    return bannerAd != null && _nativeAdIsLoaded && !config.noAds
        ? ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 320,
              maxHeight:
                  widget.size.height.isInfinite || widget.size.height.isNegative
                      ? 60
                      : widget.size.height.toDouble(),
            ),
            child: AdWidget(ad: bannerAd!))
        : Container();
  }
}

Future loadGDPRForm() async {
  var status = await ConsentInformation.instance.getConsentStatus();
  ConsentForm.loadConsentForm(
    (ConsentForm consentForm) async {
      if (status == ConsentStatus.required) {
        consentForm.show((formError) {
          loadGDPRForm();
        });
      }
    },
    (formError) {
      print(formError.message);
    },
  );
}

class BottomBanner extends StatelessWidget {
  const BottomBanner({super.key, required this.child, this.isEnabled = true});

  final Widget child;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) => Column(children: <Widget>[
        Expanded(child: child),
        if (isEnabled)
          SafeArea(
            child: Container(
                decoration: BoxDecoration(
                    color:
                        Theme.of(context).navigationBarTheme.backgroundColor),
                child: const Advertisement(
                  size: AdSize.fullBanner,
                )),
          ),
      ]);
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/hive/adapters.dart';

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

  final String _adUnitId = Platform.isAndroid
      ? kDebugMode
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-8698376572242605/9384442878'
      : kDebugMode
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-8698376572242605/9975507804';

  /// Loads a native ad.
  void loadAd({AdSize size = AdSize.fluid}) async {
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
      adUnitId: _adUnitId,
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

class BottomBanner extends StatelessWidget {
  const BottomBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Column(children: <Widget>[
        Expanded(child: child),
        SafeArea(
          child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).navigationBarTheme.backgroundColor),
              child: const Advertisement(
                size: AdSize.fullBanner,
              )),
        ),
      ]);
}

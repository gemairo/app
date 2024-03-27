import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gemairo/apis/ads.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gemairo/hive/adapters.dart';

class Advertisement extends StatefulWidget {
  const Advertisement(
      {super.key, this.size = AdSize.fluid, this.type = 'banner'});

  final AdSize size;
  final String type;

  @override
  State<StatefulWidget> createState() => _Advertisement();
}

class _Advertisement extends State<Advertisement> {
  NativeAd? nativeAd;
  BannerAd? bannerAd;
  bool _nativeAdIsLoaded = false;

  /// Loads a native ad.
  void loadAd({AdSize size = AdSize.fluid, String type = 'banner'}) async {
    final String unitId = Ads.instance?.getAdmobUnitId(type) ?? "";

    if (unitId.isEmpty) return;

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
      request: Ads.request,
    )..load();
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (Ads.instance != null) loadAd(size: widget.size, type: widget.type);
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
  const BottomBanner({super.key, required this.child, this.isEnabled});

  final Widget child;
  final bool? isEnabled;

  @override
  Widget build(BuildContext context) {
    bool showAd = !(Platform.isIOS || Platform.isAndroid)
        ? false
        : FirebaseRemoteConfig.instance.getBool('ads_bottom');
    String bannerSize = !(Platform.isIOS || Platform.isAndroid)
        ? ""
        : FirebaseRemoteConfig.instance.getString('ads_bottom_size');

    if (isEnabled != null) {
      showAd = isEnabled!;
    }

    return Column(children: <Widget>[
      Expanded(child: child),
      if (showAd)
        SafeArea(
          child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).navigationBarTheme.backgroundColor),
              child: Advertisement(
                size:
                    bannerSize == 'large' ? AdSize.largeBanner : AdSize.banner,
                type: 'static_banner',
              )),
        ),
    ]);
  }
}

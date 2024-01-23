import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gemairo/widgets/ads.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RateLimitOverlay {
  BuildContext _context;
  static bool isActive = false;

  void hide() {
    if (isActive) Navigator.of(_context).pop();
    isActive = false;
  }

  void show(Duration? duration) {
    if (!isActive) {
      showDialog(
        context: _context,
        barrierDismissible: false,
        builder: (context) => _FullScreenLoader(
          duration: duration,
        ),
      );
    }
    isActive = true;
  }

  Future<void> during<T>(Duration duration) async {
    show(duration);
    await Future.delayed(duration);
    hide();
  }

  RateLimitOverlay._create(this._context);

  factory RateLimitOverlay.of(BuildContext context) {
    return RateLimitOverlay._create(context);
  }
}

class _FullScreenLoader extends StatefulWidget {
  final Duration? duration;

  const _FullScreenLoader({required this.duration});

  @override
  _FullScreenLoaderState createState() => _FullScreenLoaderState();
}

class _FullScreenLoaderState extends State<_FullScreenLoader> {
  Duration? _countdown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    if (widget.duration is Duration) {
      _countdown = widget.duration;
      startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown!.inSeconds > 0) {
            _countdown = _countdown! - const Duration(seconds: 1);
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0.8),
      body: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Even wachten...",
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      "Magister opvraag limiet bereikt. Laat de app open.",
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (_countdown is Duration)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1, end: 0),
                        duration: widget.duration!,
                        builder: (context, value, _) =>
                            CircularProgressIndicator(value: value),
                      ),
                    if (_countdown is! Duration)
                      const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    if (_countdown is Duration)
                      Text(
                        "${_countdown!.inSeconds} seconden resterend",
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                  ]),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 15, right: 15, bottom: 30),
                child: Advertisement(
                  size: AdSize.mediumRectangle,
                  type: 'leaderboard',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

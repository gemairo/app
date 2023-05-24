import 'package:flutter/material.dart';

class ElasticAnimation extends StatelessWidget {
  const ElasticAnimation({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.elasticOut,
                    reverseDuration: const Duration(milliseconds: 10),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      final offsetAnimation = Tween<Offset>(
                              begin: const Offset(0.0, .2),
                              end: const Offset(0.0, 0.0))
                          .animate(animation);
                      return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                          ));
                    },
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.bottomRight,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: child);
  }
}
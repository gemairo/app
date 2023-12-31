import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:silvio/widgets/ads.dart';

class IntroductionSkeleton extends StatelessWidget {
  const IntroductionSkeleton({
    super.key,
    required this.title,
    required this.subTitle,
    this.content,
    this.actions = const [],
    this.icon = Icons.query_stats_rounded,
  });

  final String title;
  final IconData icon;
  final String subTitle;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(scrolledUnderElevation: 0),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding:
                  EdgeInsets.symmetric(vertical: (content != null) ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Icon(
                      icon,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(title,
                        style: Theme.of(context).textTheme.headlineMedium
                          ?..copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Text(subTitle, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            if (content != null)
              Expanded(
                  child: SingleChildScrollView(
                child: content,
              )),
            Padding(
              padding: EdgeInsets.only(top: content != null ? 16.0 : 0),
              child: Wrap(
                alignment: actions.length > 1
                    ? WrapAlignment.spaceBetween
                    : WrapAlignment.end,
                children: actions,
              ),
            )
          ],
        ),
      )),
    );
  }
}

class ScaffoldSkeleton extends StatelessWidget {
  const ScaffoldSkeleton(
      {super.key,
      this.appBar,
      this.children = const [],
      this.onRefresh,
      this.backgroundColor,
      this.sliverAppBar,
      this.bottomNavigationBar});

  final SliverAppBar? sliverAppBar;
  final PreferredSizeWidget? appBar;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Color? backgroundColor;
  final bool showAds = false;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        primary: false,
        appBar: appBar,
        bottomNavigationBar: bottomNavigationBar,
        backgroundColor: backgroundColor,
        body: BottomBanner(
          isEnabled: showAds,
          child: CustomScrollView(
            physics: onRefresh != null
                ? BouncingScrollPhysics(
                    parent: const AlwaysScrollableScrollPhysics(),
                    decelerationRate: Platform.isAndroid
                        ? ScrollDecelerationRate.fast
                        : ScrollDecelerationRate.normal)
                : null,
            slivers: [
              if (sliverAppBar != null)
                DefaultTextStyle(
                    maxLines: 2,
                    style: const TextStyle(overflow: TextOverflow.ellipsis),
                    child: sliverAppBar!),
              if (onRefresh != null)
                CupertinoSliverRefreshControl(
                  onRefresh: onRefresh,
                ),
              children.isNotEmpty
                  ? SliverList.builder(
                      addAutomaticKeepAlives: true,
                      itemCount: children.length + 1,
                      itemBuilder: (BuildContext context, int index) => index ==
                              children.length
                          ? SizedBox(
                              height:
                                  MediaQuery.of(context).viewInsets.bottom + 16,
                            )
                          : children[index],
                    )
                  : SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                          child: Icon(
                        Icons.query_stats_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      )),
                    )
            ],
          ),
        ));
  }
}

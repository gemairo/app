import 'package:flutter/material.dart';
import 'package:gemairo/widgets/ads.dart';

class IntroductionSkeleton extends StatelessWidget {
  const IntroductionSkeleton({
    super.key,
    required this.title,
    required this.subTitle,
    this.content,
    this.actions = const [],
    this.icon = const IconData(0xf201, fontFamily: "Gemairo"),
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
      this.bottomNavigationBar,
      this.injectOverlap = false});

  final SliverAppBar? sliverAppBar;
  final PreferredSizeWidget? appBar;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Color? backgroundColor;
  // final bool showAds = false;
  final Widget? bottomNavigationBar;
  final bool injectOverlap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: appBar != null,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      body: BottomBanner(
        isEnabled: false,
        child: RefreshIndicator.adaptive(
          edgeOffset: (injectOverlap
                  ? NestedScrollView.sliverOverlapAbsorberHandleFor(context)
                      .layoutExtent
                  : 0) ??
              0,
          onRefresh: onRefresh ?? () => Future(() {}),
          notificationPredicate: (notificationPredicate) =>
              onRefresh != null ? true : false,
          child: CustomScrollView(
            slivers: [
              if (injectOverlap)
                SliverOverlapInjector(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
              if (sliverAppBar != null)
                DefaultTextStyle(
                  maxLines: 2,
                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                  child: sliverAppBar!,
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
                          const IconData(0xf201, fontFamily: "Gemairo"),
                          size: 64 * .8,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

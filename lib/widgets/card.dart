import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gemairo/hive/adapters.dart';

class GemairoCard extends StatelessWidget {
  const GemairoCard(
      {super.key,
      required this.child,
      this.title,
      this.leading,
      this.trailing,
      this.isFilled = false,
      this.elevation = 1});

  final Widget child;
  final Widget? title;
  final Widget? leading;
  final Widget? trailing;
  final double elevation;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: isFilled ? 0 : elevation,
        shadowColor: elevation == 1 ? Colors.transparent : null,
        color: isFilled
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : elevation == 0 ? Theme.of(context).colorScheme.surface : null,
        margin: EdgeInsets.zero,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                ListTile(
                  title: DefaultTextStyle(
                    style: Theme.of(context).textTheme.titleMedium!,
                    child: title!,
                  ),
                  leading: leading,
                  trailing: trailing,
                  contentPadding:
                      trailing != null ? const EdgeInsets.only(left: 16) : null,
                  dense: true,
                ),
              child
            ]));
  }
}

class GemairoCardList extends StatelessWidget {
  const GemairoCardList(
      {super.key, required this.children, this.maxCrossAxisExtent = 640});

  final List<Widget> children;
  final double maxCrossAxisExtent;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: StaggeredGrid.extent(
          // primary: false,
          // shrinkWrap: true,
          // cacheExtent: double.maxFinite,
          // itemCount: children.length,
          mainAxisSpacing: 10,
          crossAxisSpacing: 8,
          // itemBuilder: (BuildContext context, int index) => children[index],
          // crossAxisCount: MediaQuery.of(context).size.width < 500 ? 1 : 2,
          maxCrossAxisExtent: maxCrossAxisExtent,
          children: children,
        ));
  }
}

class CarouselCard extends StatefulWidget {
  const CarouselCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  State<StatefulWidget> createState() => _CarouselCard();
}

class _CarouselCard extends State<CarouselCard> {
  int current = 0;
  late final CarouselController controller;
  late final ScrollController scrollController;

  @override
  initState() {
    controller = CarouselController();
    scrollController = ScrollController();
    super.initState();
  }

  @override
  dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GemairoCard(
      title: Text(widget.title),
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CarouselSlider(
                  carouselController: controller,
                  items: widget.children,
                  options: CarouselOptions(
                      enableInfiniteScroll: false,
                      viewportFraction: 1,
                      scrollPhysics: const BouncingScrollPhysics(),
                      autoPlay: config.autoScrollCarousel
                          ? (widget.children.length > 1)
                          : false,
                      autoPlayInterval: Duration(
                        seconds: (math.Random().nextInt(4) + 6),
                      ),
                      onPageChanged: (index, reason) {
                        // scrollController.animateTo()
                        setState(() {
                          current = index;
                        });
                      })),
            ),
            ShaderMask(
              shaderCallback: (Rect rect) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.white
                  ],
                  stops: [0.0, 0.25, 0.75, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstOut,
              child: Center(
                  child: SizedBox(
                height: 50,
                child: (widget.children.length > 1)
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.children.map((entry) {
                            return InkWell(
                              onTap: () => controller.animateToPage(
                                  widget.children.indexWhere((widget) =>
                                      widget.hashCode == entry.hashCode)),
                              child: Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 6.0, horizontal: 4.0),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(current ==
                                                widget.children.indexWhere(
                                                    (widget) =>
                                                        widget.hashCode ==
                                                        entry.hashCode)
                                            ? 0.9
                                            : 0.4)),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : null,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

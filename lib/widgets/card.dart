import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SilvioCard extends StatelessWidget {
  const SilvioCard(
      {super.key,
      required this.child,
      this.title,
      this.leading,
      this.trailing,
      this.elevation = 1});

  final Widget child;
  final Widget? title;
  final Widget? leading;
  final Widget? trailing;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: elevation,
        shadowColor: elevation == 1 ? Colors.transparent : null,
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
                  contentPadding: trailing != null ? const EdgeInsets.only(left: 16) : null,
                  dense: true,
                ),
              child
            ]));
  }
}

class SilvioCardList extends StatelessWidget {
  const SilvioCardList(
      {super.key, required this.children, this.maxCrossAxisExtent = 450});

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
  final CarouselController controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    return SilvioCard(
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
                      autoPlay: (widget.children.length > 1),
                      autoPlayInterval: Duration(
                        seconds: (math.Random().nextInt(4) + 6),
                      ),
                      onPageChanged: (index, reason) {
                        setState(() {
                          current = index;
                        });
                      })),
            ),
            Center(
                child: SizedBox(
              height: 50,
              child: (widget.children.length > 1)
                  ? LayoutBuilder(
                      builder: (context, constraints) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: widget.children
                                .take((constraints.maxWidth / 16).floor())
                                .map((entry) {
                              return GestureDetector(
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
                          )))
                  : null,
            )),
          ],
        ),
      ),
    );
  }
}

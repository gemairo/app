import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';
import 'package:gemairo/widgets/animations.dart';

import 'package:gemairo/widgets/card.dart';

class FactsHeader extends StatefulWidget {
  const FactsHeader({super.key, required this.grades});

  final List<Grade> grades;

  @override
  State<StatefulWidget> createState() => _FactsHeader();
}

class _FactsHeader extends State<FactsHeader> {
  @override
  Widget build(BuildContext context) {
    List<Fact> facts = widget.grades.useable.generateFactsList(
        context, Provider.of<AccountProvider>(context, listen: false).person);

    return StaggeredGrid.extent(
      maxCrossAxisExtent: 100,
      crossAxisSpacing: 10,
      mainAxisSpacing: 8,
      children: [
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1,
          child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: (((MediaQuery.of(context).size.width - 38) / 2)
                            .isNegative)
                        ? 0
                        : (MediaQuery.of(context).size.width - 38) / 2),
                child: FactCard(
                    title: AppLocalizations.of(context)!.average,
                    value: widget.grades.average.isNaN
                        ? "-"
                        : widget.grades.average.displayNumber()),
              )),
        ),
        ...List.generate(facts.length, (index) {
          // return StaggeredGridTile.count(
          //   crossAxisCellCount: 2,
          //   mainAxisCellCount: 1,
          //   child: Text('peop$index'),
          // );
          // List<Widget> cards = facts
          //     .map((fact) => SizedBox(
          //           height: 100,
          //           child: FactCard(
          //             title: fact.title,
          //             value: fact.value.getGradeString,
          //             onTap: fact.onTap,
          //           ),
          //         ))
          //     .toList();
          // if (index == (facts.length / 2).ceil()) {
          //   return FactCard(
          //       title: AppLocalizations.of(context)!.precentSufficient,
          //       value:
          //           "${widget.grades.where((grade) => grade.isSufficient).length}/${widget.grades.length}",
          //       extra: FactCardProgress(
          //         value: widget.grades.getPresentageSufficient() / 100,
          //       ));
          // }
          // return StaggeredGrid.count(
          //     crossAxisSpacing: 8,
          //     crossAxisCount: 2,
          //     children: [
          //       ...cards.getRange(index * 2,
          //           index * 2 + 2 > facts.length ? facts.length : index * 2 + 2)
          //     ]);
          var fact = facts.elementAt(index);
          return StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 1,
            child: SizedBox(
              height: 100,
              child: FactCard(
                title: fact.title,
                value: fact.value.getGradeString,
                onTap: fact.onTap,
              ),
            ),
          );
          // },
          // options: CarouselOptions(
          //   enlargeCenterPage: true,
          //   height: constraints.maxHeight,
          //   scrollDirection: Axis.vertical,
          //   autoPlay: false,
          //   autoPlayInterval: const Duration(seconds: 10),
          //   viewportFraction: 1,
          //   enlargeFactor: .4,
          // ))
          // ],
        }),
        // StaggeredGridTile.count(
        //   crossAxisCellCount: 4,
        //   mainAxisCellCount: 1,
        //   // child: LayoutBuilder(
        //   //     builder: (context, constraints) => AspectRatio(
        //   //           aspectRatio: 4 / 1,
        //   child: Column(
        //     // children: [
        //     //   CarouselSlider.builder(
        //     //       itemCount: (facts.length / 2).ceil() + 1,
        //     //       itemBuilder: (context, index, realIndex) {
        //     children: List.generate((facts.length / 2).ceil() + 1, (index) {
        //       return Text('test');
        //       List<Widget> cards = facts
        //           .map((fact) => SizedBox(
        //                 height: 100,
        //                 child: FactCard(
        //                   title: fact.title,
        //                   value: fact.value.getGradeString,
        //                   onTap: fact.onTap,
        //                 ),
        //               ))
        //           .toList();
        //       if (index == (facts.length / 2).ceil()) {
        //         return FactCard(
        //             title: AppLocalizations.of(context)!.precentSufficient,
        //             value:
        //                 "${widget.grades.where((grade) => grade.isSufficient).length}/${widget.grades.length}",
        //             extra: FactCardProgress(
        //               value: widget.grades.getPresentageSufficient() / 100,
        //             ));
        //       }
        //       return StaggeredGrid.count(
        //           crossAxisSpacing: 8,
        //           crossAxisCount: 2,
        //           children: [
        //             ...cards.getRange(
        //                 index * 2,
        //                 index * 2 + 2 > facts.length
        //                     ? facts.length
        //                     : index * 2 + 2)
        //           ]);
        //       // },
        //       // options: CarouselOptions(
        //       //   enlargeCenterPage: true,
        //       //   height: constraints.maxHeight,
        //       //   scrollDirection: Axis.vertical,
        //       //   autoPlay: false,
        //       //   autoPlayInterval: const Duration(seconds: 10),
        //       //   viewportFraction: 1,
        //       //   enlargeFactor: .4,
        //       // ))
        //       // ],
        //     }),
        //   ),
        //   // )),
        // )
      ],
    );
  }
}

class FactCard extends StatelessWidget {
  const FactCard(
      {super.key,
      required this.title,
      required this.value,
      this.extra,
      this.onTap});

  final String title;
  final String value;
  final Widget? extra;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GemairoCard(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
      child: Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (extra != null) Expanded(child: extra!),
                Container(
                  width: 16,
                ),
                ElasticAnimation(
                    child: Text(
                  value,
                  key: ValueKey(value),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                ))
              ])),
        ),
      ),
    );
  }
}

class FactCardProgress extends StatelessWidget {
  const FactCardProgress({super.key, required this.value});

  // double start = 0;
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: 0,
              end: value,
            ),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                minHeight: 5,
                value: (value.isNaN || value.isInfinite) ? 0 : value,
              );
            }));
  }
}

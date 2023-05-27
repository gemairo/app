import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';

import 'package:silvio/widgets/avatars.dart';
import 'package:silvio/widgets/card.dart';
import 'package:silvio/widgets/navigation.dart';

class RelatedSchoolYearsCard extends StatelessWidget {
  const RelatedSchoolYearsCard({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);
    List<SchoolYear> schoolyears = acP.person.schoolYears
        .where((sY) => sY.grades.relatedSubjectGrades(subject).isNotEmpty)
        .toList();
    return CarouselCard(
      title: AppLocalizations.of(context)!.otherSchoolyears,
      children: schoolyears.length > 1
          ? schoolyears.map((sY) {
              List<Grade> useableGrades =
                  sY.grades.relatedSubjectGrades(subject).toList();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(32)),
                    onTap: () => changeSchoolYear(context, newid: sY.id),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: GradeAvatar(
                                  gradeString: useableGrades.average.isNaN
                                      ? "-"
                                      : useableGrades.average.toString()),
                            )),
                        Text(
                          sY.groupName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          useableGrades.first.subject.name,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        )
                      ],
                    )),
              );
            }).toList()
          : [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.not_interested,
                        color: Theme.of(context).colorScheme.outline,
                        size: 32,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.noOtherSchoolyears,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            ],
    );
  }
}

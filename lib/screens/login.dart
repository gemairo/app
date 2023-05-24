import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:silvio/hive/adapters.dart';

import 'package:silvio/apis/local_file.dart';
import 'package:silvio/apis/random.dart';
import 'package:silvio/apis/somtoday.dart';
import 'package:silvio/apis/magister.dart';

import 'package:silvio/widgets/card.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginView();
}

class _LoginView extends State<LoginView> {
  final List<IconData> backgroundIcons = <IconData>[
    Icons.calculate_outlined,
    Icons.school_outlined,
    Icons.book_outlined,
    Icons.work_outline,
    Icons.history_edu_outlined,
    Icons.bar_chart_outlined,
    Icons.architecture_outlined,
    Icons.functions_outlined,
    Icons.sports_basketball_outlined
  ];
  @override
  Widget build(BuildContext context) {
    List<Widget> icons = List<Widget>.generate(2000, (int index) {
      return Icon(
        backgroundIcons[Random().nextInt(backgroundIcons.length)],
        color: Theme.of(context).colorScheme.surfaceVariant,
      );
    });
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor:
              Theme.of(context).colorScheme.background.withOpacity(0.2),
        ),
        body: Stack(children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Theme.of(context).colorScheme.background,
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 5,
              runSpacing: 5,
              children: icons,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onLongPress: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RandomAccount(Account())
                                    .buildLogin(context),
                              )),
                          child: Icon(
                            Icons.query_stats_rounded,
                            size: Theme.of(context)
                                    .textTheme
                                    .headlineLarge!
                                    .fontSize! *
                                1.5,
                          ),
                        ),
                        Text(
                          " Silvio",
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        )
                      ],
                    ),
                  ),
                ),
                ...loginMethods
                    .map((method) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 16),
                          child: SilvioCard(
                              child: ListTile(
                            leading: CircleAvatar(child: Icon(method.icon)),
                            title: Text(AppLocalizations.of(context)!
                                .loginWith(method.name)),
                            trailing: const Icon(Icons.navigate_next),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      method.buildLogin(context),
                                )),
                          )),
                        ))
                    .toList(),
              ],
            ),
          )
        ]));
  }
}

List<LoginMethod> loginMethods = [
  LoginMethod(
    name: 'Magister',
    buildLogin: Magister(Account()).buildLogin,
  ),
  if (!kReleaseMode)
    LoginMethod(
      name: 'Somtoday',
      buildLogin: SomToDay(Account()).buildLogin,
    ),
  if (!kReleaseMode)
    LoginMethod(
        name: 'Random',
        buildLogin: RandomAccount(Account()).buildLogin,
        icon: Icons.developer_mode),
  LoginMethod(
      name: 'Import',
      buildLogin: LocalFile(Account()).buildLogin,
      icon: Icons.upload_file)
];

class LoginMethod {
  String name;
  Widget Function(BuildContext) buildLogin;
  IconData icon;

  LoginMethod(
      {required this.name, required this.buildLogin, this.icon = Icons.login});
}

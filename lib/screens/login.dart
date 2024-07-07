import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:gemairo/hive/adapters.dart';

import 'package:gemairo/apis/local_file.dart';
import 'package:gemairo/apis/random.dart';
import 'package:gemairo/apis/somtoday.dart';
import 'package:gemairo/apis/magister.dart';

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
  late final List<IconData> icons;

  @override
  void initState() {
    super.initState();
    icons = List<IconData>.generate(
        2000,
        (int index) =>
            backgroundIcons[Random().nextInt(backgroundIcons.length)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor:
              Theme.of(context).colorScheme.surface.withOpacity(0.2),
        ),
        body: Stack(children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Theme.of(context).colorScheme.surface,
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 5,
              runSpacing: 5,
              children: icons
                  .map((e) => Icon(
                        e,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ))
                  .toList(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              const IconData(0xf201, fontFamily: "Gemairo"),
                              size: Theme.of(context)
                                      .textTheme
                                      .headlineLarge!
                                      .fontSize! *
                                  1.50,
                            ),
                          ),
                          Text(
                            "  Gemairo",
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 40,
                                ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      FilledButton.tonal(
                          onPressed: () => otherLoginDialog(context),
                          child: Text(AppLocalizations.of(context)!.other)),
                      FilledButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Magister(Account()).buildLogin(context),
                              )),
                          icon: const Icon(Icons.login),
                          label: Text(AppLocalizations.of(context)!
                              .loginWith("Magister"))),
                    ],
                  ),
                ],
              ),
            ),
          )
        ]));
  }

  Future<void> otherLoginDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login op een andere manier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...otherLoginMethods.map(
                (e) => ListTile(
                    leading: Icon(e.icon),
                    title:
                        Text(AppLocalizations.of(context)!.loginWith(e.name)),
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: e.buildLogin),
                        )),
              ),
            ]
                .map((e) => Card(
                      elevation: 0,
                      child: e,
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

List<LoginMethod> otherLoginMethods = [
  // LoginMethod(
  //   name: 'Magister',
  //   buildLogin: Magister(Account()).buildLogin,
  // ),
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

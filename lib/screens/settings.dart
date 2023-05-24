import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:silvio/hive/extentions.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/hive/adapters.dart';

import 'package:silvio/apis/local_file.dart';
import 'package:silvio/main.dart';
import 'package:silvio/widgets/card.dart';
import 'package:silvio/widgets/cards/list_grade.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Person;
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsView();
}

class _SettingsView extends State<SettingsView> {
  final Map<String, Color> material3Colors = {
    'M3 Baseline': const Color(0xff6750a4),
    'Silvio Violet': const Color(0xff713DCD),
    'Indigo': Colors.indigo,
    'Blue': Colors.blue,
    'Teal': Colors.teal,
    'Green': const Color(0xff386a20),
    'Yellow': Colors.yellow,
    'Orange': Colors.orange,
    'Deep Orange': Colors.deepOrange,
    'Pink': Colors.pink
  };

  @override
  Widget build(BuildContext context) {
    if (AccountManager().personList.isEmpty) {
      Hive.box<Account>('accountList').clear();
      config.activeProfileId = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const Start(),
        ));
      });
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settings),
        ),
        body: ListView(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.lookAndFeel,
                  style: Theme.of(context).textTheme.titleMedium),
              dense: true,
            ),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.darkMode),
              secondary: const Icon(Icons.dark_mode),
              value: config.darkMode,
              onChanged: !config.autoDarkMode
                  ? (bool value) {
                      config.darkMode = value;
                      config.save();
                      setState(() {});
                      Silvio.of(context).update();
                    }
                  : null,
            ),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.autoDarkMode),
              secondary: const Icon(Icons.brightness_auto),
              subtitle: Text(AppLocalizations.of(context)!.autoDarkModeExpl),
              value: config.autoDarkMode,
              onChanged: (bool value) {
                config.autoDarkMode = value;
                config.save();
                setState(() {});
                Silvio.of(context).update();
              },
            ),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.useMaterialYou),
              secondary: const Icon(Icons.color_lens),
              subtitle: Text(AppLocalizations.of(context)!.useMaterialYouExpl),
              value: (!kIsWeb && Platform.isAndroid && config.useMaterialYou),
              onChanged: (!kIsWeb && Platform.isAndroid)
                  ? (bool value) {
                      config.useMaterialYou = value;
                      config.save;
                      setState(() {});
                      Silvio.of(context).update();
                    }
                  : null,
            ),
            if (kIsWeb || !config.useMaterialYou || !Platform.isAndroid)
              ListTile(
                leading: const Icon(Icons.format_color_fill),
                enabled: !config.useMaterialYou,
                subtitle: Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    ...material3Colors.values.map((value) => IconButton(
                          icon: const Icon(Icons.radio_button_unchecked),
                          color: value,
                          isSelected:
                              config.activeMaterialYouColorInt == value.value,
                          selectedIcon: const Icon(Icons.circle),
                          onPressed: () {
                            config.activeMaterialYouColorInt = value.value;
                            config.save();
                            setState(() {});
                            Silvio.of(context).update();
                          },
                        ))
                  ],
                ),
              ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.sufficientBorder),
              leading: const Icon(Icons.grading),
              subtitle:
                  Text(AppLocalizations.of(context)!.sufficientBorderExpl),
              trailing: SizedBox(
                width: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onSubmitted: (value) {
                          config.sufficientFrom = double.parse(value);
                          config.save();
                          setState(() {});
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Provider.of<AccountProvider>(context, listen: false)
                                .changeAccount(null);
                          });
                        },
                        textAlign: TextAlign.center,
                        decoration: InputDecoration.collapsed(
                          hintText: config.sufficientFrom.displayNumber(),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            ListTile(
                title: Text(AppLocalizations.of(context)!.usedLanguage),
                leading: const Icon(Icons.language),
                subtitle: Text(AppLocalizations.of(context)!.usedLanguageExpl),
                trailing: DropdownButton(
                    value: config.usedLocaleCode,
                    onChanged: (value) {
                      config.usedLocaleCode = value;
                      config.save();
                      setState(() {});
                      Silvio.of(context).update();
                    },
                    items: [
                      const DropdownMenuItem(value: null, child: Text("auto")),
                      ...AppLocalizations.supportedLocales.map((locale) =>
                          DropdownMenuItem(
                              value: locale.languageCode,
                              child: Text(locale.toLanguageTag())))
                    ])),
            ListTile(
              title: Text(AppLocalizations.of(context)!.notifications,
                  style: Theme.of(context).textTheme.titleMedium),
              dense: true,
            ),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.grades),
              secondary: const Icon(Icons.notifications_active),
              subtitle: Text(AppLocalizations.of(context)!.notificationsExpl),
              value: config.enableNotifications,
              onChanged: (bool value) async {
                config.enableNotifications = value;
                config.save();
                FlutterLocalNotificationsPlugin
                    flutterLocalNotificationsPlugin =
                    FlutterLocalNotificationsPlugin();
                final bool? androidResult =
                    await flutterLocalNotificationsPlugin
                        .resolvePlatformSpecificImplementation<
                            AndroidFlutterLocalNotificationsPlugin>()
                        ?.requestPermission();
                final bool? iOSResult = await flutterLocalNotificationsPlugin
                    .resolvePlatformSpecificImplementation<
                        IOSFlutterLocalNotificationsPlugin>()
                    ?.requestPermissions(
                      alert: true,
                      badge: true,
                      sound: true,
                    );
                if (androidResult == true || iOSResult == true) {
                  if (!(await Permission
                      .ignoreBatteryOptimizations.isGranted)) {
                    Permission.ignoreBatteryOptimizations.request();
                  }
                  setState(() {});
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Silvio.of(context).update();
                  });
                }
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.personalSettings,
                  style: Theme.of(context).textTheme.titleMedium),
              dense: true,
            ),
            ListTile(
                onTap: () => backupHiveBox<Account>(
                    boxName: 'accountList', context: context),
                title: Text(AppLocalizations.of(context)!.exportAccounts),
                subtitle:
                    Text(AppLocalizations.of(context)!.exportAccountsExpl),
                leading: const Icon(Icons.save),
                trailing: const CircleAvatar(child: Icon(Icons.save_alt))),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Wrap(
                  runSpacing: 10,
                  spacing: 8,
                  children: [
                    ...AccountManager().personList.map((person) => SilvioCard(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("${person.firstName} ${person.lastName}"),
                            Badge(
                              alignment: AlignmentDirectional.centerEnd,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              label: Text(
                                  person.parentAccount!.apiType.name
                                      .capitalize(),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary)),
                            )
                          ],
                        ),
                        leading: CircleAvatar(
                            radius: 20,
                            child: ClipOval(
                                child: AspectRatio(
                                    aspectRatio: 1,
                                    child: person.profilePicture != null ? Image.memory(
                                      base64Decode(person.profilePicture!),
                                      gaplessPlayback: true,
                                      fit: BoxFit.cover,
                                    ) : const Icon(Icons.person)))),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: PersonConfig(
                            person: person,
                            callback: () => setState(() {}),
                          ),
                        ))),
                  ],
                )),
            ListTile(
              title: Text(AppLocalizations.of(context)!.feedbackAndContact,
                  style: Theme.of(context).textTheme.titleMedium),
              dense: true,
            ),
            ListTile(
                onTap: () => launchUrl(
                    Uri(scheme: 'mailto', path: 'silvio@harrydekat.dev'),
                    mode: LaunchMode.externalApplication),
                title: const Text("Email"),
                subtitle: Text(AppLocalizations.of(context)!.discordExpl),
                leading: const Icon(Icons.mail),
                trailing: const CircleAvatar(child: Icon(Icons.open_in_new))),
            ListTile(
                onTap: () => launchUrl(
                    Uri.parse("https://github.com/HarryDeKat/Silvio"),
                    mode: LaunchMode.externalApplication),
                title: const Text("Github"),
                subtitle: Text(AppLocalizations.of(context)!.githubExpl),
                leading: const Icon(FontAwesome5.github),
                trailing: const CircleAvatar(child: Icon(Icons.open_in_new))),
            InkWell(
                onLongPress: () {
                  config.noAds = !config.noAds;
                  config.save();
                  Silvio.of(context).update();
                },
                child: ListTile(
                    onTap: () async {
                      PackageInfo packageInfo =
                          await PackageInfo.fromPlatform();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showLicensePage(
                          context: context,
                          applicationVersion:
                              "${packageInfo.version} (${packageInfo.buildNumber})",
                          applicationName: packageInfo.appName,
                          applicationIcon: const Icon(
                            Icons.query_stats_rounded,
                            size: 32,
                          ),
                        );
                      });
                    },
                    title: Text(AppLocalizations.of(context)!.licenses),
                    subtitle: Text(AppLocalizations.of(context)!.licensesExpl),
                    leading: const Icon(FontAwesome5.file_contract),
                    trailing:
                        const CircleAvatar(child: Icon(Icons.navigate_next)))),
          ],
        ));
  }
}

class PersonConfig extends StatefulWidget {
  const PersonConfig({
    super.key,
    required this.person,
    required this.callback,
  });

  final Person person;
  final void Function() callback;

  @override
  State<StatefulWidget> createState() => _PersonConfig();
}

class _PersonConfig extends State<PersonConfig> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(AppLocalizations.of(context)!.notificationsPersonGrades),
          subtitle: Text(AppLocalizations.of(context)!.notificationsPersonGradesExpl),
          value: widget.person.config.useForGradeCheck,
          onChanged: config.enableNotifications
              ? (bool value) {
                  widget.person.config.useForGradeCheck = value;
                  widget.person.save();
                  setState(() {});
                }
              : null,
        ),
        SwitchListTile(
          title: Text(AppLocalizations.of(context)!.notificationsPersonTests),
          subtitle: Text(AppLocalizations.of(context)!.notificationsPersonTestsExpl),
          value: widget.person.config.useForTestCheck,
          onChanged: config.enableNotifications
              ? (bool value) {
                  widget.person.config.useForTestCheck = value;
                  widget.person.save();
                  setState(() {});
                }
              : null,
        ),
        ListTile(
            title: Text(AppLocalizations.of(context)!.profilePicture),
            subtitle: Text(AppLocalizations.of(context)!.changeProfilePicture),
            trailing: Wrap(children: [
              IconButton(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxHeight: 200,
                        maxWidth: 200);
                    if (image != null) {
                      widget.person.profilePicture =
                          base64Encode(await image.readAsBytes());
                      setState(() {});
                      widget.callback();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Provider.of<AccountProvider>(context, listen: false)
                            .changeAccount(null);
                      });
                    }
                  },
                  icon: const CircleAvatar(child: Icon(Icons.upload))),
              IconButton(
                  onPressed: () async {
                    await widget.person.parentAccount!.api
                        .refreshProfilePicture(widget.person);
                    setState(() {});
                    widget.callback();
                  },
                  icon: const CircleAvatar(child: Icon(Icons.refresh))),
            ])),
        ListTile(
          title: Text(AppLocalizations.of(context)!.resetTurnedOffGrades),
          subtitle: Text(AppLocalizations.of(context)!.resetTurnedOffGradesExpl(
              widget.person.schoolYears
                  .expand((element) => element.grades)
                  .where((element) => !element.isEnabled)
                  .toList()
                  .length)),
          trailing: Wrap(
            children: [
              IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                      List<Grade> grades = widget.person.schoolYears
                          .expand((element) => element.grades)
                          .where((element) => !element.isEnabled)
                          .toList();
                      return Scaffold(
                        appBar: AppBar(
                          title: Text(AppLocalizations.of(context)!
                              .resetTurnedOffGrades),
                        ),
                        body: grades.isNotEmpty
                            ? GradeList(
                                context: context,
                                grades: grades,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.block,
                                  size: 64,
                                ),
                              ),
                      );
                    })).then((value) => setState(() {}));
                  },
                  icon: const CircleAvatar(child: Icon(Icons.list))),
              IconButton(
                  onPressed: () {
                    for (Grade grade in widget.person.schoolYears
                        .expand((element) => element.grades)
                        .where((element) => !element.isEnabled)
                        .toList()) {
                      grade.isEnabled = true;
                    }
                    setState(() {});
                    widget.callback();
                  },
                  icon: const CircleAvatar(child: Icon(Icons.undo)))
            ],
          ),
        ),
        Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(AppLocalizations.of(context)!.activeSchoolyears),
              subtitle:
                  Text(AppLocalizations.of(context)!.activeSchoolyearsExpl),
              children: [
                ...widget.person.rawSchoolYears.map((sY) => CheckboxListTile(
                    title: Text("${sY.groupName} (${sY.groupCode})"),
                    value: sY.isEnabled,
                    onChanged: (value) {
                      sY.isEnabled = value!;
                      widget.person.save();
                      setState(() {});
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Provider.of<AccountProvider>(context, listen: false)
                            .changeAccount(null);
                      });
                    })),
              ],
            )),
        if (widget.person.parentAccount!.api
                .buildConfig(context, person: widget.person) !=
            null)
          ListTile(
              title: Text(AppLocalizations.of(context)!.apiSettings),
              subtitle: Text(AppLocalizations.of(context)!.apiSettingsExpl),
              trailing: Wrap(children: [
                IconButton(
                    onPressed: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => widget
                                .person.parentAccount!.api
                                .buildConfig(context, person: widget.person)!,
                          ));
                    },
                    icon: const CircleAvatar(child: Icon(Icons.api))),
              ])),
        ListTile(
            title: Text(AppLocalizations.of(context)!.logout),
            subtitle: Text(AppLocalizations.of(context)!.logoutExpl),
            trailing: Wrap(children: [
              IconButton(
                  onPressed: () async {
                    Account parentAccount = widget.person.parentAccount!;
                    if (config.activeProfileId == widget.person.uuid) {
                      config.activeProfileId = AccountManager()
                          .personList
                          .firstWhereOrNull(
                              (person) => person.uuid != widget.person.uuid)
                          ?.uuid;
                    }
                    if (parentAccount.profiles.length <= 1) {
                      //Remove whole account
                      widget.person.parentAccount!.api.logout();
                      parentAccount.delete();
                    } else if (parentAccount.profiles.length >= 2) {
                      //Only remove profile from account
                      parentAccount.profiles.removeWhere(
                          (profile) => profile.uuid == widget.person.uuid);
                      if (parentAccount.activeProfile == null) {
                        Provider.of<AccountProvider>(context, listen: false)
                            .changeAccount(
                                AccountManager().personList.first.uuid);
                      }
                      parentAccount.save();
                    }
                    widget.callback();
                  },
                  icon: const CircleAvatar(child: Icon(Icons.logout))),
            ])),
      ],
    );
  }
}

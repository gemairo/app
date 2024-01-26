import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:gemairo/apis/ads.dart';
import 'package:gemairo/widgets/ads.dart';
import 'package:gemairo/widgets/global/skeletons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gemairo/apis/magister.dart';
import 'package:gemairo/hive/extentions.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/hive/adapters.dart';

import 'package:gemairo/apis/local_file.dart';
import 'package:gemairo/main.dart';
import 'package:gemairo/widgets/bottom_sheet.dart';
import 'package:gemairo/widgets/card.dart';
import 'package:gemairo/widgets/cards/list_grade.dart';

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
  final TextEditingController sufficientController = TextEditingController();
  bool hasMaterialYou = false;
  final Map<String, Color> material3Colors = {
    'M3 Baseline': const Color(0xff6750a4),
    'Gemairo Purple': const Color(0xff4f46e5),
    'Indigo': Colors.indigo,
    'Blue': Colors.blue,
    'Teal': Colors.teal,
    'Green': const Color(0xff386a20),
    'Yellow': Colors.yellow,
    'Orange': Colors.orange,
    'Deep Orange': Colors.deepOrange,
    'Pink': Colors.pink
  };

  checkMaterialYou() async {
    var color = await DynamicColorPlugin.getCorePalette();
    setState(() {
      hasMaterialYou = (color != null);
    });
  }

  @override
  void initState() {
    checkMaterialYou();
    super.initState();
  }

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

    return ScaffoldSkeleton(
      sliverAppBar: SliverAppBar.large(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      children: [
        ListTile(
          title: Text(AppLocalizations.of(context)!.lookAndFeel,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
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
                  Gemairo.of(context).update();
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
            Gemairo.of(context).update();
          },
        ),
        Column(
          children: [
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.useMaterialYou),
              secondary: const Icon(Icons.color_lens),
              subtitle: Text(AppLocalizations.of(context)!.useMaterialYouExpl),
              value: config.useMaterialYou,
              onChanged: hasMaterialYou
                  ? (bool value) {
                      config.useMaterialYou = value;
                      config.save();
                      setState(() {});
                      Gemairo.of(context).update();
                    }
                  : null,
            ),
            if (!config.useMaterialYou || !hasMaterialYou)
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
                            Gemairo.of(context).update();
                          },
                        ))
                  ],
                ),
              ),
          ],
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.sufficientBorder),
          leading: const Icon(Icons.grading),
          subtitle: Text(AppLocalizations.of(context)!.sufficientBorderExpl),
          trailing: SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Expanded(
                    flex: 1,
                    child: FocusScope(
                      onFocusChange: (value) {
                        if (!value) {
                          if (double.tryParse(sufficientController.text
                                      .replaceAll(",", '.'))
                                  ?.isFinite ??
                              false) {
                            config.sufficientFrom = double.parse(
                                sufficientController.text.replaceAll(",", '.'));
                          }
                          config.save();
                          setState(() {});
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Provider.of<AccountProvider>(context, listen: false)
                                .changeAccount(null);
                          });
                          FocusScope.of(context).requestFocus(FocusNode());
                        }
                      },
                      child: TextFormField(
                        controller: sufficientController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onTapOutside: (event) {},
                        textAlign: TextAlign.center,
                        decoration: InputDecoration.collapsed(
                          hintText: config.sufficientFrom.displayNumber(),
                        ),
                      ),
                    ))
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
                  Gemairo.of(context).update();
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
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          dense: true,
        ),
        SwitchListTile(
          title: Text(AppLocalizations.of(context)!.notifications),
          secondary: const Icon(Icons.notifications_active),
          subtitle: Text(AppLocalizations.of(context)!.notificationsExpl),
          value: config.enableNotifications,
          onChanged: (bool value) async {
            config.enableNotifications = value;
            config.save();
            FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
                FlutterLocalNotificationsPlugin();
            final bool? androidResult = await flutterLocalNotificationsPlugin
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
              if (!(await Permission.ignoreBatteryOptimizations.isGranted)) {
                Permission.ignoreBatteryOptimizations.request();
              }
              setState(() {});
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Gemairo.of(context).update();
              });
            }
          },
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.personalSettings,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          dense: true,
        ),
        ListTile(
            onTap: () => backupHiveBox<Account>(
                boxName: 'accountList', context: context),
            title: Text(AppLocalizations.of(context)!.exportAccounts),
            subtitle: Text(AppLocalizations.of(context)!.exportAccountsExpl),
            leading: const Icon(Icons.save),
            trailing: const CircleAvatar(child: Icon(Icons.save_alt))),
        PersonConfigCarousel(
          profiles: AccountManager().personList,
          callback: () => setState(() {}),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.feedbackAndContact,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          dense: true,
        ),
        ListTile(
          onTap: () async {
            await Ads.instance?.checkGDPRConsent();
          },
          title: Text("GDPR"),
          leading: const Icon(Icons.ads_click),
          trailing: const CircleAvatar(child: Icon(Icons.navigate_next)),
        ),
        ListTile(
            onTap: () => launchUrl(
                Uri(scheme: 'mailto', path: 'support@gemairo.app'),
                mode: LaunchMode.externalApplication),
            title: const Text("Email"),
            subtitle: Text(AppLocalizations.of(context)!.discordExpl),
            leading: const Icon(Icons.mail),
            trailing: const CircleAvatar(child: Icon(Icons.open_in_new))),
        ListTile(
            onTap: () => launchUrl(Uri.parse("https://discord.gg/uZ7whYj"),
                mode: LaunchMode.externalApplication),
            title: Text("Discord"),
            subtitle: Text(AppLocalizations.of(context)!.settingsDiscordExpl),
            leading: const Icon(Icons.discord),
            trailing: const CircleAvatar(child: Icon(Icons.open_in_new))),
        ListTile(
            onTap: () => launchUrl(
                Uri.parse("https://github.com/Gemairo/app/issues/new/choose"),
                mode: LaunchMode.externalApplication),
            title: Text(AppLocalizations.of(context)!.bugReport),
            subtitle: Text(AppLocalizations.of(context)!.bugReportExpl),
            leading: const Icon(Icons.bug_report),
            trailing: const CircleAvatar(child: Icon(Icons.open_in_new))),
        ListTile(
            onTap: () => launchUrl(Uri.parse("https://github.com/Gemairo/app"),
                mode: LaunchMode.externalApplication),
            title: const Text("Github"),
            subtitle: Text(AppLocalizations.of(context)!.githubExpl),
            leading: const Icon(FontAwesome5.github),
            trailing: const CircleAvatar(child: Icon(Icons.open_in_new))),
        InkWell(
            onLongPress: () {
              config.noAds = !config.noAds;
              config.save();
              Gemairo.of(context).update();
            },
            child: ListTile(
                onTap: () async {
                  PackageInfo packageInfo = await PackageInfo.fromPlatform();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showLicensePage(
                      context: context,
                      applicationVersion:
                          "${packageInfo.version} (${packageInfo.buildNumber})",
                      applicationName: packageInfo.appName,
                      applicationIcon: Icon(
                        const IconData(0xf201, fontFamily: "Gemairo"),
                        size: 64 * 0.8,
                        color: Theme.of(context).colorScheme.primary,
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
    );
  }
}

class PersonConfig extends StatefulWidget {
  const PersonConfig(
      {super.key,
      required this.person,
      required this.callback,
      this.simpleView = false});

  final Person person;
  final void Function() callback;
  final bool simpleView;

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
          subtitle:
              Text(AppLocalizations.of(context)!.notificationsPersonGradesExpl),
          value: widget.person.config.useForGradeCheck,
          onChanged: config.enableNotifications &&
                  (widget.person.parentAccount?.api.isOnline ?? false)
              ? (bool value) {
                  widget.person.config.useForGradeCheck = value;
                  widget.person.save();
                  setState(() {});
                }
              : null,
        ),
        SwitchListTile(
          title: Text(AppLocalizations.of(context)!.notificationsPersonTests),
          subtitle:
              Text(AppLocalizations.of(context)!.notificationsPersonTestsExpl),
          value: widget.person.config.useForTestCheck,
          onChanged: config.enableNotifications &&
                  (widget.person.parentAccount?.api.isOnline ?? false)
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
              if (widget.person.parentAccount?.api.isOnline ?? false)
                IconButton(
                    onPressed: () async {
                      await widget.person.parentAccount!.api
                          .refreshProfilePicture(widget.person);
                      setState(() {});
                      widget.callback();
                    },
                    icon: const CircleAvatar(child: Icon(Icons.refresh))),
            ])),
        if (!widget.simpleView)
          ListTile(
            title: Text(AppLocalizations.of(context)!.resetTurnedOffGrades),
            subtitle: Text(AppLocalizations.of(context)!
                .resetTurnedOffGradesExpl(widget.person.schoolYears
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
                ...widget.person.rawSchoolYears.map((sY) => ListTile(
                      title: Text("${sY.groupName} (${sY.groupCode})"),
                      trailing: Wrap(
                        children: [
                          Checkbox(
                            value: sY.isEnabled,
                            onChanged: (value) {
                              sY.isEnabled = value!;
                              widget.person.save();
                              setState(() {});
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Provider.of<AccountProvider>(context,
                                        listen: false)
                                    .changeAccount(null);
                              });
                            },
                          ),
                          IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: () => showGemairoModalBottomSheet(
                                    context: context,
                                    children: [
                                      SchoolYearSettings(
                                          schoolYear: sY,
                                          save: () {
                                            widget.person.save();
                                            setState(() {});
                                          })
                                    ],
                                  )),
                        ],
                      ),
                    )),
              ],
            )),
        if (widget.person.parentAccount!.api
                    .buildConfig(context, person: widget.person) !=
                null &&
            !widget.simpleView)
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
        if (!widget.simpleView)
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
                        await parentAccount.delete();
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

class PersonConfigCarousel extends StatefulWidget {
  const PersonConfigCarousel(
      {super.key,
      required this.profiles,
      this.simpleView = false,
      this.callback,
      this.widgetsNextToIndicator = const []});

  final List<Person> profiles;
  final bool simpleView;
  final void Function()? callback;
  final List<Widget> widgetsNextToIndicator;

  @override
  State<PersonConfigCarousel> createState() => _PersonConfigCarouselState();
}

class _PersonConfigCarouselState extends State<PersonConfigCarousel> {
  int current = 0;
  final PageController controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ExpandablePageView(
            controller: controller,
            onPageChanged: (value) => setState(() {
              current = value;
            }),
            physics: const BouncingScrollPhysics(),
            children: [
              if (widget.profiles.isEmpty) Container(),
              ...widget.profiles.map((person) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: GemairoCard(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("${person.firstName} ${person.lastName}"),
                          InkWell(
                            onTap: () {
                              if (person.parentAccount!.apiType ==
                                  AccountAPITypes.magister) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SignIn(
                                          alreadyExistingAccount:
                                              person.parentAccount!),
                                    ));
                              }
                            },
                            child: Badge(
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
                            ),
                          )
                        ],
                      ),
                      leading: CircleAvatar(
                          radius: 20,
                          child: ClipOval(
                              child: AspectRatio(
                                  aspectRatio: 1,
                                  child: person.profilePicture != null
                                      ? Image.memory(
                                          base64Decode(
                                              person.profilePicture ?? ""),
                                          gaplessPlayback: true,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.person)))),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PersonConfig(
                          person: person,
                          simpleView: widget.simpleView,
                          callback: widget.callback ?? () => setState(() {}),
                        ),
                      )))),
            ],
          ),
          (widget.profiles.length > 1 ||
                  widget.widgetsNextToIndicator.isNotEmpty)
              ? Center(
                  child: SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (widget.profiles.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.profiles.map((entry) {
                            return InkWell(
                              onTap: () => controller.animateToPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.bounceInOut,
                                  widget.profiles.indexWhere((widget) =>
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
                                                widget.profiles.indexWhere(
                                                    (widget) =>
                                                        widget.hashCode ==
                                                        entry.hashCode)
                                            ? 0.9
                                            : 0.4)),
                              ),
                            );
                          }).toList(),
                        ),
                      ...widget.widgetsNextToIndicator
                    ],
                  ),
                ))
              : Container(),
        ]);
  }
}

class SchoolYearSettings extends StatefulWidget {
  const SchoolYearSettings(
      {super.key, required this.schoolYear, required this.save});

  final SchoolYear schoolYear;
  final void Function() save;

  @override
  State<SchoolYearSettings> createState() => _SchoolYearSettingsState();
}

class _SchoolYearSettingsState extends State<SchoolYearSettings> {
  int subjectExpandableIndex = 0;
  final PageController controller = PageController();

  void save() {
    widget.save();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).changeAccount(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Subject> subjects = widget.schoolYear.grades.subjects
      ..sort((a, b) => a.rawName.compareTo(b.rawName));
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text(AppLocalizations.of(context)!.schoolYearSettings,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          dense: true,
        ),
        SwitchListTile(
          value: widget.schoolYear.isEnabled,
          onChanged: (value) {
            widget.schoolYear.isEnabled = value;
            setState(() {});
            save();
          },
          secondary: const Icon(Icons.visibility_off),
          title: Text(AppLocalizations.of(context)!.turnOnThisSchoolYear),
        ),
        SwitchListTile(
          value: widget.schoolYear.warningEnabled,
          onChanged: (value) {
            widget.schoolYear.warningEnabled = value;
            setState(() {});
            save();
          },
          title: Text(AppLocalizations.of(context)!.avarageWarning),
          secondary: const Icon(Icons.warning_amber_outlined),
          subtitle: Text(AppLocalizations.of(context)!.avarageWarningExpl),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.subjectSettings,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          dense: true,
        ),
        ...subjects.map(
          (subject) => ExpansionTile(
            leading: const CircleAvatar(child: Icon(Icons.book)),
            title: Text(subject.name),
            children: [
              //Change name
              ListTile(
                title: Text(AppLocalizations.of(context)!.subjectName),
                leading: const Icon(Icons.short_text),
                subtitle: Text(AppLocalizations.of(context)!.subjectNameExpl),
                trailing: SizedBox(
                  width: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      IconButton.filledTonal(
                          onPressed: () {
                            widget.schoolYear.grades
                                .where(
                                    (grade) => grade.subject.id == subject.id)
                                .forEach(
                                    (grade) => grade.subject.customName = null);

                            setState(() {});
                            save();
                          },
                          icon: const Icon(Icons.undo)),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          onSubmitted: (value) {
                            widget.schoolYear.grades
                                .where(
                                    (grade) => grade.subject.id == subject.id)
                                .forEach((grade) =>
                                    grade.subject.customName = value);

                            setState(() {});
                            save();
                          },
                          textAlign: TextAlign.center,
                          decoration: InputDecoration.collapsed(
                            hintText: subject.name,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.subjectNameShort),
                leading: const Icon(Icons.short_text),
                subtitle:
                    Text(AppLocalizations.of(context)!.subjectNameShortExpl),
                trailing: SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      IconButton.filledTonal(
                          onPressed: () {
                            widget.schoolYear.grades
                                .where(
                                    (grade) => grade.subject.id == subject.id)
                                .forEach(
                                    (grade) => grade.subject.customCode = null);

                            setState(() {});
                            save();
                          },
                          icon: const Icon(Icons.undo)),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          onSubmitted: (value) {
                            widget.schoolYear.grades
                                .where(
                                    (grade) => grade.subject.id == subject.id)
                                .forEach((grade) =>
                                    grade.subject.customCode = value);

                            setState(() {});
                            save();
                          },
                          textAlign: TextAlign.center,
                          decoration: InputDecoration.collapsed(
                            hintText: subject.code,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SwitchListTile(
                value: subject.warningEnabled,
                onChanged: widget.schoolYear.warningEnabled
                    ? (value) {
                        widget.schoolYear.grades
                            .where((grade) => grade.subject.id == subject.id)
                            .forEach((grade) =>
                                grade.subject.warningEnabled = value);
                        setState(() {});
                        save();
                      }
                    : null,
                title: Text(AppLocalizations.of(context)!.avarageWarning),
                secondary: const Icon(Icons.warning_amber_outlined),
                subtitle: Text(
                    AppLocalizations.of(context)!.avarageWarningExplSubject),
              ),
              SwitchListTile(
                value: subject.roundOnDecimals != null,
                onChanged: (value) {
                  widget.schoolYear.grades
                      .where((grade) => grade.subject.id == subject.id)
                      .forEach((grade) =>
                          grade.subject.roundOnDecimals = value ? 1 : null);
                  setState(() {});
                  save();
                },
                title: Text(AppLocalizations.of(context)!.decimals),
                secondary: const Icon(Icons.calculate_outlined),
                subtitle: Text(AppLocalizations.of(context)!.decimalsExpl),
              ),
              if (subject.roundOnDecimals != null)
                Slider(
                  onChanged: (double value) {
                    widget.schoolYear.grades
                        .where((grade) => grade.subject.id == subject.id)
                        .forEach((grade) =>
                            grade.subject.roundOnDecimals = value.toInt());
                    setState(() {});
                  },
                  onChangeEnd: (value) => save(),
                  divisions: 2,
                  min: 0,
                  max: 2,
                  label: "${subject.roundOnDecimals}",
                  value: subject.roundOnDecimals?.toDouble() ?? 0,
                )
              //Change roundOnDecimals
              //Disable ??
            ],
          ),
        )
      ],
    );
  }
}

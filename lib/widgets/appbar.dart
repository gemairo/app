import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';

import 'package:gemairo/screens/login.dart';
import 'package:gemairo/screens/settings.dart';
import 'package:gemairo/widgets/navigation.dart';

class GemairoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GemairoAppBar(
      {super.key,
      this.title,
      this.enableYearSwitcher = true,
      this.forceElevated});

  final Widget? title;
  final bool enableYearSwitcher;

  /// If this value is non-null a [SliverAppBar] will be returned
  final bool? forceElevated;
  static final Key dismissibleKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);

    List<Widget> actions = [
      if (enableYearSwitcher)
        DropdownButtonHideUnderline(
            child: DropdownButton<int>(
                value: acP.schoolYear.id,
                items: acP.person.rawSchoolYears
                    .map<DropdownMenuItem<int>>((SchoolYear schoolYear) {
                  return DropdownMenuItem<int>(
                    value: schoolYear.id,
                    enabled: schoolYear.isEnabled,
                    child: Text(
                      schoolYear.groupCode,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: !schoolYear.isEnabled ? Colors.grey : null),
                    ),
                  );
                }).toList(),
                onChanged: (int? value) {
                  changeSchoolYear(context, newid: value!);
                })),
      Dismissible(
        key: dismissibleKey,
        dismissThresholds: const {DismissDirection.vertical: 0.25},
        direction: AccountManager().personList.length == 1
            ? DismissDirection.none
            : DismissDirection.vertical,
        resizeDuration: null,
        confirmDismiss: (DismissDirection direction) {
          navigateUpOrDownPersonList(context,
              AccountManager().personList.indexOf(acP.person), direction);
          return Future.value(false);
        },
        child: IconButton(
          key: ValueKey<int>(acP.person.uuid),
          icon: CircleAvatar(
              radius: 25,
              child: ClipOval(
                  child: AspectRatio(
                      aspectRatio: 1,
                      child: SizedBox(
                          height: 40,
                          child: acP.person.profilePicture != null
                              ? Image.memory(
                                  base64Decode(acP.person.profilePicture!),
                                  gaplessPlayback: true,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.person))))),
          onPressed: () => showDialog<String>(
              builder: (BuildContext context) {
                return AccountSwitcher(context: context);
              },
              context: context),
        ),
      )
    ];

    return forceElevated != null
        ? SliverAppBar(
            title: title == null ? Text(acP.schoolYear.groupName) : title!,
            pinned: true,
            forceElevated: forceElevated!,
            actions: actions,
          )
        : AppBar(
            centerTitle: false,
            title: Padding(
                padding: const EdgeInsets.all(4),
                child: title == null ? Text(acP.schoolYear.groupName) : title!),
            actions: actions,
          );
  }

  @override
  Size get preferredSize => AppBar(
        toolbarHeight: 56,
      ).preferredSize;
}

navigateUpOrDownPersonList(
    BuildContext context, int accountIndex, DismissDirection direction) {
  int newindex = accountIndex + (direction == DismissDirection.down ? -1 : 1);
  int accounts = (AccountManager().personList.length - 1);
  newindex = (newindex > accounts)
      ? 0
      : (newindex < 0)
          ? accounts
          : newindex;
  changeProfile(context, newid: AccountManager().personList[newindex].uuid);
}

class AccountSwitcher extends StatelessWidget {
  const AccountSwitcher({super.key, required context});

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconData(0xf201, fontFamily: "Gemairo"),
                          weight: 700,
                          size: 28 * 0.8,
                        ),
                        Text(
                          "  Gemairo",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        )
                      ],
                    ),
                  ),
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceBright,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: AccountManager().personList.length,
                            prototypeItem: ListTile(
                              title: Text(
                                  AccountManager().personList.first.firstName),
                            ),
                            itemBuilder: (context, index) {
                              Person person =
                                  AccountManager().personList[index];
                              return ListTile(
                                onTap: () {
                                  Navigator.pop(context);
                                  changeProfile(context, newid: person.uuid);
                                },
                                enabled: !(person.uuid ==
                                    AccountManager()
                                        .getActive()
                                        .activeProfile!
                                        .uuid),
                                title: Text([
                                  person.firstName,
                                  person.middleName,
                                  person.lastName
                                ].nonNulls.join(" ")),
                                leading: CircleAvatar(
                                    radius: 25,
                                    child: ClipOval(
                                        child: AspectRatio(
                                            aspectRatio: 1,
                                            child: person.profilePicture != null
                                                ? Image.memory(
                                                    base64Decode(
                                                        person.profilePicture!),
                                                    gaplessPlayback: true,
                                                    fit: BoxFit.cover,
                                                  )
                                                : const Icon(Icons.person)))),
                              );
                            },
                          ),
                          Divider(
                            color: ElevationOverlay.applySurfaceTint(
                                Theme.of(context).colorScheme.surfaceBright,
                                Theme.of(context).colorScheme.surfaceTint,
                                1),
                            thickness: 4,
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginView()));
                            },
                            title:
                                Text(AppLocalizations.of(context)!.addAccount),
                            leading: const CircleAvatar(
                                radius: 25,
                                child: ClipOval(child: Icon(Icons.person_add))),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsView()));
                            },
                            title: Text(AppLocalizations.of(context)!.settings),
                            leading: const CircleAvatar(
                                radius: 25,
                                child: ClipOval(child: Icon(Icons.settings))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: Text("© Gemairo Group • HarryDeKat")),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}

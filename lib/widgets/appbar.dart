import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:silvio/apis/account_manager.dart';
import 'package:silvio/hive/adapters.dart';

import 'package:silvio/screens/login.dart';
import 'package:silvio/screens/settings.dart';
import 'package:silvio/widgets/navigation.dart';

class SilvioAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SilvioAppBar({super.key, this.title, this.enableYearSwitcher = true});

  final String? title;
  final bool enableYearSwitcher;
  static final Key dismissibleKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);
    return AppBar(
      title: Padding(
          padding: const EdgeInsets.all(4),
          child: title == null ? Text(acP.schoolYear.groupName) : Text(title!)),
      actions: <Widget>[
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
                          child: acP.person.profilePicture != null
                              ? Image.memory(
                                  base64Decode(acP.person.profilePicture!),
                                  gaplessPlayback: true,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.person)))),
              onPressed: () => showDialog<String>(
                  builder: (BuildContext context) {
                    return AccountSwitcher(context: context);
                  },
                  context: context),
            ))
      ],
    );
  }

  @override
  Size get preferredSize => AppBar().preferredSize;
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
                      Icons.query_stats_rounded,
                      weight: 700,
                      size: 28,
                    ),
                    Text(
                      " Silvio",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    )
                  ],
                ),
              ),
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AccountManager().personList.length,
                prototypeItem: ListTile(
                  title: Text(AccountManager().personList.first.firstName),
                ),
                itemBuilder: (context, index) {
                  Person person = AccountManager().personList[index];
                  return ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      changeProfile(context, newid: person.uuid);
                    },
                    enabled: !(person.uuid ==
                        AccountManager().getActive().activeProfile!.uuid),
                    title: Text("${person.firstName} ${person.lastName}"),
                    leading: CircleAvatar(
                        radius: 25,
                        child: ClipOval(
                            child: AspectRatio(
                                aspectRatio: 1,
                                child: person.profilePicture != null
                                    ? Image.memory(
                                        base64Decode(person.profilePicture!),
                                        gaplessPlayback: true,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.person)))),
                  );
                },
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginView()));
                },
                title: Text(AppLocalizations.of(context)!.addAccount),
                leading: const CircleAvatar(
                    radius: 25, child: ClipOval(child: Icon(Icons.person_add))),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsView()));
                },
                title: Text(AppLocalizations.of(context)!.settings),
                leading: const CircleAvatar(
                    radius: 25, child: ClipOval(child: Icon(Icons.settings))),
              ),
              const Divider(),
              const Center(child: Text("Harry de Kat")),
            ],
          ),
        ),
      ),
    ));
  }
}

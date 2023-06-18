import 'dart:io';

import 'package:cr_file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:silvio/apis/abstact_api.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/main.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocalFile implements Api {
  @override
  Account account;
  LocalFile(this.account);

  @override
  late bool isOnline = false;

  @override
  Widget? buildConfig(BuildContext context, {required Person person}) {
    return null;
  }

  @override
  Widget buildLogin(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: restoreHiveBox<Account>(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).popUntil((r) => r.isFirst);
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => const Start(),
              ));
            });
          }
          if (snapshot.hasError) {
            print(snapshot.error);
            return Center(
              child: AlertDialog(
                actionsAlignment: MainAxisAlignment.start,
                title: Text(AppLocalizations.of(context)!.somethingWentWrong),
                content:
                    Text(AppLocalizations.of(context)!.localfileFailedWarning),
                actions: [
                  FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.navigate_before),
                      label: Text(AppLocalizations.of(context)!.back))
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  @override
  Future<void> refreshAll(Person person) async {}

  @override
  Future<void> refreshCalendarEvents(Person person) async {}

  @override
  Future<void> refreshGrade(Person person, Grade grade) async {}

  @override
  Future<void> refreshProfilePicture(Person person) async {}

  @override
  Future<void> refreshSchoolYear(Person person, SchoolYear schoolYear,
      void Function(int completed, int total) progress) async {}

  Future<bool> restoreHiveBox<T>() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final box = await Hive.openBox<Account>('tmpAccountlistBox');
      final boxPath = box.path;
      await box.close();

      //Get acccounts from imported box
      await File(result.files.single.path!).copy(boxPath!);
      await Hive.openBox<Account>('tmpAccountlistBox');
      List<Account> importedAccounts = Hive.box<Account>('tmpAccountlistBox')
          .values
          .toList()
          .map((e) => e.copy)
          .toList();
      Hive.deleteBoxFromDisk('tmpAccountlistBox');
      //Remove accounts that already exist
      importedAccounts.removeWhere((element) => Hive.box<Account>('accountList')
          .values
          .map((e) => e.uuid)
          .contains(element.uuid));
      //Change the API type, add all the imported accounts & change the active account ID
      for (Account importedAccount in importedAccounts) {
        importedAccount.apiType = AccountAPITypes.localFile;
      }
      Hive.box<Account>('accountList').addAll(importedAccounts);
      return Future.value(true);
    } else {
      throw 'No file selected';
    }
  }

  @override
  Future<void> logout() async {}
}

Future<void> backupHiveBox<T>(
    {required String boxName, BuildContext? context}) async {
  String? selectedDirectory =
      Platform.isIOS ? await FilePicker.platform.getDirectoryPath() : '';

  if (selectedDirectory != null) {
    final box = Hive.box<T>(boxName);
    final boxPath = box.path;
    await box.close();

    try {
      if (Platform.isAndroid) {
        CRFileSaver.saveFileWithDialog(SaveFileDialogParams(
            sourceFilePath: boxPath!,
            destinationFileName:
                "Accounts-${DateTime.now().millisecondsSinceEpoch}.Silvio"));
      } else {
        File(boxPath!).copy(
            "$selectedDirectory/Accounts-${DateTime.now().millisecondsSinceEpoch}.Silvio");
      }
    } catch (e) {
      if (context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) =>
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  AppLocalizations.of(context)?.somethingWentWrong ?? "Error"),
              showCloseIcon: true,
            )));
      }
    } finally {
      await Hive.openBox<T>(boxName);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:gemairo/apis/saaf.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';
import 'package:hive/hive.dart';

class AccountManager {
  late List<Account> accountsList =
      Hive.box<Account>('accountList').values.toList().unique((x) => x.uuid);
  late List<Person> personList = accountsList
      .map((e) => e.profiles)
      .expand((x) => x)
      .toList()
      .unique((x) => x.uuid);

  Account getActive() {
    if (accountsList.isNotEmpty) {
      List<Account> accountListWithActiveProfile = accountsList
          .where((account) => account.profiles
              .map((profile) => profile.uuid)
              .contains(config.activeProfileId))
          .toList();
      if (accountListWithActiveProfile.isNotEmpty) {
        return accountListWithActiveProfile.first;
      } else {
        //No active account has been set, setting one...
        config.activeProfileId = accountsList.first.profiles.first.uuid;
        config.save();
        return accountsList.first;
      }
    } else {
      return Account();
    }
  }

  bool alreadyExists(Account account, {bool unsaved = false}) =>
      accountsList.map((e) => e.uuid).contains(account.uuid) ||
      personList.map((e) => unsaved ? e.id : e.uuid).any((uuid) =>
          account.profiles.map((e) => unsaved ? e.id : e.uuid).contains(uuid));

  void addAccount(Account account) {
    if (!alreadyExists(account)) {
      Hive.box<Account>('accountList').add(account);
    }
  }
}

class AccountProvider extends ChangeNotifier {
  Account get account => AccountManager().getActive();

  Person get person => AccountManager().getActive().activeProfile!;

  SchoolYear get schoolYear =>
      AccountManager().getActive().activeProfile!.activeSchoolYear;

  List<Filter> get _activeFilters =>
      AccountManager().getActive().activeProfile!.activeFilters;
  List<Filter> activeFilters({bool isGlobal = false}) => isGlobal
      ? _activeFilters
      : _activeFilters.where((f) => !f.isGlobal).toList();

  void changeAccount(int? newid) {
    config.activeProfileId = newid ?? config.activeProfileId;
    config.save();
    notifyListeners();
    Saaf.instance.setAdRequest(force: true);
  }

  void changeSchoolYear(int newid) {
    person.config.activeSchoolYearId = newid;
    person.activeFilters.clear();
    account.save();
    notifyListeners();
  }

  void addToFilter(Filter filter, {bool isGlobal = false}) {
    _activeFilters.add(filter..isGlobal = isGlobal);
    notifyListeners();
  }

  void removeFromFilterWhere(bool Function(Filter) test) {
    _activeFilters.removeWhere(test);
    notifyListeners();
  }
}

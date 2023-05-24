import 'package:flutter/material.dart';
import 'package:silvio/hive/adapters.dart';
import 'package:silvio/hive/extentions.dart';
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

  List<Filter> get activeFilters =>
      AccountManager().getActive().activeProfile!.activeFilters;

  void changeAccount(int? newid) {
    config.activeProfileId = newid ?? config.activeProfileId;
    config.save();
    notifyListeners();
  }

  void changeSchoolYear(int newid) {
    person.config.activeSchoolYearId = newid;
    person.activeFilters.clear();
    account.save();
    notifyListeners();
  }

  void addToFilter(Filter filter) {
    activeFilters.add(filter);
    notifyListeners();
  }

  void removeFromFilterWhere(bool Function(Filter) test) {
    activeFilters.removeWhere(test);
    notifyListeners();
  }
}

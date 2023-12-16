part of 'package:gemairo/apis/somtoday.dart';

Future<List<SomToDaySchool>> getSchools() async {
  var test = (await Dio().get('https://servers.somtoday.nl/organisaties.json'))
      .data
      .first["instellingen"];
  return Future.value(List.from(test.map((e) => SomToDaySchool(e))));
}

class SomToDaySchool {
  String location = "";
  String name = "";
  String uuid = "";

  SomToDaySchool(Map map) {
    location = map["plaats"] != ""
        ? map["plaats"].toString().toLowerCase().capitalize()
        : "Onbekend";
    name = map["naam"];
    uuid = map["uuid"];
  }
}

class SchoolPicker extends StatelessWidget {
  const SchoolPicker(this.account, {super.key});
  final Account account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.chooseaSchool),
        ),
        body: FutureBuilder(
          future: getSchools(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              TextEditingController controller = TextEditingController();
              ValueNotifier<String> valueListenable = ValueNotifier<String>("");
              return ValueListenableBuilder(
                  valueListenable: valueListenable,
                  builder: (context, value, _) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: GemairoCard(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: TextField(
                                controller: controller,
                                onTapOutside: (event) => FocusScope.of(context)
                                    .requestFocus(FocusNode()),
                                onChanged: (value) =>
                                    valueListenable.value = value,
                                decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search),
                                    border: InputBorder.none,
                                    hintText: AppLocalizations.of(context)!
                                        .searchaSchool,
                                    filled: false),
                              ),
                            ),
                          ),
                        ),
                        ...snapshot.data!
                            .where((school) =>
                                school.location.toLowerCase().contains(
                                    valueListenable.value.toLowerCase()) ||
                                school.name.toLowerCase().contains(
                                    valueListenable.value.toLowerCase()))
                            .map((e) => ListTile(
                                  title: Text(e.name),
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.school),
                                  ),
                                  trailing: const Icon(Icons.navigate_next),
                                  subtitle: Text(e.location),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            _SignIn(account, e.uuid),
                                      )),
                                ))
                      ],
                    );
                  });
            }
            if (snapshot.hasError) {
              return const Center(child: Icon(Icons.warning_amber));
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ));
  }
}

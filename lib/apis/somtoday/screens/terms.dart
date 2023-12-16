part of 'package:gemairo/apis/somtoday.dart';

class Terms extends StatefulWidget {
  const Terms(this.account, {super.key});
  final Account account;

  @override
  State<StatefulWidget> createState() => _Terms();
}

class _Terms extends State<Terms> {
  bool accepted = false;
  @override
  Widget build(BuildContext context) {
    String company = "Topicus";
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.terms),
        ),
        body:
            Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text.rich(TextSpan(
                  style: Theme.of(context).textTheme.headlineSmall,
                  children: <TextSpan>[
                    TextSpan(
                        text:
                            AppLocalizations.of(context)!.termsContent(company),
                        style: Theme.of(context).textTheme.bodyMedium),
                  ]))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            InkWell(
                onTap: () => setState(() {
                      accepted = !accepted;
                    }),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Checkbox(
                    value: accepted,
                    onChanged: (value) => setState(() {
                      accepted = value!;
                    }),
                  ),
                  Text(
                    AppLocalizations.of(context)!.agree,
                  ),
                ])),
            FilledButton.icon(
                icon: const Icon(Icons.navigate_next),
                onPressed: accepted
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SchoolPicker(widget.account),
                        ))
                    : null,
                label: Text(AppLocalizations.of(context)!.gContinue)),
          ])
        ]));
  }
}

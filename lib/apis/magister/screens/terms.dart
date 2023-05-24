part of 'package:silvio/apis/magister.dart';

class Terms extends StatefulWidget {
  const Terms({super.key});

  @override
  State<StatefulWidget> createState() => _Terms();
}

class _Terms extends State<Terms> {
  bool accepted = false;
  @override
  Widget build(BuildContext context) {
    String company = "Iddink Group";
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.terms),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: 
                      Text.rich(TextSpan(
                          style: Theme.of(context).textTheme.headlineSmall,
                          children: <TextSpan>[
                            TextSpan(
                                text: AppLocalizations.of(context)!
                                    .termsContent(company),
                                style: Theme.of(context).textTheme.bodyMedium)]),)
          ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                            onTap: () => setState(() {
                                  accepted = !accepted;
                                }),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
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
                                      builder: (context) => const SignIn(),
                                    ))
                                : null,
                            label:
                                Text(AppLocalizations.of(context)!.gContinue)),
                      ])
                ]),
          ),
        ));
  }
}

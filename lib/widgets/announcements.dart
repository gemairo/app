import 'package:flutter/material.dart';
import 'package:gemairo/widgets/card.dart';
import 'package:url_launcher/url_launcher.dart';

class Announcement {
  String title;
  String body;
  List<Map<String, Uri>> buttons;

  Announcement(
      {required this.title, required this.body, this.buttons = const []});
}

Future<List<Announcement>> getAnnouncements() async {
  return Future.value([]);
  // var data =
  //     (await Dio().get('https://silvio.harrydekat.dev/announcements.json'))
  //         .data;
  // return data
  //     .map<Announcement>((data) => Announcement(
  //         title: data["title"],
  //         body: data["body"],
  //         buttons: data["buttons"]
  //             .map<Map<String, Uri>>(
  //                 (e) => {e["title"].toString(): Uri.parse(e["url"])})
  //             .toList()))
  //     .toList();
}

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return GemairoCard(
        elevation: 2,
        title: Text(announcement.title),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(announcement.body),
              Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: announcement.buttons
                      .map((e) => FilledButton(
                          onPressed: () => launchUrl(
                              e.entries.toList().first.value,
                              mode: LaunchMode.externalApplication),
                          child: Text(e.entries.toList().first.key)))
                      .toList()),
            ],
          ),
        ));
  }
}

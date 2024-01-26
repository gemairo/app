import 'dart:convert';
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:gemairo/widgets/card.dart';
import 'package:url_launcher/url_launcher.dart';

class Announcement {
  String title;
  String body;
  bool urgent;
  List<Map<String, Uri>> buttons;

  Announcement(
      {required this.title,
      required this.body,
      required this.urgent,
      this.buttons = const []});
}

List<Announcement> getAnnouncements() {
  if (!(Platform.isIOS || Platform.isAndroid)) return [];
  var data =
      jsonDecode(FirebaseRemoteConfig.instance.getString('announcements'));
  return data
      .map<Announcement>((data) => Announcement(
          title: data["title"],
          body: data["body"],
          urgent: data["urgent"],
          buttons: data["buttons"]
              .map<Map<String, Uri>>(
                  (e) => {e["title"].toString(): Uri.parse(e["url"])})
              .toList()))
      .toList();
}

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return GemairoCard(
        isFilled: announcement.urgent,
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
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: FilledButton(
                            onPressed: () => launchUrl(
                              e.entries.toList().first.value,
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Text(e.entries.toList().first.key),
                          ),
                        ),
                      )
                      .toList()),
            ],
          ),
        ));
  }
}

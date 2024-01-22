import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gemairo/apis/ads.dart';
import 'package:gemairo/widgets/ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gemairo/hive/adapters.dart' hide PersonConfig;
import 'package:gemairo/main.dart';
import 'package:gemairo/screens/settings.dart';

class SettingsReminder extends StatefulWidget {
  const SettingsReminder({super.key, required this.account});

  final Account account;

  @override
  State<StatefulWidget> createState() => _SettingsReminder();
}

class _SettingsReminder extends State<SettingsReminder> {
  @override
  void dispose() {
    super.dispose();
    Ads.instance.checkGDPRConsent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: Center(
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(children: [
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.notifications),
                    secondary: const Icon(Icons.notifications_active),
                    subtitle:
                        Text(AppLocalizations.of(context)!.notificationsExpl),
                    value: config.enableNotifications,
                    onChanged: (bool value) async {
                      config.enableNotifications = value;
                      config.save();
                    },
                  ),
                  PersonConfigCarousel(
                    profiles: widget.account.profiles,
                    simpleView: true,
                    widgetsNextToIndicator: [
                      FilledButton.icon(
                          icon: const Icon(Icons.navigate_next),
                          onPressed: () async {
                            FlutterLocalNotificationsPlugin
                                flutterLocalNotificationsPlugin =
                                FlutterLocalNotificationsPlugin();
                            final bool? androidResult =
                                await flutterLocalNotificationsPlugin
                                    .resolvePlatformSpecificImplementation<
                                        AndroidFlutterLocalNotificationsPlugin>()
                                    ?.requestPermission();
                            final bool? iOSResult =
                                await flutterLocalNotificationsPlugin
                                    .resolvePlatformSpecificImplementation<
                                        IOSFlutterLocalNotificationsPlugin>()
                                    ?.requestPermissions(
                                      alert: true,
                                      badge: true,
                                      sound: true,
                                    );
                            if (androidResult == true || iOSResult == true) {
                              if (!(await Permission
                                  .ignoreBatteryOptimizations.isGranted)) {
                                try {
                                  Permission.ignoreBatteryOptimizations
                                      .request();
                                } catch (e) {
                                  print(e);
                                }
                              }
                              setState(() {});
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Gemairo.of(context).update();
                              });
                            }

                            await FirebaseMessaging.instance.requestPermission(
                              alert: true,
                              announcement: false,
                              badge: true,
                              carPlay: false,
                              criticalAlert: false,
                              provisional: false,
                              sound: true,
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Start(),
                              ),
                            );
                          },
                          label: Text(AppLocalizations.of(context)!.gContinue)),
                    ],
                  ),
                ])),
          ),
        ),
      ),
    );
  }
}

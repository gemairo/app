import UIKit
import AppTrackingTransparency
import flutter_local_notifications
import Flutter
import GoogleMobileAds

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // This is required to make any communication available in the action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }
      
    if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
      
    func applicationDidBecomeActive(_ application: UIApplication) {
        if #available(iOS 15.0, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                  
            })
        }
    }
      
    GeneratedPluginRegistrant.register(with: self)
    GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "bae27ae297f1ea60743b27eb5351b744" ]
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

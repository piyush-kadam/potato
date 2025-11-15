import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {  // ✅ REMOVED the duplicate protocol declaration
                         
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Register Flutter Plugins
    GeneratedPluginRegistrant.register(with: self)

    // ------------------------------------------------------------
    // 🚨 REQUIRED FOR LOCAL NOTIFICATIONS
    // ------------------------------------------------------------
    UNUserNotificationCenter.current().delegate = self

    // Ask permission for alerts, sounds, badges
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { granted, error in
      if let error = error {
        print("Notification permission error: \(error)")
      } else {
        print("Notification permission granted: \(granted)")
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ------------------------------------------------------------
  // 🚨 REQUIRED: Show notifications when app is in foreground
  // ------------------------------------------------------------
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .sound]) // Show normally
  }
}
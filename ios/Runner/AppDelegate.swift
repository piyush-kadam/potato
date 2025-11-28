import Flutter
import UIKit
import UserNotifications
import Intents

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    // Siri shortcuts method channel
    private var shortcutsChannel: FlutterMethodChannel?
                         
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Register Flutter Plugins
        GeneratedPluginRegistrant.register(with: self)
        
        // ------------------------------------------------------------
        // 🚨 SIRI SHORTCUTS SETUP
        // ------------------------------------------------------------
        let controller = window?.rootViewController as! FlutterViewController
        
        // Setup method channel for Siri shortcuts
        shortcutsChannel = FlutterMethodChannel(
            name: "com.potato.slideme/shortcuts",
            binaryMessenger: controller.binaryMessenger
        )
        
        shortcutsChannel?.setMethodCallHandler { [weak self] (call, result) in
            if call.method == "setupShortcuts" {
                self?.donateShortcuts()
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
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
    // 🚨 SIRI: Donate shortcuts to iOS
    // ------------------------------------------------------------
    private func donateShortcuts() {
        // Shortcut 1: Open App
        let openAppActivity = NSUserActivity(activityType: "com.potato.slideme.openApp")
        openAppActivity.title = "Open Potato Book"
        openAppActivity.isEligibleForPrediction = true
        openAppActivity.isEligibleForSearch = true
        openAppActivity.persistentIdentifier = "openApp"
        openAppActivity.suggestedInvocationPhrase = "Open Potato Book"
        openAppActivity.becomeCurrent()
        
        // Shortcut 2: Open Analytics
        let openAnalyticsActivity = NSUserActivity(activityType: "com.potato.slideme.openAnalytics")
        openAnalyticsActivity.title = "Open Potato Book Analytics"
        openAnalyticsActivity.isEligibleForPrediction = true
        openAnalyticsActivity.isEligibleForSearch = true
        openAnalyticsActivity.persistentIdentifier = "openAnalytics"
        openAnalyticsActivity.suggestedInvocationPhrase = "Open Potato Book Analytics"
        openAnalyticsActivity.becomeCurrent()
        
        // Shortcut 3: Open Settings
        let openSettingsActivity = NSUserActivity(activityType: "com.potato.slideme.openSettings")
        openSettingsActivity.title = "Open Settings in Potato Book"
        openSettingsActivity.isEligibleForPrediction = true
        openSettingsActivity.isEligibleForSearch = true
        openSettingsActivity.persistentIdentifier = "openSettings"
        openSettingsActivity.suggestedInvocationPhrase = "Open Settings in Potato Book"
        openSettingsActivity.becomeCurrent()
        
        print("✅ Siri shortcuts donated successfully")
    }
    
    // ------------------------------------------------------------
    // 🚨 SIRI: Handle when app continues from Siri shortcut
    // ------------------------------------------------------------
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        print("📱 Received Siri activity: \(userActivity.activityType)")
        
        // Send the command to Flutter
        switch userActivity.activityType {
        case "com.potato.slideme.openApp":
            shortcutsChannel?.invokeMethod("openApp", arguments: nil)
            print("✅ Invoked: openApp")
        case "com.potato.slideme.openAnalytics":
            shortcutsChannel?.invokeMethod("openAnalytics", arguments: nil)
            print("✅ Invoked: openAnalytics")
        case "com.potato.slideme.openSettings":
            shortcutsChannel?.invokeMethod("openSettings", arguments: nil)
            print("✅ Invoked: openSettings")
        default:
            print("❌ Unknown activity type")
            break
        }
        
        return true
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
// main.dart
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:home_widget/home_widget.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:slideme/auth/splash.dart';
import 'package:slideme/screens/profile.dart';
import 'package:slideme/screens/settings.dart';
import 'package:slideme/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable debug logs (very helpful while developing)
  await Purchases.setDebugLogsEnabled(true);

  // Use the platform-specific public SDK key:
  // - appl_... => iOS public SDK key (App Store)
  // - public Android key (starts with goog_? or similar) => Play Store
  final String revenueCatKey;
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    revenueCatKey =
        "appl_UmcrQrsvFzOgkfJmcFsmioBNrlS"; // iOS key from your console screenshot
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    revenueCatKey =
        "YOUR_ANDROID_PUBLIC_KEY_HERE"; // ⚠ Replace with Android public key
  } else {
    revenueCatKey = "appl_UmcrQrsvFzOgkfJmcFsmioBNrlS"; // fallback
  }
  await HomeWidget.setAppGroupId('group.com.potato.slideme');
  await Purchases.configure(PurchasesConfiguration(revenueCatKey));

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Global navigator key for navigation from Siri shortcuts
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Method channel for iOS Siri shortcuts
  static const platform = MethodChannel('com.potato.slideme/shortcuts');

  @override
  void initState() {
    super.initState();
    _setupSiriShortcuts();
    _handleSiriCommands();
  }

  // Setup Siri shortcuts on app launch
  void _setupSiriShortcuts() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await platform.invokeMethod('setupShortcuts');
        print('Siri shortcuts setup completed');
      } on PlatformException catch (e) {
        print("Failed to setup Siri shortcuts: ${e.message}");
      }
    }
  }

  // Handle incoming Siri commands
  void _handleSiriCommands() {
    platform.setMethodCallHandler((call) async {
      print('Received Siri command: ${call.method}');

      // Wait a bit to ensure navigation is ready
      await Future.delayed(const Duration(milliseconds: 300));

      switch (call.method) {
        case 'openApp':
          // App opens automatically, just reset to home if needed
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
          break;

        case 'openAnalytics':
          // Navigate to your profile/analytics page
          navigatorKey.currentState?.pushNamed('/analytics');
          break;

        case 'openSettings':
          // Navigate to your settings page
          navigatorKey.currentState?.pushNamed('/settings');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Important: Add navigator key
      title: 'PotatoBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
      // Define your routes here
      routes: {
        '/analytics': (context) =>
            const ProfilePage(), // Replace with your actual ProfilePage
        '/settings': (context) =>
            const SettingsPage(), // Replace with your actual SettingsPage
      },
    );
  }
}

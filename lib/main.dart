// main.dart
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:home_widget/home_widget.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:slideme/auth/splash.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slideme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
    );
  }
}

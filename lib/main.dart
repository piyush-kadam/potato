import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:slideme/auth/authgate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:slideme/auth/splash.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env safely
  try {
    await dotenv.load(fileName: ".env");
    // Optional: print to verify the key
    if (kDebugMode) {
      print("OPENAI_API_KEY: ${dotenv.env['OPENAI_API_KEY']}");
    }
  } catch (e) {
    print("Warning: .env file not loaded: $e");
  }

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Slideme',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
    );
  }
}

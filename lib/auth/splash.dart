import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slideme/screens/motnhlywrap.dart';
import 'package:slideme/auth/authgate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late GifController _gifController;

  @override
  void initState() {
    super.initState();
    _gifController = GifController(vsync: this);
  }

  @override
  void dispose() {
    _gifController.dispose();
    super.dispose();
  }

  Future<void> _handleNavigationLogic() async {
    final now = DateTime.now();
    final isFirstDayOfMonth = now.day == 1;
    final prefs = await SharedPreferences.getInstance();
    final shownKey = "wrapper_shown_${now.year}_${now.month}";
    final hasShownWrapper = prefs.getBool(shownKey) ?? false;

    if (isFirstDayOfMonth && !hasShownWrapper) {
      await prefs.setBool(shownKey, true);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MonthlyWrapScreen()),
      );
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        // ensures it covers full screen
        child: Gif(
          controller: _gifController,
          image: const AssetImage('assets/images/splash.gif'),
          autostart: Autostart.once,
          onFetchCompleted: () {
            // Navigate after the GIF completes
            Timer(const Duration(seconds: 3), _handleNavigationLogic);
          },
          fit: BoxFit.cover, // fills the screen, cropping if needed
        ),
      ),
    );
  }
}

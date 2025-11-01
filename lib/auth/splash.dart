import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
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

  void _navigateToAuthGate() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5FB567), // Your brand green color
      body: SizedBox.expand(
        child: Gif(
          controller: _gifController,
          image: const AssetImage('assets/images/splash.gif'),
          autostart: Autostart.once,

          onFetchCompleted: () {
            // Navigate 3 seconds after GIF starts
            Timer(const Duration(seconds: 3), _navigateToAuthGate);
          },
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

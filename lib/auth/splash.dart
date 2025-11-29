import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:slideme/auth/authgate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late GifController _gifController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _gifController = GifController(vsync: this);
  }

  @override
  void dispose() {
    _gifController.dispose();
    _audioPlayer.dispose();
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
      backgroundColor: const Color(0xFF5FB567),
      body: SizedBox.expand(
        child: Gif(
          controller: _gifController,
          image: const AssetImage('assets/images/splashg.gif'),
          autostart: Autostart.once,

          onFetchCompleted: () async {
            _gifController.forward();

            // Start sound 1 second after animation begins
            Timer(const Duration(milliseconds: 115), () {
              _audioPlayer.play(AssetSource("images/splash.mp3"));
            });

            // Total sync duration still 3 seconds
            Timer(const Duration(seconds: 3), _navigateToAuthGate);
          },
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

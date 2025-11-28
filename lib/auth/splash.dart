import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:slideme/auth/authgate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/images/splashvideo.mp4',
    );

    await _videoController.initialize();
    await _videoController.setLooping(false);

    setState(() {});

    // Start playback
    _videoController.play();

    print('Video initialized and playing');
    print('Duration: ${_videoController.value.duration}');

    // Play audio after 700ms
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _audioPlayer.play(AssetSource("images/splash.mp3"));
      }
    });

    // Listen for video end
    _videoController.addListener(() {
      if (_videoController.value.position >= _videoController.value.duration &&
          _videoController.value.duration.inMilliseconds > 0 &&
          !_hasNavigated) {
        _hasNavigated = true;
        _navigateToAuthGate();
      }
    });

    // Backup timer in case listener fails
    Future.delayed(const Duration(seconds: 5), () {
      if (!_hasNavigated && mounted) {
        _hasNavigated = true;
        _navigateToAuthGate();
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
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
      body: _videoController.value.isInitialized
          ? Stack(
              children: [
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                ),
              ],
            )
          : Container(color: const Color(0xFF5FB567)),
    );
  }
}

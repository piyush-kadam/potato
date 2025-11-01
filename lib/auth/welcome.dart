import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slideme/auth/phoneno.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xff5FB567),
      body: SafeArea(
        child: Stack(
          children: [
            // Background with image behind solid color
            Positioned.fill(
              child: Stack(
                children: [
                  // Background Image (behind)
                  Image.asset(
                    'assets/images/bgg.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: const Color(0xff5FB567)),
                  ),

                  // Solid green color overlay (your exact color)
                ],
              ),
            ),

            // Main content with animation
            const _WelcomeContent(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatefulWidget {
  const _WelcomeContent();

  @override
  State<_WelcomeContent> createState() => _WelcomeContentState();
}

class _WelcomeContentState extends State<_WelcomeContent>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // Entrance animation controllers
  late AnimationController _entranceController;
  late Animation<double> _fadeSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Start floating immediately
    _floatController.repeat(reverse: true);

    // Smooth fade-in and slide-up animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeSlideAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    // Start entrance animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive scaling
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    final scaleFactor = isSmallScreen ? 0.9 : (isMediumScreen ? 0.95 : 1.0);

    return AnimatedBuilder(
      animation: _fadeSlideAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeSlideAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _fadeSlideAnimation.value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Speech bubble
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0 * scaleFactor),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 30 * scaleFactor,
                vertical: 20 * scaleFactor,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Hi there! I'm Potato.",
                    style: GoogleFonts.poppins(
                      fontSize: 18 * scaleFactor,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4 * scaleFactor),
                  Text(
                    "Your Money Pal",
                    style: GoogleFonts.poppins(
                      fontSize: 16 * scaleFactor,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 40 * scaleFactor),

          // Floating mascot - starts immediately
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: Transform.rotate(angle: 0.35, child: child),
              );
            },
            child: Image.asset(
              'assets/images/mascot2.png',
              height: 220 * scaleFactor,
              width: 220 * scaleFactor,
              errorBuilder: (context, error, stackTrace) =>
                  Text('🥔', style: TextStyle(fontSize: 120 * scaleFactor)),
            ),
          ),

          const Spacer(flex: 3),

          // Let's Go button with press effect
          _PressableButton(scaleFactor: scaleFactor),

          SizedBox(height: 50 * scaleFactor),
        ],
      ),
    );
  }
}

class _PressableButton extends StatefulWidget {
  final double scaleFactor;

  const _PressableButton({required this.scaleFactor});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.0 * widget.scaleFactor),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff2E5D33).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xff8BD497).withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Material(
            color: const Color(0xff4A8C51),
            borderRadius: BorderRadius.circular(30),
            elevation: 0,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PhoneInputPage()),
                );
              },
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 18 * widget.scaleFactor,
                ),
                child: Center(
                  child: Text(
                    "LET'S GO!",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16 * widget.scaleFactor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

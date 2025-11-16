import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/widgets/buttons/neopop_button/neopop_button.dart';
import 'package:slideme/screens/homepage.dart';
import 'package:slideme/screens/welcome.dart';

class GOTPPage extends StatefulWidget {
  final String verificationId;
  final String fullName;
  final String phone;
  final bool isAfterGoogleSignIn; // Flag to check if after Google sign-in
  final String? userId; // User ID from Google sign-in

  const GOTPPage({
    super.key,
    required this.verificationId,
    required this.fullName,
    required this.phone,
    this.isAfterGoogleSignIn = false,
    this.userId,
  });

  @override
  State<GOTPPage> createState() => _GOTPPageState();
}

class _GOTPPageState extends State<GOTPPage> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isOtpComplete = false;
  bool _isVerifying = false;

  // Animation controllers - INCREASED DURATION
  late AnimationController _contentAnimationController;
  late AnimationController _otpBoxesController;
  late Animation<double> _backButtonAnimation;
  late Animation<double> _resendAnimation;
  late Animation<double> _verifyButtonAnimation;
  late Animation<double> _bottomTextAnimation;
  late List<Animation<double>> _otpBoxAnimations;

  @override
  void initState() {
    super.initState();

    // INCREASED DURATION from 1000ms to 1800ms for more noticeable fade
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // INCREASED DURATION from 800ms to 1600ms for OTP boxes
    _otpBoxesController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    // Extended intervals with slower fade curves
    _backButtonAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _resendAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
    );

    _verifyButtonAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOut),
    );

    _bottomTextAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    // Create MORE NOTICEABLE staggered animations for each OTP box
    _otpBoxAnimations = List.generate(6, (index) {
      final start = 0.0 + (index * 0.12); // Increased spacing
      final end = start + 0.35; // Longer duration per box
      return CurvedAnimation(
        parent: _otpBoxesController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    // Add listeners to all controllers
    for (var controller in _controllers) {
      controller.addListener(_checkOtpComplete);
    }

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentAnimationController.forward();
      _otpBoxesController.forward();
    });
  }

  @override
  void dispose() {
    _contentAnimationController.dispose();
    _otpBoxesController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _checkOtpComplete() {
    final otp = _otp;
    final isComplete = otp.length == 6;
    if (isComplete != _isOtpComplete) {
      setState(() {
        _isOtpComplete = isComplete;
      });
    }
  }

  String get _otp => _controllers.map((controller) => controller.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      _controllers[index].text = value[0];
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    } else {
      // Handle backspace - move to previous field
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _verifyOtp() async {
    final otp = _otp;

    if (otp.length != 6) {
      _showSnackBar('Enter valid 6-digit OTP', isError: true);
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      if (widget.isAfterGoogleSignIn && widget.userId != null) {
        // For Google sign-in users, just link the phone credential
        // Don't create a new auth user, just update the existing document
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == widget.userId) {
          // Link phone credential to existing Google account
          await currentUser.linkWithCredential(credential);
        }

        // Update the SAME document with phone verification
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.userId)
            .update({
              'phone': widget.phone,
              'phoneVerified': true,
              'otpVerified': true,
              'timestamp': FieldValue.serverTimestamp(),
            });
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const NamePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isVerifying = false);
      _showSnackBar('OTP Error: ${e.message}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError
            ? Colors.red.shade600
            : const Color(0xFF5FB567),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _resendCode() {
    _showSnackBar('Code resent successfully');
  }

  Widget _buildAnimatedElement({
    required Animation<double> animation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(opacity: animation.value, child: child);
      },
      child: child,
    );
  }

  Widget _buildOtpBox(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final scaleFactor = isSmallScreen ? 0.85 : 1.0;

    return AnimatedBuilder(
      animation: _otpBoxAnimations[index],
      builder: (context, child) {
        return Opacity(opacity: _otpBoxAnimations[index].value, child: child);
      },
      child: Container(
        width: 42 * scaleFactor,
        height: 52 * scaleFactor,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 20 * scaleFactor,
            fontWeight: FontWeight.w600,
          ),
          keyboardType: TextInputType.number,
          maxLength: 1,
          showCursor: false,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) => _onDigitChanged(value, index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final scaleFactor = isSmallScreen ? 0.9 : 1.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xff5FB567),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bgg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xff5FB567)),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 35 * scaleFactor,
                vertical: 30 * scaleFactor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back Button with Loading Bar - Animated
                  _buildAnimatedElement(
                    animation: _backButtonAnimation,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(8 * scaleFactor),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24 * scaleFactor,
                            ),
                          ),
                        ),
                        SizedBox(width: 12 * scaleFactor),
                        // Loading Bar
                        Expanded(
                          child: Container(
                            height: 4 * scaleFactor,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _isOtpComplete ? 0.5 : 0.25,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // OTP Boxes with smooth staggered fade-in
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3 * scaleFactor,
                        ),
                        child: _buildOtpBox(index),
                      );
                    }),
                  ),

                  SizedBox(height: 24 * scaleFactor),

                  // Resend OTP - Animated
                  _buildAnimatedElement(
                    animation: _resendAnimation,
                    child: GestureDetector(
                      onTap: _resendCode,
                      child: Text(
                        'Resend OTP',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14 * scaleFactor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30 * scaleFactor),

                  // Verify Button - Animated
                  _buildAnimatedElement(
                    animation: _verifyButtonAnimation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: _isOtpComplete
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xff2E5D33,
                                  ).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xff8BD497,
                                  ).withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, -2),
                                ),
                              ]
                            : [],
                      ),
                      child: Material(
                        color: _isOtpComplete
                            ? const Color(0xff4A8C51)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          onTap: (_isVerifying || !_isOtpComplete)
                              ? null
                              : _verifyOtp,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 18 * scaleFactor,
                            ),
                            child: Center(
                              child: _isVerifying
                                  ? SizedBox(
                                      width: 20 * scaleFactor,
                                      height: 20 * scaleFactor,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _isOtpComplete
                                                  ? Colors.white
                                                  : Colors.white.withOpacity(
                                                      0.5,
                                                    ),
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "VERIFY",
                                      style: GoogleFonts.poppins(
                                        color: _isOtpComplete
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.5),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16 * scaleFactor,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom Text - Animated
                  _buildAnimatedElement(
                    animation: _bottomTextAnimation,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 20 * scaleFactor),
                      child: Text(
                        'Your data is safe with us 🔒',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13 * scaleFactor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

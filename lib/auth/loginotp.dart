import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slideme/screens/homepage.dart';

class OTPVerificationPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPVerificationPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage>
    with TickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _isOtpComplete = false;
  bool _isVerifying = false;
  bool _isResending = false;
  int remainingSeconds = 60;
  Timer? timer;
  String? newVerificationId;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _verifyButtonAnimation;

  @override
  void initState() {
    super.initState();
    startTimer();

    // Fade-in onboarding animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    // Button pop animation
    _verifyButtonAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.6,
      upperBound: 1.0,
    )..forward();

    // Listen for OTP completion
    _pinController.addListener(_checkOtpComplete);
  }

  @override
  void dispose() {
    timer?.cancel();
    _fadeController.dispose();
    _verifyButtonAnimation.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _checkOtpComplete() {
    final isComplete = _pinController.text.length == 6;
    if (isComplete != _isOtpComplete) {
      setState(() => _isOtpComplete = isComplete);
    }
  }

  void startTimer() {
    remainingSeconds = 60;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _clearSkipLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_skipped_login');
  }

  Future<void> _verifyOtp() async {
    HapticFeedback.heavyImpact();
    String otp = _pinController.text;
    if (otp.length != 6) return;

    setState(() => _isVerifying = true);
    try {
      final verificationIdToUse = newVerificationId ?? widget.verificationId;

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationIdToUse,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _clearSkipLoginState();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Invalid OTP or expired. Try again.",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> resendOTP() async {
    try {
      setState(() => _isResending = true);
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _clearSkipLoginState();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isResending = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isResending = false;
            newVerificationId = verificationId;
          });
          startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('OTP sent successfully'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _isResending = false);
    }
  }

  Widget _buildAnimatedElement({
    required AnimationController animation,
    required Widget child,
    double scaleStart = 0.8,
  }) {
    return ScaleTransition(
      scale: Tween(
        begin: scaleStart,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    double scaleFactor = MediaQuery.of(context).textScaleFactor;
    double screenWidth = MediaQuery.of(context).size.width;

    // Pinput theme
    final defaultPinTheme = PinTheme(
      width: 55,
      height: 55,
      textStyle: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: const Color(0xff2E5D33),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff4A8C51), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff4A8C51).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xff5FB567),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bgg.png', fit: BoxFit.cover),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 60,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),

                    Text(
                      "Enter OTP",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "We've sent a code to ${widget.phoneNumber}",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Pinput OTP Input
                    Pinput(
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      length: 6,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      showCursor: true,
                      cursor: Container(
                        width: 2,
                        height: 24,
                        color: const Color(0xff4A8C51),
                      ),
                      keyboardType: TextInputType.number,
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onCompleted: (pin) {
                        _pinFocusNode.unfocus();
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) _verifyOtp();
                        });
                      },
                    ),

                    const SizedBox(height: 35),

                    // Verify Button - Animated
                    _buildAnimatedElement(
                      animation: _verifyButtonAnimation,
                      scaleStart: 0.6,
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

                    const SizedBox(height: 25),

                    GestureDetector(
                      onTap: remainingSeconds == 0 && !_isResending
                          ? resendOTP
                          : null,
                      child: Text(
                        remainingSeconds > 0
                            ? "Resend OTP in ${remainingSeconds}s"
                            : _isResending
                            ? "Resending..."
                            : "Resend OTP",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          decoration: remainingSeconds == 0
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Colors.white.withOpacity(0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Your data is safe with us 🔒",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

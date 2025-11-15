import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/widgets/buttons/neopop_button/neopop_button.dart';
import 'package:slideme/screens/homepage.dart';
import 'package:slideme/screens/welcome.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OTPPage extends StatefulWidget {
  final String verificationId;
  final String fullName;
  final String phone;

  const OTPPage({
    super.key,
    required this.verificationId,
    required this.fullName,
    required this.phone,
  });

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage>
    with TickerProviderStateMixin, CodeAutoFill {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isOtpComplete = false;
  bool _isVerifying = false;

  // Animation controllers
  late AnimationController _contentAnimationController;
  late AnimationController _otpBoxesController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late Animation<double> _backButtonAnimation;
  late Animation<double> _resendAnimation;
  late Animation<double> _verifyButtonAnimation;
  late Animation<double> _bottomTextAnimation;
  late List<Animation<double>> _otpBoxAnimations;

  @override
  void initState() {
    super.initState();

    // Fade animations - enhanced smoothness
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _otpBoxesController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.25, end: 0.5).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _backButtonAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );

    _resendAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
    );

    _verifyButtonAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.6, 0.9, curve: Curves.easeOutCubic),
    );

    _bottomTextAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.8, 1.0, curve: Curves.easeOutCubic),
    );

    _otpBoxAnimations = List.generate(6, (index) {
      final start = 0.1 + (index * 0.08);
      final end = start + 0.35;
      return CurvedAnimation(
        parent: _otpBoxesController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    for (var controller in _controllers) {
      controller.addListener(_checkOtpComplete);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentAnimationController.forward();
      _otpBoxesController.forward();
      // Focus first box for immediate input
      _focusNodes[0].requestFocus();
    });

    // ✅ Start listening for SMS OTP
    listenForCode();
  }

  // ✅ SMS Autofill callback - automatically called when OTP is detected
  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      _fillOtpAutomatically(code!);
    }
  }

  void _fillOtpAutomatically(String otp) {
    if (!mounted) return;

    for (int i = 0; i < 6 && i < otp.length; i++) {
      _controllers[i].text = otp[i];
    }
    setState(() {
      _isOtpComplete = true;
    });

    // Unfocus all to hide keyboard
    for (var node in _focusNodes) {
      node.unfocus();
    }

    // Auto-verify after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isOtpComplete) {
        _verifyOtp();
      }
    });
  }

  @override
  void dispose() {
    cancel(); // ✅ Stop listening for SMS
    _contentAnimationController.dispose();
    _otpBoxesController.dispose();
    _progressController.dispose();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _checkOtpComplete() {
    final otp = _otp;
    final isComplete = otp.length == 6;
    if (isComplete != _isOtpComplete) {
      setState(() => _isOtpComplete = isComplete);
      if (isComplete) {
        _progressController.forward();
      } else {
        _progressController.reverse();
      }
    }
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(String value, int index) {
    // Handle paste - if multiple digits detected
    if (value.length > 1) {
      _handlePaste(value, index);
      return;
    }

    if (value.isNotEmpty) {
      // Single digit entered
      _controllers[index].text = value[0];
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last box filled, unfocus
        _focusNodes[index].unfocus();
      }
    }
  }

  void _handlePaste(String pastedText, int startIndex) {
    // Extract only digits from pasted text
    final digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');

    // Fill boxes starting from current index
    for (int i = 0; i < digits.length && (startIndex + i) < 6; i++) {
      _controllers[startIndex + i].text = digits[i];
    }

    // Move focus to next empty box or last box
    final nextEmptyIndex = _controllers.indexWhere((c) => c.text.isEmpty);
    if (nextEmptyIndex != -1) {
      _focusNodes[nextEmptyIndex].requestFocus();
    } else {
      _focusNodes[5].unfocus();
    }

    setState(() {}); // Trigger rebuild to check completion
  }

  void _handleBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      // Current box is empty, move to previous box and clear it
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    } else {
      // Current box has content, just clear it
      _controllers[index].clear();
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

      await _auth.signInWithCredential(credential);

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(_auth.currentUser!.uid)
          .set({
            'name': widget.fullName,
            'phone': widget.phone,
            'otpVerified': true,
            'phoneVerified': true,
            'profileCompleted': true,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const NamePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        String errorMessage = 'OTP verification failed';
        if (e.code == 'invalid-verification-code') {
          errorMessage = 'Invalid OTP. Please try again.';
        } else if (e.code == 'session-expired') {
          errorMessage = 'OTP expired. Please request a new one.';
        }
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        _showSnackBar('An error occurred. Please try again.', isError: true);
      }
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

  void _resendCode() async {
    setState(() => _isVerifying = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final smsCode = credential.smsCode;
          if (smsCode != null && smsCode.length == 6) {
            _fillOtpAutomatically(smsCode);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            _showSnackBar('Failed to resend code', isError: true);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            _showSnackBar('Code resent successfully');
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Widget _buildAnimatedElement({
    required Animation<double> animation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: Curves.easeInOut.transform(animation.value),
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 20),
            child: child,
          ),
        );
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
          showCursor: true,
          // ✅ Enable iOS autofill on first box
          autofillHints: index == 0 ? [AutofillHints.oneTimeCode] : null,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(
              6,
            ), // Allow paste of multiple digits
          ],
          onChanged: (value) => _onDigitChanged(value, index),
          onTap: () {
            // Select all text when tapping (helps with replacing)
            _controllers[index].selection = TextSelection(
              baseOffset: 0,
              extentOffset: _controllers[index].text.length,
            );
          },
          // Handle backspace key
          onEditingComplete: () {
            if (_controllers[index].text.isEmpty && index < 5) {
              _focusNodes[index + 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final scaleFactor = isSmallScreen ? 0.9 : 1.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xff5FB567),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bgg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xff5FB567)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 35 * scaleFactor,
                vertical: 30 * scaleFactor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, _) {
                              return Container(
                                height: 4 * scaleFactor,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _isOtpComplete
                                      ? _progressAnimation.value
                                      : 0.25,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
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
                  _buildAnimatedElement(
                    animation: _resendAnimation,
                    child: GestureDetector(
                      onTap: _isVerifying ? null : _resendCode,
                      child: Text(
                        'Resend OTP',
                        style: GoogleFonts.poppins(
                          color: _isVerifying
                              ? Colors.white.withOpacity(0.5)
                              : Colors.white,
                          fontSize: 14 * scaleFactor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30 * scaleFactor),
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

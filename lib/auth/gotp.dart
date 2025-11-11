import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/widgets/buttons/neopop_button/neopop_button.dart';
import 'package:slideme/screens/homepage.dart';
import 'package:slideme/screens/welcome.dart';
import 'package:sms_autofill/sms_autofill.dart'; // Add this to pubspec.yaml

class GOTPPage extends StatefulWidget {
  final String verificationId;
  final String fullName;
  final String phone;
  final bool isAfterGoogleSignIn;
  final String? userId;

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

class _GOTPPageState extends State<GOTPPage>
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
  late Animation<double> _backButtonAnimation;
  late Animation<double> _resendAnimation;
  late Animation<double> _verifyButtonAnimation;
  late Animation<double> _bottomTextAnimation;
  late List<Animation<double>> _otpBoxAnimations;

  @override
  void initState() {
    super.initState();

    // Start listening for SMS
    _listenForOtp();

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _otpBoxesController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

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

    _otpBoxAnimations = List.generate(6, (index) {
      final start = 0.0 + (index * 0.12);
      final end = start + 0.35;
      return CurvedAnimation(
        parent: _otpBoxesController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    for (var controller in _controllers) {
      controller.addListener(_checkOtpComplete);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentAnimationController.forward();
      _otpBoxesController.forward();
    });
  }

  // Listen for OTP from SMS
  void _listenForOtp() async {
    await SmsAutoFill().listenForCode();
  }

  @override
  void codeUpdated() {
    // This is called when SMS OTP is detected
    if (code != null && code!.length == 6) {
      _fillOtp(code!);
    }
  }

  // Fill OTP into boxes
  void _fillOtp(String otp) {
    for (int i = 0; i < otp.length && i < 6; i++) {
      _controllers[i].text = otp[i];
    }
    setState(() {
      _checkOtpComplete();
    });
    // Unfocus to hide keyboard after auto-fill
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    cancel(); // Cancel SMS listener
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
    if (value.length > 1) {
      // Handle paste - distribute characters across boxes
      _handlePaste(value, index);
      return;
    }

    if (value.isNotEmpty) {
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

    // Move focus to the last filled box or next empty box
    final lastFilledIndex = (startIndex + digits.length - 1).clamp(0, 5);
    if (lastFilledIndex < 5 && digits.length < 6) {
      _focusNodes[lastFilledIndex + 1].requestFocus();
    } else {
      _focusNodes[lastFilledIndex].unfocus();
    }

    setState(() {
      _checkOtpComplete();
    });
  }

  void _onKeyEvent(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          // If current box is empty and backspace pressed, move to previous box and clear it
          _controllers[index - 1].clear();
          _focusNodes[index - 1].requestFocus();
        } else if (_controllers[index].text.isNotEmpty) {
          // If current box has content, clear it
          _controllers[index].clear();
        }
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
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == widget.userId) {
          await currentUser.linkWithCredential(credential);
        }

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

  void _resendCode() async {
    // Clear existing OTP
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();

    // Restart SMS listener
    await SmsAutoFill().listenForCode();

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
        child: RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: (event) => _onKeyEvent(event, index),
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6), // Allow paste of full OTP
            ],
            onChanged: (value) => _onDigitChanged(value, index),
          ),
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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/widgets/buttons/neopop_button/neopop_button.dart';
import 'package:slideme/auth/gotp.dart';
import 'package:slideme/auth/otp.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GPhoneInputPage extends StatefulWidget {
  final bool isAfterGoogleSignIn; // Flag to check if after Google sign-in
  final String? userId; // User ID from Google sign-in

  const GPhoneInputPage({
    super.key,
    this.isAfterGoogleSignIn = false,
    this.userId,
  });

  @override
  State<GPhoneInputPage> createState() => _GPhoneInputPageState();
}

class _GPhoneInputPageState extends State<GPhoneInputPage>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String _selectedCountryCode = '+91';
  bool _isPhoneNumberValid = false;

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  // Individual content animations - INCREASED DURATION for more noticeable fade
  late AnimationController _contentAnimationController;
  late Animation<double> _backButtonAnimation;
  late Animation<double> _labelAnimation;
  late Animation<double> _phoneFieldAnimation;
  late Animation<double> _sendButtonAnimation;
  late Animation<double> _bottomTextAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // INCREASED DURATION from 1000ms to 1800ms for more noticeable fade
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Extended intervals with slower fade curves
    _backButtonAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _labelAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
    );

    _phoneFieldAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );

    _sendButtonAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
    );

    _bottomTextAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    // Start animation after mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentAnimationController.forward();
    });

    // Listen to phone number changes
    _phoneController.addListener(() {
      final phone = _phoneController.text.trim();
      final isValid = phone.length == 10;
      if (isValid != _isPhoneNumberValid) {
        setState(() {
          _isPhoneNumberValid = isValid;
        });
      }
    });
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _contentAnimationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    HapticFeedback.heavyImpact();
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showSnackBar('Please enter your phone number', isError: true);
      return;
    }

    if (phone.length != 10) {
      _showSnackBar(
        'Please enter a valid 10-digit phone number',
        isError: true,
      );
      return;
    }

    final fullNumber = '$_selectedCountryCode$phone';
    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showSnackBar('Verification failed: ${e.message}', isError: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GOTPPage(
                verificationId: verificationId,
                fullName: '',
                phone: fullNumber,
                isAfterGoogleSignIn: widget.isAfterGoogleSignIn,
                userId: widget.userId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('An error occurred. Please try again.', isError: true);
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

  Widget _buildPhoneField() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final scaleFactor = isSmallScreen ? 0.9 : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12 * scaleFactor),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: Colors.white,
                value: _selectedCountryCode,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 15 * scaleFactor,
                  fontWeight: FontWeight.w500,
                ),
                items: const [
                  DropdownMenuItem(value: '+91', child: Text('+91')),
                  DropdownMenuItem(value: '+1', child: Text('+1')),
                  DropdownMenuItem(value: '+44', child: Text('+44')),
                  DropdownMenuItem(value: '+61', child: Text('+61')),
                  DropdownMenuItem(value: '+81', child: Text('+81')),
                  DropdownMenuItem(value: '+82', child: Text('+82')),
                  DropdownMenuItem(value: '+86', child: Text('+86')),
                  DropdownMenuItem(value: '+971', child: Text('+971')),
                  DropdownMenuItem(value: '+974', child: Text('+974')),
                  DropdownMenuItem(value: '+966', child: Text('+966')),
                  DropdownMenuItem(value: '+92', child: Text('+92')),
                  DropdownMenuItem(value: '+880', child: Text('+880')),
                  DropdownMenuItem(value: '+94', child: Text('+94')),
                  DropdownMenuItem(value: '+60', child: Text('+60')),
                  DropdownMenuItem(value: '+65', child: Text('+65')),
                  DropdownMenuItem(value: '+62', child: Text('+62')),
                  DropdownMenuItem(value: '+63', child: Text('+63')),
                  DropdownMenuItem(value: '+66', child: Text('+66')),
                  DropdownMenuItem(value: '+84', child: Text('+84')),
                  DropdownMenuItem(value: '+27', child: Text('+27')),
                  DropdownMenuItem(value: '+234', child: Text('+234')),
                  DropdownMenuItem(value: '+254', child: Text('+254')),
                  DropdownMenuItem(value: '+49', child: Text('+49')),
                  DropdownMenuItem(value: '+33', child: Text('+33')),
                  DropdownMenuItem(value: '+39', child: Text('+39')),
                  DropdownMenuItem(value: '+34', child: Text('+34')),
                  DropdownMenuItem(value: '+31', child: Text('+31')),
                  DropdownMenuItem(value: '+41', child: Text('+41')),
                  DropdownMenuItem(value: '+46', child: Text('+46')),
                  DropdownMenuItem(value: '+45', child: Text('+45')),
                  DropdownMenuItem(value: '+47', child: Text('+47')),
                  DropdownMenuItem(value: '+48', child: Text('+48')),
                  DropdownMenuItem(value: '+351', child: Text('+351')),
                  DropdownMenuItem(value: '+90', child: Text('+90')),
                  DropdownMenuItem(value: '+7', child: Text('+7')),
                  DropdownMenuItem(value: '+55', child: Text('+55')),
                  DropdownMenuItem(value: '+52', child: Text('+52')),
                  DropdownMenuItem(value: '+54', child: Text('+54')),
                  DropdownMenuItem(value: '+64', child: Text('+64')),
                  DropdownMenuItem(value: '+353', child: Text('+353')),
                  DropdownMenuItem(value: '+32', child: Text('+32')),
                  DropdownMenuItem(value: '+43', child: Text('+43')),
                  DropdownMenuItem(value: '+420', child: Text('+420')),
                  DropdownMenuItem(value: '+358', child: Text('+358')),
                  DropdownMenuItem(value: '+40', child: Text('+40')),
                  DropdownMenuItem(value: '+56', child: Text('+56')),
                  DropdownMenuItem(value: '+20', child: Text('+20')),
                  DropdownMenuItem(value: '+212', child: Text('+212')),
                  DropdownMenuItem(value: '+972', child: Text('+972')),
                  DropdownMenuItem(value: '+886', child: Text('+886')),
                ],
                onChanged: (value) {
                  setState(() => _selectedCountryCode = value!);
                },
              ),
            ),
          ),
          Container(
            width: 1,
            height: 40 * scaleFactor,
            color: Colors.grey[300],
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 15 * scaleFactor,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '9876543210',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 15 * scaleFactor,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16 * scaleFactor,
                  vertical: 16 * scaleFactor,
                ),
              ),
            ),
          ),
        ],
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
                              widthFactor: _isPhoneNumberValid ? 0.25 : 0.15,
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

                  // Mobile Number Label - Animated
                  _buildAnimatedElement(
                    animation: _labelAnimation,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Mobile Number',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18 * scaleFactor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20 * scaleFactor),

                  // Phone Input Field - Animated
                  _buildAnimatedElement(
                    animation: _phoneFieldAnimation,
                    child: _buildPhoneField(),
                  ),

                  SizedBox(height: 30 * scaleFactor),

                  // Send OTP Button - Animated
                  _buildAnimatedElement(
                    animation: _sendButtonAnimation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: _isPhoneNumberValid
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
                        color: _isPhoneNumberValid
                            ? const Color(0xff4A8C51)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          onTap: (_isLoading || !_isPhoneNumberValid)
                              ? null
                              : _sendOTP,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 18 * scaleFactor,
                            ),
                            child: Center(
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20 * scaleFactor,
                                      height: 20 * scaleFactor,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _isPhoneNumberValid
                                                  ? Colors.white
                                                  : Colors.white.withOpacity(
                                                      0.5,
                                                    ),
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "SEND OTP",
                                      style: GoogleFonts.poppins(
                                        color: _isPhoneNumberValid
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

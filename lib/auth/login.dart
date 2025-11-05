import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:neopop/widgets/buttons/neopop_button/neopop_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slideme/auth/authservice.dart';
import 'package:slideme/auth/loginotp.dart';
import 'package:slideme/auth/signup.dart';
import 'package:slideme/screens/homepage.dart';
import 'package:slideme/screens/welcome.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;
  final AuthService authService = AuthService();
  String selectedCountryCode = '+91';

  // List of popular country codes
  final List<Map<String, String>> countryCodes = [
    {'code': '+1', 'country': 'US/CA'},
    {'code': '+44', 'country': 'UK'},
    {'code': '+91', 'country': 'IN'},
    {'code': '+86', 'country': 'CN'},
    {'code': '+81', 'country': 'JP'},
    {'code': '+49', 'country': 'DE'},
    {'code': '+33', 'country': 'FR'},
    {'code': '+39', 'country': 'IT'},
    {'code': '+61', 'country': 'AU'},
    {'code': '+7', 'country': 'RU'},
    {'code': '+55', 'country': 'BR'},
    {'code': '+52', 'country': 'MX'},
    {'code': '+34', 'country': 'ES'},
    {'code': '+82', 'country': 'KR'},
    {'code': '+92', 'country': 'PK'},
    {'code': '+62', 'country': 'ID'},
    {'code': '+63', 'country': 'PH'},
    {'code': '+64', 'country': 'NZ'},
    {'code': '+27', 'country': 'ZA'},
    {'code': '+20', 'country': 'EG'},
    {'code': '+971', 'country': 'AE'},
    {'code': '+966', 'country': 'SA'},
    {'code': '+65', 'country': 'SG'},
    {'code': '+60', 'country': 'MY'},
    {'code': '+66', 'country': 'TH'},
    {'code': '+84', 'country': 'VN'},
  ];

  @override
  void initState() {
    super.initState();
    _clearGoogleSession();
  }

  Future<void> _clearGoogleSession() async {
    final googleSignIn = GoogleSignIn();
    try {
      await googleSignIn.signOut();
      await googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google disconnect error: $e');
    }
  }

  Future<void> _clearSkipLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_skipped_login');
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(
                'Select Country Code',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: countryCodes.length,
                  itemBuilder: (context, index) {
                    final country = countryCodes[index];
                    return ListTile(
                      leading: Text(
                        country['code']!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      title: Text(
                        country['country']!,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      onTap: () {
                        setState(() {
                          selectedCountryCode = country['code']!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Send OTP to Phone Number
  Future<void> sendOTP() async {
    String phoneNumber = phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter your phone number",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Add selected country code if not present
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '$selectedCountryCode$phoneNumber';
    }

    try {
      setState(() => isLoading = true);

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _clearSkipLoginState();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.message ?? "Verification failed",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationPage(
                verificationId: verificationId,
                phoneNumber: phoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Google Sign-In
  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      setState(() => isLoading = true);

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String email = googleUser.email;

      final QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        await GoogleSignIn().signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No account found. Please sign up first.',
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _clearSkipLoginState();

      // Navigate directly to HomePage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      await GoogleSignIn().signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Apple Sign-In
  // Apple Sign-In

  Future<void> signInWithApple() async {
    try {
      setState(() => isLoading = true);

      // Use the centralized AuthService method
      final userCredential = await authService.signInWithApple();

      if (userCredential == null) {
        // User cancelled the sign-in
        setState(() => isLoading = false);
        return;
      }

      // Check if user document exists
      final userDoc = FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user!.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        // New user - should sign up first
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No account found. Please sign up first.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // Clear skip login state and navigate
      await _clearSkipLoginState();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Apple Sign-In failed: ${e.toString()}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50), // Green background
      body: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user != null) {
              return const NamePage();
            }
          }

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // Welcome Text - Left Aligned
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back!Glad",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "to see you, Again!",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Mobile Number Label
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Mobile Number",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Phone Number Input Field with Country Code Selector
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Country Code Selector
                            GestureDetector(
                              onTap: _showCountryCodePicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      selectedCountryCode,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey[700],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Phone Number Input
                            Expanded(
                              child: TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: "9876543210",
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : sendOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            isLoading ? "SENDING..." : "LOGIN",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Or Login with Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.5),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Or Login with",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.5),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Social Login Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google Button
                          Expanded(
                            child: GestureDetector(
                              onTap: isLoading ? null : signInWithGoogle,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.g_mobiledata,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Apple Button
                          Expanded(
                            child: GestureDetector(
                              onTap: isLoading ? null : signInWithApple,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.apple,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Sign Up Link - Centered without underline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SignUpPage(onTap: () {}),
                                ),
                              );
                            },
                            child: Text(
                              'Register Now',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

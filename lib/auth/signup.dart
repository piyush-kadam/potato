import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:neopop/widgets/buttons/neopop_button/neopop_button.dart';
import 'package:slideme/auth/authservice.dart';
import 'package:slideme/auth/gphone.dart';
import 'package:slideme/auth/login.dart';
import 'package:slideme/auth/welcome.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUpPage extends StatefulWidget {
  final VoidCallback onTap;

  const SignUpPage({super.key, required this.onTap});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool isLoading = false;
  final AuthService _authService = AuthService();

  // Add GoogleSignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _clearGoogleSession();
  }

  // This function clears the last used (cached) Google account/session
  Future<void> _clearGoogleSession() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
      // Optionally handle catch
    } catch (e) {
      print("Error clearing Google Sign-In cache: $e");
    }
  }

  void _signInWithGoogle() async {
    setState(() => isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('Users')
            .doc(userCredential.user!.uid);
        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'authMethod': 'google',
            'phoneVerified': false,
          });
        }
        // REMOVED: Manual navigation - let AuthGate handle it
      }
    } catch (e) {
      _showError("Google sign-in failed: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _signInWithApple() async {
    setState(() => isLoading = true);

    try {
      final userCredential = await _authService.signInWithApple();

      if (userCredential != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('Users')
            .doc(userCredential.user!.uid);
        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'authMethod': 'apple',
            'phoneVerified': false,
          });
        }
        // AuthGate handles navigation
      }
    } catch (e) {
      _showError("Apple sign-in failed: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff5FB567),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            const SizedBox(height: 80),

            Positioned(
              left: 0,
              top: 20,
              child: Lottie.asset(
                'assets/animations/Scene.json',
                height: size.height * 0.8,
                width: size.width,
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 8,
                  ),
                  child: NeoPopButton(
                    depth: 6,
                    color: Colors.transparent,
                    animationDuration: const Duration(milliseconds: 400),
                    onTapUp: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WelcomePage()),
                      );
                    },
                    onTapDown: () {},
                    child: Container(
                      width: 250,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xff4A8C51),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Center(
                        child: Text(
                          'Get  Started',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: NeoPopButton(
                    depth: 6,
                    color: Colors.transparent,
                    animationDuration: const Duration(milliseconds: 400),
                    onTapUp: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(onTap: () {}),
                        ),
                      );
                    },
                    onTapDown: () {},
                    child: Container(
                      width: 250,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Center(
                        child: Text(
                          'I Already Have An Account',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff4A8C51),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'or continue with',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 15),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: isLoading ? null : _signInWithGoogle,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: Colors.white, width: 2),
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
                      Expanded(
                        child: GestureDetector(
                          onTap: isLoading ? null : _signInWithApple,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: Colors.white, width: 2),
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
                ),

                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slideme/auth/age.dart';

class NamePage extends StatefulWidget {
  const NamePage({super.key});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;
  bool _isNameFilled = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late AnimationController
  _progressController; // Added for animated loading bar

  late Animation<double> _backButtonFade;
  late Animation<double> _mascotFade;
  late Animation<double> _titleFade;
  late Animation<double> _inputFade;
  late Animation<double> _buttonFade;
  late Animation<double> _floatAnimation;
  late Animation<double> _progressAnimation; // For the loading bar

  bool _fadeComplete = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_checkNameFilled);

    // Fade animation (longer, e.g. 2600ms)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2600), // was 1800
      vsync: this,
    );

    // Mascot float
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Progress bar (loading bar) animation: animates from 0 to 0.33
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0.11).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Staggered fade animations
    _backButtonFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _mascotFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.1, 0.45, curve: Curves.easeOut),
    );
    _titleFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    );
    _inputFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
    );
    _buttonFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );

    // Listen for fade completion
    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _fadeComplete = true;
        });
      }
    });

    // Start fade animation & mascot float & progress bar animation as soon as page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _floatController.repeat(reverse: true); // Start mascot float immediately
      _progressController.forward(); // Start loading bar animation
    });
  }

  void _checkNameFilled() {
    final isFilled = _nameController.text.trim().isNotEmpty;
    if (isFilled != _isNameFilled) {
      setState(() {
        _isNameFilled = isFilled;
      });
    }
  }

  String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(
      6,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  Future<void> _saveName() async {
    HapticFeedback.mediumImpact();
    final user = FirebaseAuth.instance.currentUser;
    final name = _nameController.text.trim();

    if (user == null) {
      _showSnackBar("User not logged in");
      return;
    }

    if (name.isEmpty) {
      _showSnackBar("Please enter your name");
      return;
    }

    setState(() => _isSaving = true);

    try {
      String inviteCode = generateInviteCode();

      bool isUnique = false;
      while (!isUnique) {
        final query = await FirebaseFirestore.instance
            .collection('Users')
            .where('inviteCode', isEqualTo: inviteCode)
            .get();

        if (query.docs.isEmpty) {
          isUnique = true;
        } else {
          inviteCode = generateInviteCode();
        }
      }

      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'username': name,
        'inviteCode': inviteCode,
        'linkedUsers': [],
      }, SetOptions(merge: true));

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AgePage(userName: name)),
      );
    } catch (e) {
      _showSnackBar("Error: $e");
    }

    setState(() => _isSaving = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xff4A8C51),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFadeElement({
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xff5FB567),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bgg.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xff5FB567)),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Back button with animated progress bar - Faded
                        _buildFadeElement(
                          animation: _backButtonFade,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.3,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _progressAnimation,
                                    builder: (context, child) {
                                      return FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _progressAnimation.value,
                                        child: child,
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 130),

                        // Mascot and speech bubble - Faded with float only on mascot
                        _buildFadeElement(
                          animation: _mascotFade,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Only mascot floats
                              AnimatedBuilder(
                                animation: _floatController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _floatAnimation.value),
                                    child: child,
                                  );
                                },
                                child: Image.asset(
                                  'assets/images/mascot2.png',
                                  height: 100,
                                  width: 100,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Let's start with the basics!",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "What should I call you?",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xff4A8C51),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Title - Faded
                        _buildFadeElement(
                          animation: _titleFade,
                          child: Text(
                            "What's your name?",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Input Field - Faded
                        _buildFadeElement(
                          animation: _inputFade,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _nameController,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter your name",
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w400,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Continue Button - Faded
                        _buildFadeElement(
                          animation: _buttonFade,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: _isNameFilled
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
                                color: _isNameFilled
                                    ? const Color(0xff4A8C51)
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                                child: InkWell(
                                  onTap: (_isSaving || !_isNameFilled)
                                      ? null
                                      : _saveName,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    child: Center(
                                      child: _isSaving
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: _isNameFilled
                                                    ? Colors.white
                                                    : Colors.white.withOpacity(
                                                        0.5,
                                                      ),
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              "CONTINUE",
                                              style: GoogleFonts.poppins(
                                                color: _isNameFilled
                                                    ? Colors.white
                                                    : Colors.white.withOpacity(
                                                        0.5,
                                                      ),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

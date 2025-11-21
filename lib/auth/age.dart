import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slideme/auth/country.dart';

class AgePage extends StatefulWidget {
  final String userName;

  const AgePage({super.key, required this.userName});

  @override
  State<AgePage> createState() => _AgePageState();
}

class _AgePageState extends State<AgePage> with TickerProviderStateMixin {
  final FixedExtentScrollController _scrollController =
      FixedExtentScrollController(initialItem: 18);
  int _selectedAge = 18;
  bool _isSaving = false;
  bool _isAgeSelected = true;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late AnimationController _progressController; // NEW

  late Animation<double> _backButtonFade;
  late Animation<double> _mascotFade;
  late Animation<double> _titleFade;
  late Animation<double> _pickerFade;
  late Animation<double> _buttonFade;
  late Animation<double> _floatAnimation;
  late Animation<double> _progressAnimation; // NEW

  bool _fadeComplete = false;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Mascot float (will start immediately)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Progress bar animation (0 to 66%)
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0.22).animate(
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
    _pickerFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
    );
    _buttonFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );

    // Fade completion (no longer starts float here)
    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _fadeComplete = true;
        });
      }
    });

    // Start all animations when page appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _floatController.repeat(reverse: true); // Mascot floats immediately!
      _progressController.forward(); // Loading bar animates!
    });
  }

  Future<void> _saveAge() async {
    HapticFeedback.heavyImpact();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar("User not logged in");
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'age': _selectedAge,
      }, SetOptions(merge: true));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CountryPage(userName: widget.userName),
        ),
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
                            backgroundColor: Colors.white.withOpacity(0.3),
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

                  const SizedBox(height: 60),

                  // Mascot and speech bubble - Only mascot floats, float starts immediately
                  _buildFadeElement(
                    animation: _mascotFade,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                        // Speech bubble (static)
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Nice to meet you, ${widget.userName}!",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "How old are you?",
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

                  // Question text - Faded
                  _buildFadeElement(
                    animation: _titleFade,
                    child: Text(
                      "What's your age?",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Age picker - Faded
                  _buildFadeElement(
                    animation: _pickerFade,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Glass effect overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                            // Center highlight
                            Center(
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            // Picker
                            ListWheelScrollView.useDelegate(
                              controller: _scrollController,
                              itemExtent: 60,
                              perspective: 0.005,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedAge = index;
                                  _isAgeSelected = true;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  final isSelected = index == _selectedAge;
                                  return Center(
                                    child: Text(
                                      '$index',
                                      style: GoogleFonts.poppins(
                                        fontSize: isSelected ? 40 : 32,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  );
                                },
                                childCount: 100,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Continue button - Faded
                  _buildFadeElement(
                    animation: _buttonFade,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: _isAgeSelected
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
                          color: _isAgeSelected
                              ? const Color(0xff4A8C51)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            onTap: (_isSaving || !_isAgeSelected)
                                ? null
                                : _saveAge,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: _isSaving
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: _isAgeSelected
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.5),
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        "CONTINUE",
                                        style: GoogleFonts.poppins(
                                          color: _isAgeSelected
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.5),
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    _progressController.dispose(); // NEW - always dispose!
    _scrollController.dispose();
    super.dispose();
  }
}

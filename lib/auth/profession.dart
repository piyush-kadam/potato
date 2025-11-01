import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slideme/auth/completion.dart';
import 'package:slideme/auth/spamount.dart';

class ProfessionPage extends StatefulWidget {
  const ProfessionPage({super.key});

  @override
  State<ProfessionPage> createState() => _ProfessionPageState();
}

class _ProfessionPageState extends State<ProfessionPage>
    with TickerProviderStateMixin {
  String? _selectedProfession;
  bool _isSaving = false;

  late AnimationController _cardAnimationController;
  late List<Animation<double>> _cardAnimations;

  // Progress and mascot float
  late AnimationController _progressController;
  late AnimationController _floatController;
  late Animation<double> _progressAnimation;
  late Animation<double> _floatAnimation;

  // Much improved emoji animation
  late AnimationController _emojiBounceController;
  int? _bouncingIndex;

  final List<Map<String, dynamic>> professions = [
    {'title': 'Student', 'subtitle': 'Learning & Growing', 'emoji': '🎓'},
    {'title': 'Professional', 'subtitle': 'Career Focused', 'emoji': '💼'},
    {'title': 'Entrepreneur', 'subtitle': 'Building Dreams', 'emoji': '🚀'},
    {'title': 'Freelancer', 'subtitle': 'Independent Work', 'emoji': '💻'},
    {'title': 'Homemaker', 'subtitle': 'Family First', 'emoji': '🏡'},
    {'title': 'Other', 'subtitle': 'Something Unique', 'emoji': '✨'},
  ];

  @override
  void initState() {
    super.initState();

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardAnimations = List.generate(professions.length, (index) {
      final start = index * 0.1;
      final end = start + 0.5;
      return CurvedAnimation(
        parent: _cardAnimationController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      );
    });

    // Loading bar
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0.77).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Mascot float
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Enhanced bounce+twist emoji animation
    _emojiBounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cardAnimationController.forward();
      _progressController.forward();
      _floatController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _progressController.dispose();
    _floatController.dispose();
    _emojiBounceController.dispose();
    super.dispose();
  }

  Future<void> _saveProfession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("User not logged in");
      return;
    }
    if (_selectedProfession == null) {
      _showSnackBar("Please select a profession");
      return;
    }
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'profession': _selectedProfession,
      }, SetOptions(merge: true));

      _showSnackBar("Profession saved successfully!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SpendAmountPage()),
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

  Widget _buildMascotFloat() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Image.asset('assets/images/mascot2.png', height: 98, width: 98),
    );
  }

  Widget _buildAnimatedEmoji(int index, String emoji, bool isSelected) {
    if (isSelected) {
      return AnimatedBuilder(
        animation: _emojiBounceController,
        builder: (context, child) {
          final t = _emojiBounceController.value;
          // Compose a springy up, then spin, shrink, and fall effect
          final double height = -28 * sin(pi * t); // up, then down
          final double scale = 1.0 - 0.18 * sin(pi * t);
          final double rotation = 0.35 * sin(2.8 * pi * t); // quick twist
          return Transform.translate(
            offset: Offset(0, height),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: Text(emoji, style: const TextStyle(fontSize: 36)),
      );
    } else {
      return Text(emoji, style: const TextStyle(fontSize: 34));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfessionSelected = _selectedProfession != null;

    return Scaffold(
      backgroundColor: const Color(0xff5FB567),
      body: Stack(
        children: [
          // Background Image
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),

                  // Top bar with animated progress bar
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
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

                  const SizedBox(height: 22),

                  // Mascot floating
                  const SizedBox(height: 13),

                  // Title and subtitle
                  Center(
                    child: Text(
                      "What do you do?",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      "Help us personalize your experience",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),

                  const SizedBox(height: 23),

                  // Profession grid, now overflow-safe!
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.12,
                      padding: EdgeInsets.zero,
                      children: List.generate(professions.length, (index) {
                        final profession = professions[index];
                        final isSelected =
                            _selectedProfession == profession['title'];

                        return ScaleTransition(
                          scale: _cardAnimations[index],
                          child: FadeTransition(
                            opacity: _cardAnimations[index],
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedProfession = profession['title'];
                                  _bouncingIndex = index;
                                });
                                _emojiBounceController.forward(from: 0);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: isSelected
                                      ? Border.all(
                                          color: const Color(0xff4A8C51),
                                          width: 2,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildAnimatedEmoji(
                                            index,
                                            profession['emoji'],
                                            isSelected,
                                          ),
                                          const SizedBox(height: 11),
                                          Text(
                                            profession['title'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            profession['subtitle'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: Color(0xff4A8C51),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Continue button with dynamic state
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18, top: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: isProfessionSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xff3D7043,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [],
                      ),
                      child: Material(
                        color: isProfessionSelected
                            ? const Color(0xff4A8C51)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          onTap: (_isSaving || !isProfessionSelected)
                              ? null
                              : _saveProfession,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: _isSaving
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: isProfessionSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.5),
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      "CONTINUE",
                                      style: GoogleFonts.poppins(
                                        color: isProfessionSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.5),
                                        fontWeight: FontWeight.w700,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

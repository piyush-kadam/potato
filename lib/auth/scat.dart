import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slideme/auth/completion.dart';

class SpendCategoriesPage extends StatefulWidget {
  const SpendCategoriesPage({super.key});

  @override
  State<SpendCategoriesPage> createState() => _SpendCategoriesPageState();
}

class _SpendCategoriesPageState extends State<SpendCategoriesPage>
    with TickerProviderStateMixin {
  List<String> _selectedCategories = [];
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Fade animation for entire page
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // For ticking animation
  late AnimationController _tickAnimationController;
  late Animation<double> _tickScaleAnimation;
  late Animation<double> _tickOpacityAnimation;

  final List<Map<String, String>> categories = [
    {'name': 'Food', 'emoji': '🍕'},
    {'name': 'Shopping', 'emoji': '🛍️'},
    {'name': 'Transport', 'emoji': '🚗'},
    {'name': 'Entertainment', 'emoji': '🎬'},
    {'name': 'Bills', 'emoji': '💡'},
    {'name': 'Other', 'emoji': '✨'},
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0.75).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _tickAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tickScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _tickAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
    _tickOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tickAnimationController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    _tickAnimationController.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
        _tickAnimationController.forward(from: 0.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xff5FB567);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bgg.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: bgColor),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Top bar with back button and animated progress bar
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
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

                    const SizedBox(height: 30),

                    // Title and subtitle
                    Text(
                      "What do you spend on?",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Select categories you use (tap multiple)",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Categories grid wrapped in Expanded to prevent overflow
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 1,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: categories.map((category) {
                          bool selected = _selectedCategories.contains(
                            category['name'],
                          );

                          return GestureDetector(
                            onTap: () => _toggleCategory(category['name']!),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xff4A8C51)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          category['emoji']!,
                                          style: const TextStyle(fontSize: 38),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          category['name']!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Animated tick icon top right when selected
                                  Positioned(
                                    top: -2,
                                    right: 0,
                                    child: selected
                                        ? FadeTransition(
                                            opacity: _tickOpacityAnimation,
                                            child: ScaleTransition(
                                              scale: _tickScaleAnimation,
                                              child: Container(
                                                width: 26,
                                                height: 26,
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
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Select at least one category text
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Center(
                        child: Text(
                          "Select at least one category",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),

                    // Continue button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: GestureDetector(
                        onTap: _selectedCategories.isNotEmpty
                            ? () {
                                HapticFeedback.mediumImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CompletionPage(),
                                  ),
                                );
                              }
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: _selectedCategories.isNotEmpty
                                ? const Color(0xff4A8C51)
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: _selectedCategories.isNotEmpty
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xff2E5D33,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              "CONTINUE",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _selectedCategories.isNotEmpty
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                letterSpacing: 1,
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slideme/auth/profession.dart';

class CountryPage extends StatefulWidget {
  final String userName;

  const CountryPage({super.key, required this.userName});

  @override
  State<CountryPage> createState() => _CountryPageState();
}

class _CountryPageState extends State<CountryPage>
    with TickerProviderStateMixin {
  String? _selectedCountry;
  bool _isSaving = false;

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

  final List<Map<String, String>> countries = [
    {'name': 'India', 'flag': '🇮🇳'},
    {'name': 'United States', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'name': 'Canada', 'flag': '🇨🇦'},
    {'name': 'Australia', 'flag': '🇦🇺'},
    {'name': 'Germany', 'flag': '🇩🇪'},
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'Japan', 'flag': '🇯🇵'},
    {'name': 'China', 'flag': '🇨🇳'},
    {'name': 'Brazil', 'flag': '🇧🇷'},
    {'name': 'Mexico', 'flag': '🇲🇽'},
    {'name': 'Spain', 'flag': '🇪🇸'},
    {'name': 'Italy', 'flag': '🇮🇹'},
    {'name': 'South Korea', 'flag': '🇰🇷'},
    {'name': 'Singapore', 'flag': '🇸🇬'},
    {'name': 'Netherlands', 'flag': '🇳🇱'},
    {'name': 'Sweden', 'flag': '🇸🇪'},
    {'name': 'Norway', 'flag': '🇳🇴'},
    {'name': 'Denmark', 'flag': '🇩🇰'},
    {'name': 'Switzerland', 'flag': '🇨🇭'},
    {'name': 'Russia', 'flag': '🇷🇺'},
    {'name': 'South Africa', 'flag': '🇿🇦'},
    {'name': 'New Zealand', 'flag': '🇳🇿'},
    {'name': 'Ireland', 'flag': '🇮🇪'},
    {'name': 'United Arab Emirates', 'flag': '🇦🇪'},
    {'name': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'name': 'Turkey', 'flag': '🇹🇷'},
    {'name': 'Argentina', 'flag': '🇦🇷'},
    {'name': 'Chile', 'flag': '🇨🇱'},
    {'name': 'Indonesia', 'flag': '🇮🇩'},
    {'name': 'Thailand', 'flag': '🇹🇭'},
    {'name': 'Philippines', 'flag': '🇵🇭'},
    {'name': 'Vietnam', 'flag': '🇻🇳'},
    {'name': 'Malaysia', 'flag': '🇲🇾'},
    {'name': 'Pakistan', 'flag': '🇵🇰'},
    {'name': 'Bangladesh', 'flag': '🇧🇩'},
    {'name': 'Nepal', 'flag': '🇳🇵'},
    {'name': 'Sri Lanka', 'flag': '🇱🇰'},
    {'name': 'Nigeria', 'flag': '🇳🇬'},
    {'name': 'Kenya', 'flag': '🇰🇪'},
    {'name': 'Egypt', 'flag': '🇪🇬'},
    {'name': 'Israel', 'flag': '🇮🇱'},
    {'name': 'Portugal', 'flag': '🇵🇹'},
    {'name': 'Poland', 'flag': '🇵🇱'},
    {'name': 'Finland', 'flag': '🇫🇮'},
    {'name': 'Greece', 'flag': '🇬🇷'},
    {'name': 'Austria', 'flag': '🇦🇹'},
    {'name': 'Belgium', 'flag': '🇧🇪'},
    {'name': 'Czech Republic', 'flag': '🇨🇿'},
    {'name': 'Hungary', 'flag': '🇭🇺'},
    {'name': 'Romania', 'flag': '🇷🇴'},
    {'name': 'Colombia', 'flag': '🇨🇴'},
    {'name': 'Peru', 'flag': '🇵🇪'},
    {'name': 'Ukraine', 'flag': '🇺🇦'},
    {'name': 'Morocco', 'flag': '🇲🇦'},
    {'name': 'Qatar', 'flag': '🇶🇦'},
    {'name': 'Kuwait', 'flag': '🇰🇼'},
    {'name': 'Oman', 'flag': '🇴🇲'},
  ];

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Mascot float (starts immediately)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Progress bar animation (0 to 100%)
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0.44).animate(
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

  Future<void> _saveCountry() async {
    HapticFeedback.heavyImpact();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar("User not logged in");
      return;
    }

    if (_selectedCountry == null) {
      _showSnackBar("Please select a country");
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'country': _selectedCountry,
      }, SetOptions(merge: true));

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfessionPage()),
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

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Country',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    return ListTile(
                      leading: Text(
                        country['flag']!,
                        style: const TextStyle(fontSize: 32),
                      ),
                      title: Text(
                        country['name']!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCountry = country['name'];
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
    bool isCountrySelected = _selectedCountry != null;

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

                  // Back button + ANIMATED progress bar
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

                  // Mascot and speech bubble - mascot always floats!
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
                                  "Hi ${widget.userName}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Which Country you from?",
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
                      "Select Country Name",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Country selection card - Faded
                  _buildFadeElement(
                    animation: _pickerFade,
                    child: GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                        child: Row(
                          children: [
                            // Flag icon
                            Text(
                              _selectedCountry != null
                                  ? countries.firstWhere(
                                      (c) => c['name'] == _selectedCountry,
                                    )['flag']!
                                  : '🌍',
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            // Country name
                            Expanded(
                              child: Text(
                                _selectedCountry ?? 'Select a country',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: _selectedCountry != null
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: _selectedCountry != null
                                      ? Colors.black87
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            // Check icon only if a country is selected
                            if (_selectedCountry != null)
                              Container(
                                padding: const EdgeInsets.all(6),
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
                          boxShadow: isCountrySelected
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
                          color: isCountrySelected
                              ? const Color(0xff4A8C51)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            onTap: (_isSaving || !isCountrySelected)
                                ? null
                                : _saveCountry,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: _isSaving
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: isCountrySelected
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.5),
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        "CONTINUE",
                                        style: GoogleFonts.poppins(
                                          color: isCountrySelected
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
    _progressController.dispose(); // NEW!
    super.dispose();
  }
}

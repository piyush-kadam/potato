import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:slideme/screens/category.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage>
    with SingleTickerProviderStateMixin {
  double _budget = 25000;
  final TextEditingController _budgetController = TextEditingController();
  bool _manualEntry = false;
  bool _isSaving = false;
  String? _username;
  String _currencySymbol = "₹";

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  int get _dailyBudget => (_budget / 30).round();

  // Currency mapping based on country names
  final Map<String, String> _currencyMap = {
    'India': '₹',
    'United States': '\$',
    'United Kingdom': '£',
    'Canada': 'C\$',
    'Australia': 'A\$',
    'Germany': '€',
    'France': '€',
    'Japan': '¥',
    'China': '¥',
    'Brazil': 'R\$',
    'Mexico': 'MX\$',
    'Spain': '€',
    'Italy': '€',
    'South Korea': '₩',
    'Singapore': 'S\$',
    'Netherlands': '€',
    'Sweden': 'kr',
    'Norway': 'kr',
    'Denmark': 'kr',
    'Switzerland': 'CHF',
    'Russia': '₽',
    'South Africa': 'R',
    'New Zealand': 'NZ\$',
    'Ireland': '€',
    'United Arab Emirates': 'د.إ',
    'Saudi Arabia': '﷼',
    'Turkey': '₺',
    'Argentina': 'AR\$',
    'Chile': 'CL\$',
    'Indonesia': 'Rp',
    'Thailand': '฿',
    'Philippines': '₱',
    'Vietnam': '₫',
    'Malaysia': 'RM',
    'Pakistan': '₨',
    'Bangladesh': '৳',
    'Nepal': '₨',
    'Sri Lanka': '₨',
    'Nigeria': '₦',
    'Kenya': 'KSh',
    'Egypt': 'E£',
    'Israel': '₪',
    'Portugal': '€',
    'Poland': 'zł',
    'Finland': '€',
    'Greece': '€',
    'Austria': '€',
    'Belgium': '€',
    'Czech Republic': 'Kč',
    'Hungary': 'Ft',
    'Romania': 'lei',
    'Colombia': 'COL\$',
    'Peru': 'S/',
    'Ukraine': '₴',
    'Morocco': 'د.م.',
    'Qatar': '﷼',
    'Kuwait': 'د.ك',
    'Oman': '﷼',
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    // Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Start animation after a small delay
    Future.delayed(const Duration(milliseconds: 200), () {
      _controller.forward();
    });
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _username = data["username"];
        // Fetch country and set currency symbol
        final country = data["country"] as String?;
        if (country != null && _currencyMap.containsKey(country)) {
          _currencySymbol = _currencyMap[country]!;
        }
      });
    }
  }

  Future<void> _saveBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection("Users").doc(user.uid).set({
        "monthlyBudget": _budget.round(),
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CategoryBudgetPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _isSaving = false);
  }

  void _enableManualEntry() {
    setState(() {
      _manualEntry = true;
      _budgetController.text = _budget.round().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _username == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff4CAF50)),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/bg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),

                          // Replace emoji with Lottie animation
                          SizedBox(
                            height: 200,
                            width: 250,
                            child: Lottie.asset('assets/animations/money.json'),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Hi $_username!",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Set your monthly budget",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Budget Display / Manual Entry
                          GestureDetector(
                            onTap: _enableManualEntry,
                            child: Column(
                              children: [
                                _manualEntry
                                    ? TextField(
                                        controller: _budgetController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        autofocus: true,
                                        style: GoogleFonts.poppins(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xff4CAF50),
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          prefix: Text(
                                            _currencySymbol,
                                            style: GoogleFonts.poppins(
                                              fontSize: 48,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xff4CAF50),
                                            ),
                                          ),
                                        ),
                                        onSubmitted: (value) {
                                          if (value.isNotEmpty) {
                                            setState(() {
                                              _budget =
                                                  double.tryParse(value) ??
                                                  _budget;
                                              _manualEntry = false;
                                            });
                                          }
                                        },
                                      )
                                    : Text(
                                        "$_currencySymbol${_budget.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xff4CAF50),
                                        ),
                                      ),
                                const SizedBox(height: 8),
                                Text(
                                  "$_currencySymbol$_dailyBudget per day",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xff4CAF50),
                              inactiveTrackColor: Colors.grey[300],
                              thumbColor: Colors.white,
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                              ),
                              overlayColor: const Color(
                                0xff4CAF50,
                              ).withOpacity(0.15),
                            ),
                            child: Slider(
                              min: 5000,
                              max: 200000,
                              divisions: 195,
                              value: _budget,
                              onChanged: (value) {
                                setState(() {
                                  _manualEntry = false;
                                  _budget = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 30),

                          GestureDetector(
                            onTap: _isSaving ? null : _saveBudget,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: const Color(0xff4CAF50),
                              ),
                              child: Center(
                                child: _isSaving
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      )
                                    : Text(
                                        "CONTINUE",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _budgetController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slideme/auth/subscription.dart';

import 'package:slideme/screens/expensewrap.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class ExpenseCategoryPage extends StatefulWidget {
  const ExpenseCategoryPage({super.key});

  @override
  State<ExpenseCategoryPage> createState() => _ExpenseCategoryPageState();
}

class _ExpenseCategoryPageState extends State<ExpenseCategoryPage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> availableCategories = [
    {'emoji': '🍔', 'name': 'Food'},
    {'emoji': '🛍️', 'name': 'Shopping'},
    {'emoji': '✈️', 'name': 'Travel'},
    {'emoji': '🎬', 'name': 'Entertainment'},
    {'emoji': '💰', 'name': 'Savings'},
  ];

  Set<String> selectedCategories = {};
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check if user is pro
  Future<bool> _checkProStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(
            'Monthly Pro Access',
          ) ||
          customerInfo.entitlements.active.containsKey('Yearly Pro Access') ||
          customerInfo.entitlements.active.containsKey('Lifetime Pro Access');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 44),

                    // Title
                    Text(
                      "Choose Expense Categories",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Select exactly 5 categories to track",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selectedCategories.length == 5
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${selectedCategories.length}/5 selected",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selectedCategories.length == 5
                              ? Colors.green[800]
                              : Colors.orange[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Grid
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.0,
                        children: [
                          ...availableCategories.map((category) {
                            final key =
                                "${category['emoji']} ${category['name']}";
                            final isSelected = selectedCategories.contains(key);
                            return _buildCategoryCard(
                              category['emoji']!,
                              category['name']!,
                              isSelected,
                              key,
                            );
                          }).toList(),

                          // Add category card
                          _buildAddCategoryCard(),
                        ],
                      ),
                    ),

                    // Save Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              selectedCategories.length == 5 && !_isSaving
                              ? _saveCategories
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedCategories.length == 5
                                ? Colors.green[600]
                                : Colors.grey[400],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                            shadowColor: Colors.green.withOpacity(0.4),
                            disabledBackgroundColor: Colors.grey[400],
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  selectedCategories.length == 5
                                      ? "SAVE CATEGORIES"
                                      : "SELECT 5 CATEGORIES",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String emoji,
    String name,
    bool isSelected,
    String key,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedCategories.remove(key);
          } else {
            if (selectedCategories.length < 5) {
              selectedCategories.add(key);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "You can only select 5 categories",
                    style: GoogleFonts.poppins(),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.orange[700],
                ),
              );
            }
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.85)
              : Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white.withOpacity(0.7),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 42)),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Add Category Card
  Widget _buildAddCategoryCard() {
    return GestureDetector(
      onTap: () async {
        bool isPro = await _checkProStatus();
        if (isPro) {
          _showAddCategoryDialog();
        } else {
          _showUpgradeToProDialog();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 32, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              "Add",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Upgrade to Pro Dialog
  Future<void> _showUpgradeToProDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Crown icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('👑', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                "Upgrade to Pro",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                "Add custom categories and unlock all premium features with Pro!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Maybe Later",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Go Pro",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add Category Dialog
  Future<void> _showAddCategoryDialog() async {
    final TextEditingController emojiController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Note icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('📝', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 24),

              // Category name field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: nameController,
                  style: GoogleFonts.poppins(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Category name",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Emoji field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: emojiController,
                  style: GoogleFonts.poppins(fontSize: 16),
                  maxLength: 2,
                  decoration: InputDecoration(
                    hintText: "add an emoji",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    counterText: "",
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final emoji = emojiController.text.trim().isEmpty
                            ? "📦"
                            : emojiController.text.trim();
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          setState(() {
                            availableCategories.insert(
                              availableCategories.length,
                              {'emoji': emoji, 'name': name},
                            );
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Category added! Now select it.",
                                style: GoogleFonts.poppins(),
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green[700],
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81C784),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Add",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Save categories to Firestore
  Future<void> _saveCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (selectedCategories.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select exactly 5 categories",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'expenseCategories': selectedCategories.toList(),
        'trackingMode': 'expense',
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ExpensePageWithSlider()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    if (mounted) setState(() => _isSaving = false);
  }
}

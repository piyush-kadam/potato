import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:slideme/auth/subscription.dart';
import 'package:slideme/screens/chatbot.dart';
import 'package:slideme/screens/expensecategory.dart';
import 'package:slideme/screens/expensewrap.dart';
import 'package:slideme/screens/monthlywrap.dart';
import 'package:slideme/screens/settings.dart';

import 'package:slideme/widgets/addcat.dart';
import 'package:slideme/widgets/popup.dart';

class HomePage extends StatefulWidget {
  final int? currentPage;
  final Function(int)? onPageIndicatorTap;

  const HomePage({super.key, this.currentPage, this.onPageIndicatorTap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDarkMode = false;
  bool _isNavigating = false;
  bool _isProUser = false;
  bool _isCheckingEntitlement = true;
  String _currencySymbol = '₹';

  // Define the desired category order
  final List<String> _categoryOrder = [
    'food',
    'shopping',
    'entertainment',
    'travel',
    'savings',
  ];

  @override
  void initState() {
    super.initState();
    _checkProStatus();
    _fetchCurrencySymbol();
    _checkAndShowMonthlyWrap();
  }

  // 🧠 Function to check if today is first of the month and db has previousMonthAnalytics
  Future<void> _checkAndShowMonthlyWrap() async {
    try {
      // Example: get current user ID
      final uid = FirebaseAuth
          .instance
          .currentUser!
          .uid; // Replace or use FirebaseAuth.instance.currentUser!.uid
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();

      // ✅ Check if today is the 1st
      final now = DateTime.now();
      final isFirstOfMonth = now.day == 1;

      // ✅ Check if field exists
      final hasPreviousAnalytics =
          userDoc.data()?['previousMonthAnalytics'] != null;

      if (isFirstOfMonth && hasPreviousAnalytics && mounted) {
        // Navigate to MonthlyWrapScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MonthlyWrapScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error checking monthly wrap: $e');
    }
  }

  // Check if user has any pro entitlement
  Future<void> _checkProStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();

      // Check for any of the three pro entitlements
      bool hasMonthlyPro =
          customerInfo.entitlements.all['Monthly Pro Access']?.isActive ??
          false;
      bool hasYearlyPro =
          customerInfo.entitlements.all['Yearly Pro Access']?.isActive ?? false;
      bool hasLifetimePro =
          customerInfo.entitlements.all['Lifetime Pro Access']?.isActive ??
          false;

      setState(() {
        _isProUser = hasMonthlyPro || hasYearlyPro || hasLifetimePro;
        _isCheckingEntitlement = false;
      });
    } catch (e) {
      print("Error checking pro status: $e");
      setState(() {
        _isProUser = false;
        _isCheckingEntitlement = false;
      });
    }
  }

  String extractEmoji(String categoryName) {
    final emojiRegex = RegExp(
      r'(?:[\u{1F600}-\u{1F64F}]|'
      r'[\u{1F300}-\u{1F5FF}]|'
      r'[\u{1F680}-\u{1F6FF}]|'
      r'[\u{1F1E0}-\u{1F1FF}]|'
      r'[\u{2600}-\u{26FF}]|'
      r'[\u{2700}-\u{27BF}]|'
      r'[\u{1F900}-\u{1F9FF}]|'
      r'[\u{1FA00}-\u{1FA6F}]|'
      r'[\u{1FA70}-\u{1FAFF}])'
      r'[\u{FE00}-\u{FE0F}\u{E0100}-\u{E01EF}]?',
      unicode: true,
    );
    final match = emojiRegex.firstMatch(categoryName);
    return match?.group(0) ?? '📦';
  }

  String extractCategoryName(String categoryName) {
    final emojiRegex = RegExp(
      r'(?:[\u{1F600}-\u{1F64F}]|'
      r'[\u{1F300}-\u{1F5FF}]|'
      r'[\u{1F680}-\u{1F6FF}]|'
      r'[\u{1F1E0}-\u{1F1FF}]|'
      r'[\u{2600}-\u{26FF}]|'
      r'[\u{2700}-\u{27BF}]|'
      r'[\u{1F900}-\u{1F9FF}]|'
      r'[\u{1FA00}-\u{1FA6F}]|'
      r'[\u{1FA70}-\u{1FAFF}])'
      r'[\u{FE00}-\u{FE0F}\u{E0100}-\u{E01EF}]?',
      unicode: true,
    );
    return categoryName.replaceAll(emojiRegex, '').trim();
  }

  final Map<String, String> currencyMap = {
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

  Future<void> _fetchCurrencySymbol() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .get();
    final country = userDoc.data()?['country'] as String?;
    setState(() {
      _currencySymbol = currencyMap[country ?? 'India'] ?? '₹';
    });
  }

  // Sort categories based on predefined order
  List<String> _getSortedCategories(Map<String, int> categoryBudgets) {
    List<String> sortedKeys = [];

    // Add categories in the defined order
    for (String orderKey in _categoryOrder) {
      for (String key in categoryBudgets.keys) {
        String cleanName = extractCategoryName(key).toLowerCase();
        if (cleanName.contains(orderKey)) {
          sortedKeys.add(key);
          break;
        }
      }
    }

    // Add any remaining categories that don't match the order
    for (String key in categoryBudgets.keys) {
      if (!sortedKeys.contains(key)) {
        sortedKeys.add(key);
      }
    }

    return sortedKeys;
  }

  Future<void> _navigateToExpenseMode() async {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final docSnapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .get();

      if (!mounted) return;

      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;

        if (data.containsKey('expenseCategories') &&
            data['expenseCategories'] != null &&
            (data['expenseCategories'] as List).isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ExpensePageWithSlider(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ExpenseCategoryPage(),
            ),
          );
        }
      }
    } catch (e) {
      print("Error navigating to expense mode: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  // Handle add category tap - show subscription page if not pro
  void _handleAddCategoryTap(
    int remainingBudget,
    Map<String, int> categoryBudgets,
    String userId,
  ) async {
    if (!_isProUser) {
      // Navigate to subscription page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SubscriptionPage()),
      );
    } else {
      // Show add category dialog for pro users
      var result = await showDialog(
        context: context,
        builder: (_) => AddCategoryPopup(
          remainingBudget: remainingBudget,
          categoryBudgets: categoryBudgets,
        ),
      );
      if (result != null) {
        await FirebaseFirestore.instance.collection("Users").doc(userId).update(
          {"categoryBudgets": result},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;
    final availableHeight = screenHeight - topPadding - bottomPadding;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String username = data["username"] ?? "User";
        int monthlyBudget = (data["monthlyBudget"] ?? 0).toDouble().toInt();
        int remainingBudget = (data["remainingBudget"] ?? monthlyBudget)
            .toDouble()
            .toInt();

        Map<String, int> categoryBudgets = {};
        Map<String, int> originalCategoryBudgets = {};

        if (data["categoryBudgets"] != null) {
          (data["categoryBudgets"] as Map<String, dynamic>).forEach((
            key,
            value,
          ) {
            categoryBudgets[key] = (value is num) ? value.toInt() : 0;
          });
        }

        if (data["originalCategoryBudgets"] != null) {
          (data["originalCategoryBudgets"] as Map<String, dynamic>).forEach((
            key,
            value,
          ) {
            originalCategoryBudgets[key] = (value is num) ? value.toInt() : 0;
          });
        } else {
          originalCategoryBudgets = Map.from(categoryBudgets);
        }

        Map<String, int> categorySpent = {};
        if (data["categorySpent"] != null) {
          (data["categorySpent"] as Map<String, dynamic>).forEach((key, value) {
            categorySpent[key] = (value is num) ? value.toInt() : 0;
          });
        }

        // Get sorted category keys
        List<String> sortedCategoryKeys = _getSortedCategories(categoryBudgets);

        int spent = monthlyBudget - remainingBudget;
        int categoriesCount = categoryBudgets.length;
        double usedPercent = monthlyBudget > 0 ? spent / monthlyBudget : 0;

        final now = DateTime.now();
        final lastDay = DateTime(now.year, now.month + 1, 0);
        int remainingDays = lastDay.difference(now).inDays + 1;

        final topBarHeight = availableHeight * 0.10;
        final daysLeftHeight = availableHeight * 0.10;
        final gridHeight = availableHeight * 0.65;
        final analyticsHeight = availableHeight * 0.17;

        bool needsScrolling = categoryBudgets.length > 5;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFFE3F2FD)),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    /// TOP BAR
                    Container(
                      height: topBarHeight.clamp(60.0, 90.0),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatbotPage(),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/mascot.png',
                                  width: screenWidth * 0.11,
                                  height: screenWidth * 0.11,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                        '🥔',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.08,
                                        ),
                                      ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Hi $username",
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "How's your day going?",
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.028,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.01,
                              vertical: screenHeight * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.03,
                                    vertical: screenHeight * 0.007,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    "Budget",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.028,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                GestureDetector(
                                  onTap: _isNavigating
                                      ? null
                                      : _navigateToExpenseMode,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.03,
                                      vertical: screenHeight * 0.007,
                                    ),
                                    child: _isNavigating
                                        ? SizedBox(
                                            width: screenWidth * 0.115,
                                            height: screenHeight * 0.017,
                                            child: Center(
                                              child: SizedBox(
                                                width: screenWidth * 0.025,
                                                height: screenWidth * 0.025,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.grey[600]!),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            "Expense",
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[600],
                                              fontSize: screenWidth * 0.028,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// DAYS LEFT & PAY NOW
                    Container(
                      height: daysLeftHeight.clamp(70.0, 100.0),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.065,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Days Left",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.028,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "$remainingDays",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.09,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                                vertical: screenHeight * 0.015,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              var result = await showDialog(
                                context: context,
                                builder: (_) => PayNowPopup(
                                  categoryBudgets: categoryBudgets,
                                ),
                              );
                              if (result != null) {
                                String selectedCategory = result['category'];
                                int amount = result['amount'];

                                Map<String, int> updatedSpent = Map.from(
                                  categorySpent,
                                );
                                updatedSpent[selectedCategory] =
                                    (updatedSpent[selectedCategory] ?? 0) +
                                    amount;

                                await FirebaseFirestore.instance
                                    .collection("Users")
                                    .doc(userId)
                                    .update({
                                      "categorySpent": updatedSpent,
                                      "remainingBudget":
                                          remainingBudget - amount,
                                    });
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currencySymbol,
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Text(
                                  "Pay now",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.033,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// CATEGORY GRID - NOW WITH PRO CHECK
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          int itemCount = sortedCategoryKeys.length + 1;
                          int rows = (itemCount / 2).ceil();

                          double itemWidth =
                              (constraints.maxWidth - screenWidth * 0.025) / 2;
                          double itemHeight = itemWidth / 1.2;

                          double calculatedHeight =
                              (rows * itemHeight) +
                              ((rows - 1) * screenHeight * 0.015);

                          // 🔧 HEIGHT CONTROL - Adjust these values to change grid height
                          double minHeight =
                              315.0; // Minimum height (increased from 280)
                          double maxHeight =
                              600.0; // Maximum height (increased from 550 to 650)

                          double maxAvailableHeight = gridHeight.clamp(
                            minHeight,
                            maxHeight,
                          );

                          double finalHeight = needsScrolling
                              ? maxAvailableHeight
                              : calculatedHeight.clamp(
                                  200.0, // Minimum for non-scrolling (can also increase this)
                                  maxAvailableHeight,
                                );

                          return SizedBox(
                            height: finalHeight,
                            child: GridView.builder(
                              physics: needsScrolling
                                  ? const BouncingScrollPhysics()
                                  : const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: screenWidth * 0.025,
                                    mainAxisSpacing: screenHeight * 0.010,
                                    childAspectRatio: 1.2,
                                  ),
                              itemCount: sortedCategoryKeys.length + 1,
                              itemBuilder: (context, index) {
                                if (index < sortedCategoryKeys.length) {
                                  String categoryKey =
                                      sortedCategoryKeys[index];

                                  int originalBudget =
                                      originalCategoryBudgets[categoryKey] ??
                                      categoryBudgets[categoryKey]!;
                                  int spentAmount =
                                      categorySpent[categoryKey] ?? 0;
                                  int remainingInCategory =
                                      originalBudget - spentAmount;
                                  double progress = originalBudget > 0
                                      ? (remainingInCategory / originalBudget)
                                            .clamp(0.0, 1.0)
                                      : 0.0;
                                  if (remainingInCategory < 0) {
                                    remainingInCategory = 0;
                                    progress = 0.0;
                                  }

                                  String emoji = extractEmoji(categoryKey);
                                  String categoryName = extractCategoryName(
                                    categoryKey,
                                  );

                                  Color liquidColor;
                                  if (progress > 0.5) {
                                    liquidColor = const Color(0xFF4CAF50);
                                  } else if (progress > 0.25) {
                                    liquidColor = const Color.fromARGB(
                                      255,
                                      225,
                                      160,
                                      49,
                                    );
                                  } else {
                                    liquidColor = const Color.fromARGB(
                                      255,
                                      249,
                                      24,
                                      12,
                                    );
                                  }

                                  bool isOverspent =
                                      spentAmount > originalBudget;

                                  return GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            CategoryDetailsDrawer(
                                              categoryName: categoryName,
                                              emoji: emoji,
                                              originalBudget: originalBudget,
                                              categoryBudgets: categoryBudgets,
                                              categorySpent: categorySpent,
                                            ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isOverspent
                                              ? const Color(0xFFFF3B30)
                                              : Colors.white.withOpacity(0.3),
                                          width: isOverspent ? 3.0 : 1.5,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Stack(
                                          children: [
                                            TweenAnimationBuilder<double>(
                                              duration: const Duration(
                                                milliseconds: 800,
                                              ),
                                              curve: Curves.easeInOut,
                                              tween: Tween<double>(
                                                begin: progress,
                                                end: progress,
                                              ),
                                              builder: (context, value, child) {
                                                return LiquidLinearProgressIndicator(
                                                  value: value,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(liquidColor),
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  borderColor:
                                                      Colors.transparent,
                                                  borderWidth: 0,
                                                  borderRadius: 24.0,
                                                  direction: Axis.vertical,
                                                  center: Container(),
                                                );
                                              },
                                            ),
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Colors.white.withOpacity(
                                                        0.2,
                                                      ),
                                                      Colors.white.withOpacity(
                                                        0.05,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Center(
                                              child: Text(
                                                emoji,
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.15,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  // Add Category Button
                                  return GestureDetector(
                                    onTap: _isCheckingEntitlement
                                        ? null
                                        : () => _handleAddCategoryTap(
                                            remainingBudget,
                                            categoryBudgets,
                                            userId,
                                          ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: _isProUser
                                              ? Colors.white.withOpacity(0.3)
                                              : const Color(
                                                  0xFFFFD700,
                                                ).withOpacity(0.5),
                                          width: _isProUser ? 1.5 : 2.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: _isProUser
                                                      ? [
                                                          Colors.white
                                                              .withOpacity(0.2),
                                                          Colors.white
                                                              .withOpacity(
                                                                0.05,
                                                              ),
                                                        ]
                                                      : [
                                                          const Color(
                                                            0xFFFFD700,
                                                          ).withOpacity(0.1),
                                                          const Color(
                                                            0xFFFFA500,
                                                          ).withOpacity(0.05),
                                                        ],
                                                ),
                                              ),
                                            ),
                                            Center(
                                              child: _isCheckingEntitlement
                                                  ? SizedBox(
                                                      width: screenWidth * 0.08,
                                                      height:
                                                          screenWidth * 0.08,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(
                                                              Colors.grey[600]!,
                                                            ),
                                                      ),
                                                    )
                                                  : Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          _isProUser
                                                              ? Icons.add
                                                              : Icons.lock,
                                                          size:
                                                              screenWidth * 0.2,
                                                          color: _isProUser
                                                              ? const Color.fromARGB(
                                                                  255,
                                                                  81,
                                                                  75,
                                                                  75,
                                                                )
                                                              : const Color(
                                                                  0xFFFFD700,
                                                                ),
                                                        ),
                                                        if (!_isProUser) ...[
                                                          SizedBox(
                                                            height:
                                                                screenHeight *
                                                                0.005,
                                                          ),
                                                          Text(
                                                            "PRO",
                                                            style: GoogleFonts.poppins(
                                                              fontSize:
                                                                  screenWidth *
                                                                  0.025,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  const Color(
                                                                    0xFFFFD700,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    /// ANALYTICS CONTAINER WITH PAGE INDICATORS
                    Container(
                      margin: EdgeInsets.fromLTRB(
                        screenWidth * 0.04,
                        0,
                        screenWidth * 0.04,
                        screenHeight * 0.015,
                      ),
                      padding: EdgeInsets.all(screenHeight * 0.01),
                      constraints: BoxConstraints(
                        minHeight: analyticsHeight.clamp(100.0, 160.0),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "$_currencySymbol$remainingBudget",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "remaining of $_currencySymbol$monthlyBudget",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.025,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.007),
                              Container(
                                width: double.infinity,
                                height: screenHeight * 0.007,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: usedPercent.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                "${(usedPercent * 100).toStringAsFixed(1)}% used",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.023,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.012),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "$_currencySymbol$spent",
                                        style: GoogleFonts.poppins(
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "spent",
                                        style: GoogleFonts.poppins(
                                          fontSize: screenWidth * 0.023,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "$categoriesCount",
                                        style: GoogleFonts.poppins(
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "categories",
                                        style: GoogleFonts.poppins(
                                          fontSize: screenWidth * 0.023,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SettingsPage(),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.settings,
                                          size: screenWidth * 0.045,
                                          color: Colors.grey[700],
                                        ),
                                        Text(
                                          "settings",
                                          style: GoogleFonts.poppins(
                                            fontSize: screenWidth * 0.023,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:slideme/auth/subscription.dart';
import 'package:slideme/screens/category.dart';
import 'package:slideme/screens/chatbot.dart';
import 'package:slideme/screens/monthly_budget.dart';
import 'package:slideme/screens/settings.dart';
import 'package:slideme/screens/homepage.dart';
import 'package:slideme/screens/wrapper.dart';
import 'package:slideme/services/notification_service.dart';
import 'package:slideme/widgets/expaddcat.dart';
import 'package:slideme/widgets/expensepopup.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  bool isDarkMode = false;
  bool _isNavigating = false;
  bool _isProUser = false;
  bool _isCheckingEntitlement = true;

  // Store previous progress values to animate from current position
  final Map<String, double> _previousProgress = {};

  // Define the desired category order
  final List<String> _categoryOrder = [
    'food',
    'shopping',
    'entertainment',
    'travel',
    'savings',
  ];

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

  @override
  void initState() {
    super.initState();
    _checkProStatus();
    NotificationService.init();
  }

  Future<void> _checkProStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      setState(() {
        _isProUser = customerInfo.entitlements.all['pro']?.isActive ?? false;
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

  String getCurrencySymbol(String? country) {
    if (country == null || country.isEmpty) {
      return '₹'; // Default to rupees
    }
    return currencyMap[country] ?? '₹';
  }

  String extractEmoji(String categoryName) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|'
      r'[\u{1F300}-\u{1F5FF}]|'
      r'[\u{1F680}-\u{1F6FF}]|'
      r'[\u{1F1E0}-\u{1F1FF}]|'
      r'[\u{2600}-\u{26FF}]|'
      r'[\u{2700}-\u{27BF}]',
      unicode: true,
    );
    final match = emojiRegex.firstMatch(categoryName);
    return match?.group(0) ?? '📦';
  }

  String extractCategoryName(String categoryName) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|'
      r'[\u{1F300}-\u{1F5FF}]|'
      r'[\u{1F680}-\u{1F6FF}]|'
      r'[\u{1F1E0}-\u{1F1FF}]|'
      r'[\u{2600}-\u{26FF}]|'
      r'[\u{2700}-\u{27BF}]',
      unicode: true,
    );
    return categoryName.replaceAll(emojiRegex, '').trim();
  }

  Color getCategoryColor(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('food')) return Colors.orange;
    if (name.contains('shopping')) return Colors.pink;
    if (name.contains('travel')) return Colors.blue;
    if (name.contains('entertainment')) return Colors.purple;
    if (name.contains('savings')) return Colors.green;
    if (name.contains('transport')) return Colors.indigo;
    if (name.contains('health')) return Colors.red;
    if (name.contains('education')) return Colors.teal;
    return const Color(0xFF4CAF50);
  }

  // Sort categories based on predefined order
  List<String> _getSortedCategories(List<String> categories) {
    List<String> sortedCategories = [];

    // Add categories in the defined order
    for (String orderKey in _categoryOrder) {
      for (String category in categories) {
        String cleanName = extractCategoryName(category).toLowerCase();
        if (cleanName.contains(orderKey)) {
          sortedCategories.add(category);
          break;
        }
      }
    }

    // Add any remaining categories that don't match the order
    for (String category in categories) {
      if (!sortedCategories.contains(category)) {
        sortedCategories.add(category);
      }
    }

    return sortedCategories;
  }

  Future<void> _navigateToBudgetMode() async {
    HapticFeedback.heavyImpact();
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

        if (!data.containsKey('monthlyBudget') ||
            data['monthlyBudget'] == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BudgetPage()),
          );
          return;
        }

        if (!data.containsKey('categoryBudgets') ||
            data['categoryBudgets'] == null ||
            (data['categoryBudgets'] as Map).isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CategoryBudgetPage()),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPageWithSlider()),
        );
      }
    } catch (e) {
      print("Error navigating to budget mode: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  Future<void> updateWidgetData() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      Map<String, dynamic> categoryBudgets = userDoc['categoryBudgets'] ?? {};
      Map<String, dynamic> categorySpent = userDoc['categorySpent'] ?? {};

      // Convert maps to JSON strings
      String budgetsJson = jsonEncode(categoryBudgets);
      String spentJson = jsonEncode(categorySpent);

      // Save to shared storage
      await HomeWidget.saveWidgetData<String>('categoryBudgets', budgetsJson);
      await HomeWidget.saveWidgetData<String>('categorySpent', spentJson);

      // Update the widget
      await HomeWidget.updateWidget(name: 'HomeWidget', iOSName: 'HomeWidget');
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  void _handleAddCategoryTap() {
    if (_isProUser) {
      // Navigate to add category page
      showDialog(context: context, builder: (_) => AddCategoryDialog());
    } else {
      // Navigate to subscription page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SubscriptionPage()),
      );
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
        String? country = data["country"];
        String currencySymbol = getCurrencySymbol(country);

        List<String> categories = [];
        if (data["expenseCategories"] != null) {
          categories = List<String>.from(data["expenseCategories"]);
        }

        // Sort categories based on predefined order
        List<String> sortedCategories = _getSortedCategories(categories);

        Map<String, int> categorySpent = {};
        if (data["categorySpent"] != null) {
          (data["categorySpent"] as Map<String, dynamic>).forEach((key, value) {
            categorySpent[key] = (value is num) ? value.toInt() : 0;
          });
        }

        int totalSpent = categorySpent.values.fold(
          0,
          (sum, value) => sum + value,
        );

        final now = DateTime.now();
        final lastDay = DateTime(now.year, now.month + 1, 0);
        int remainingDays = lastDay.difference(now).inDays + 1;

        // Calculate responsive heights with better scaling
        final topBarHeight = (availableHeight * 0.09).clamp(55.0, 85.0);
        final daysLeftHeight = (availableHeight * 0.11).clamp(65.0, 100.0);
        final gridHeight = (availableHeight * 0.56).clamp(250.0, 420.0);
        final analyticsHeight = (availableHeight * 0.16).clamp(95.0, 150.0);

        // Calculate if scrolling is needed
        bool needsScrolling = sortedCategories.length >= 5;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xAAFFFFFF),
                        Color(0xAEE7D17A),
                        Color(0xAEEFCF4E),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: Image.asset(
                  'assets/images/bgg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFFE3F2FD)),
                ),
              ),

              // Main Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Column(
                    children: [
                      /// TOP BAR
                      Container(
                        height: topBarHeight,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChatbotPage(),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/mascot.png',
                                    width: screenWidth * 0.11,
                                    height: screenWidth * 0.11,
                                    errorBuilder:
                                        (context, error, stackTrace) => Text(
                                          '🥔',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.08,
                                          ),
                                        ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Hi $username",
                                        style: GoogleFonts.poppins(
                                          fontSize: (screenWidth * 0.04).clamp(
                                            14.0,
                                            18.0,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "How's your day going?",
                                        style: GoogleFonts.poppins(
                                          fontSize: (screenWidth * 0.028).clamp(
                                            10.0,
                                            13.0,
                                          ),
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Toggle section
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
                                  GestureDetector(
                                    onTap: _isNavigating
                                        ? null
                                        : _navigateToBudgetMode,
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
                                              "Budget",
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[600],
                                                fontSize: (screenWidth * 0.028)
                                                    .clamp(10.0, 13.0),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
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
                                      "Expense",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: (screenWidth * 0.028).clamp(
                                          10.0,
                                          13.0,
                                        ),
                                        fontWeight: FontWeight.w600,
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
                        height: daysLeftHeight,
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
                                    fontSize: (screenWidth * 0.028).clamp(
                                      10.0,
                                      13.0,
                                    ),
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "$remainingDays",
                                  style: GoogleFonts.poppins(
                                    fontSize: (screenWidth * 0.09).clamp(
                                      28.0,
                                      40.0,
                                    ),
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
                                  vertical: (screenHeight * 0.015).clamp(
                                    10.0,
                                    15.0,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                var result = await showDialog(
                                  context: context,
                                  builder: (_) => ExpensePayNowPopup(
                                    categories: sortedCategories,
                                  ),
                                );
                                await updateWidgetData();
                                if (result != null &&
                                    result['success'] == true) {
                                  print("✅ Payment recorded successfully");
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "$currencySymbol Pay now",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: (screenWidth * 0.033).clamp(
                                        12.0,
                                        15.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// CATEGORY GRID - Expanded to take available space
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.01,
                          ),
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: screenWidth * 0.025,
                                  mainAxisSpacing: (screenHeight * 0.010).clamp(
                                    8.0,
                                    15.0,
                                  ),
                                  childAspectRatio: 1.19,
                                ),
                            itemCount: sortedCategories.length + 1,
                            itemBuilder: (context, index) {
                              if (index < sortedCategories.length) {
                                String categoryKey = sortedCategories[index];
                                int spentAmount =
                                    categorySpent[categoryKey] ?? 0;

                                double progress = totalSpent > 0
                                    ? (spentAmount / totalSpent).clamp(0.0, 1.0)
                                    : 0.0;

                                double previousProgress =
                                    _previousProgress[categoryKey] ?? progress;

                                _previousProgress[categoryKey] = progress;

                                String emoji = extractEmoji(categoryKey);
                                String categoryName = extractCategoryName(
                                  categoryKey,
                                );

                                Color liquidColor = getCategoryColor(
                                  categoryKey,
                                );

                                return GestureDetector(
                                  onTap: () async {
                                    var result = await showDialog(
                                      context: context,
                                      builder: (_) => ExpensePayNowPopup(
                                        categories: sortedCategories,
                                      ),
                                    );

                                    if (result != null &&
                                        result['success'] == true) {
                                      print("✅ Payment recorded successfully");
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Stack(
                                        children: [
                                          // Animated Liquid fill
                                          TweenAnimationBuilder<double>(
                                            key: ValueKey(
                                              '$categoryKey-$spentAmount',
                                            ),
                                            duration: const Duration(
                                              milliseconds: 1500,
                                            ),
                                            curve: Curves.easeInOut,
                                            tween: Tween<double>(
                                              begin: previousProgress,
                                              end: progress,
                                            ),
                                            builder:
                                                (
                                                  context,
                                                  animatedProgress,
                                                  child,
                                                ) {
                                                  return LiquidLinearProgressIndicator(
                                                    value: animatedProgress,
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
                                          // Glass effect
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
                                                fontSize: (screenWidth * 0.15)
                                                    .clamp(40.0, 60.0),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                // Add Category button (Pro check)
                                return GestureDetector(
                                  onTap: _handleAddCategoryTap,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _isProUser
                                          ? Colors.white.withOpacity(0.15)
                                          : Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5,
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
                                                colors: [
                                                  Colors.white.withOpacity(0.2),
                                                  Colors.white.withOpacity(
                                                    0.05,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: _isCheckingEntitlement
                                                ? SizedBox(
                                                    width: screenWidth * 0.08,
                                                    height: screenWidth * 0.08,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                            Colors.black,
                                                          ),
                                                    ),
                                                  )
                                                : _isProUser
                                                ? Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .add_circle_outline,
                                                        size:
                                                            (screenWidth * 0.12)
                                                                .clamp(
                                                                  35.0,
                                                                  50.0,
                                                                ),
                                                        color: const Color(
                                                          0xFF4CAF50,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            screenHeight * 0.01,
                                                      ),
                                                      Text(
                                                        "Add\nCategory",
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color: Colors
                                                                  .black87,
                                                              fontSize:
                                                                  (screenWidth *
                                                                          0.03)
                                                                      .clamp(
                                                                        11.0,
                                                                        14.0,
                                                                      ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ],
                                                  )
                                                : Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.lock,
                                                        size:
                                                            (screenWidth * 0.1)
                                                                .clamp(
                                                                  30.0,
                                                                  45.0,
                                                                ),
                                                        color: Colors.black,
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            screenHeight * 0.01,
                                                      ),
                                                      Text(
                                                        "5 Categories\nMax",
                                                        style: GoogleFonts.poppins(
                                                          color: Colors.black,
                                                          fontSize:
                                                              (screenWidth *
                                                                      0.03)
                                                                  .clamp(
                                                                    11.0,
                                                                    14.0,
                                                                  ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          shadows: [
                                                            Shadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    1,
                                                                  ),
                                                              blurRadius: 2,
                                                            ),
                                                          ],
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
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
                        ),
                      ),

                      /// ANALYTICS CONTAINER - Fixed at bottom
                      Container(
                        margin: EdgeInsets.fromLTRB(
                          screenWidth * 0.04,
                          0,
                          screenWidth * 0.04,
                          screenHeight * 0.035,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.02,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$currencySymbol$totalSpent",
                              style: GoogleFonts.poppins(
                                fontSize: (screenWidth * 0.06).clamp(
                                  20.0,
                                  28.0,
                                ),
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "spent this month",
                              style: GoogleFonts.poppins(
                                fontSize: (screenWidth * 0.025).clamp(
                                  9.0,
                                  12.0,
                                ),
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(
                              height: (screenHeight * 0.007).clamp(5.0, 8.0),
                            ),
                            Container(
                              width: double.infinity,
                              height: (screenHeight * 0.007).clamp(5.0, 8.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: totalSpent > 0 ? 0.5 : 0.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: (screenHeight * 0.012).clamp(8.0, 12.0),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      "$currencySymbol${sortedCategories.isNotEmpty ? totalSpent : 0}",
                                      style: GoogleFonts.poppins(
                                        fontSize: (screenWidth * 0.035).clamp(
                                          12.0,
                                          16.0,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "spent",
                                      style: GoogleFonts.poppins(
                                        fontSize: (screenWidth * 0.023).clamp(
                                          8.0,
                                          11.0,
                                        ),
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "${sortedCategories.length}",
                                      style: GoogleFonts.poppins(
                                        fontSize: (screenWidth * 0.035).clamp(
                                          12.0,
                                          16.0,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "categories",
                                      style: GoogleFonts.poppins(
                                        fontSize: (screenWidth * 0.023).clamp(
                                          8.0,
                                          11.0,
                                        ),
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.heavyImpact();
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
                                        size: (screenWidth * 0.045).clamp(
                                          16.0,
                                          20.0,
                                        ),
                                        color: Colors.grey[700],
                                      ),
                                      Text(
                                        "settings",
                                        style: GoogleFonts.poppins(
                                          fontSize: (screenWidth * 0.023).clamp(
                                            8.0,
                                            11.0,
                                          ),
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Placeholder for AddCategoryDialog
class AddCategoryDialog extends StatelessWidget {
  const AddCategoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Category'),
      content: Text('Category addition dialog goes here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}

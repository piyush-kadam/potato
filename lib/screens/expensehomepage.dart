import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:slideme/screens/category.dart';
import 'package:slideme/screens/chatbot.dart';
import 'package:slideme/screens/monthly_budget.dart';
import 'package:slideme/screens/settings.dart';
import 'package:slideme/screens/homepage.dart';
import 'package:slideme/screens/wrapper.dart';
import 'package:slideme/widgets/expaddcat.dart';
import 'package:slideme/widgets/expensepopup.dart';

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  bool isDarkMode = false;
  bool _isNavigating = false;

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

  Future<void> _navigateToBudgetMode() async {
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

        List<String> categories = [];
        if (data["expenseCategories"] != null) {
          categories = List<String>.from(data["expenseCategories"]);
        }

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

        // Calculate responsive heights
        final topBarHeight = availableHeight * 0.10;
        final daysLeftHeight = availableHeight * 0.12;
        final gridHeight = availableHeight * 0.58;
        final analyticsHeight = availableHeight * 0.17;

        // Calculate if scrolling is needed (more than 5 categories + 1 locked button = 6 items)
        bool needsScrolling = categories.length >= 5;

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
                          // Toggle section (unchanged)
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
                                              fontSize: screenWidth * 0.028,
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
                                      fontSize: screenWidth * 0.028,
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
                      height: daysLeftHeight.clamp(70.0, 110.0),
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
                                builder: (_) =>
                                    ExpensePayNowPopup(categories: categories),
                              );

                              if (result != null && result['success'] == true) {
                                print("✅ Payment recorded successfully");
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.currency_rupee,
                                  size: screenWidth * 0.04,
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

                    /// CATEGORY GRID
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate the actual height needed for the grid
                          int itemCount =
                              categories.length + 1; // +1 for locked button
                          int rows = (itemCount / 2).ceil();

                          // Calculate item dimensions
                          double itemWidth =
                              (constraints.maxWidth - screenWidth * 0.025) / 2;
                          double itemHeight = itemWidth / 1.3;

                          // Calculate total height needed
                          double calculatedHeight =
                              (rows * itemHeight) +
                              ((rows - 1) * screenHeight * 0.015);

                          // Use calculated height when 5 or less categories, but clamp to available space
                          // Use fixed height for scrolling when more than 5 categories
                          double maxAvailableHeight = gridHeight.clamp(
                            280.0,
                            450.0,
                          );
                          double finalHeight = needsScrolling
                              ? maxAvailableHeight
                              : calculatedHeight.clamp(
                                  200.0,
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
                                    mainAxisSpacing: screenHeight * 0.015,
                                    childAspectRatio: 1.2,
                                  ),
                              itemCount: categories.length + 1,
                              itemBuilder: (context, index) {
                                if (index < categories.length) {
                                  String categoryKey = categories[index];
                                  int spentAmount =
                                      categorySpent[categoryKey] ?? 0;

                                  double progress = totalSpent > 0
                                      ? (spentAmount / totalSpent).clamp(
                                          0.0,
                                          1.0,
                                        )
                                      : 0.0;

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
                                          categories: categories,
                                        ),
                                      );

                                      if (result != null &&
                                          result['success'] == true) {
                                        print(
                                          "✅ Payment recorded successfully",
                                        );
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
                                            // Liquid fill (no glass effect here)
                                            LiquidLinearProgressIndicator(
                                              value: progress,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    liquidColor,
                                                  ),
                                              backgroundColor:
                                                  Colors.transparent,
                                              borderColor: Colors.transparent,
                                              borderWidth: 0,
                                              borderRadius: 24.0,
                                              direction: Axis.vertical,
                                              center: Container(),
                                            ),
                                            // Glass effect only on empty area
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
                                                    stops: [
                                                      0.0,
                                                      1 - progress, // Glass effect stops where liquid starts
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
                                  // Locked "Add Category" button
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
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
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.lock,
                                                  size: screenWidth * 0.1,
                                                  color: Colors.black,
                                                ),
                                                SizedBox(
                                                  height: screenHeight * 0.01,
                                                ),
                                                Text(
                                                  "5 Categories\nMax",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.black,
                                                    fontSize:
                                                        screenWidth * 0.03,
                                                    fontWeight: FontWeight.w600,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                        blurRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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

                    /// ANALYTICS CONTAINER
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "₹$totalSpent",
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "spent this month",
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
                              widthFactor: totalSpent > 0 ? 0.5 : 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.005),

                          SizedBox(height: screenHeight * 0.012),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "₹${categories.isNotEmpty ? totalSpent : 0}",
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
                                    "${categories.length}",
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

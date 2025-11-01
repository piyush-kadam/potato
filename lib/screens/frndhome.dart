import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:slideme/screens/frndexpense.dart';

class ConnectedUserBudgetPage extends StatefulWidget {
  final String connectedUsername;
  final bool isDarkMode;

  const ConnectedUserBudgetPage({
    super.key,
    required this.connectedUsername,
    this.isDarkMode = false,
  });

  @override
  State<ConnectedUserBudgetPage> createState() =>
      _ConnectedUserBudgetPageState();
}

class _ConnectedUserBudgetPageState extends State<ConnectedUserBudgetPage> {
  String? connectedUserId;
  bool isLoadingUserId = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fetchConnectedUserId();
  }

  /// Navigate to connected user's expense page
  Future<void> _navigateToExpenseMode() async {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    try {
      if (!mounted) return;

      // Import: import 'package:slideme/screens/connected_user_expense_page.dart';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConnectedUserExpensePage(
            connectedUsername: widget.connectedUsername,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
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

  /// Fetch the userId of the connected user by their username
  Future<void> _fetchConnectedUserId() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("Users")
          .where('username', isEqualTo: widget.connectedUsername)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          connectedUserId = querySnapshot.docs.first.id;
          isLoadingUserId = false;
        });
      } else {
        setState(() {
          isLoadingUserId = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("User not found")));
        }
      }
    } catch (e) {
      setState(() {
        isLoadingUserId = false;
      });
      debugPrint("Error fetching connected user ID: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaHeight =
        MediaQuery.of(context).padding.top +
        MediaQuery.of(context).padding.bottom;
    final availableHeight = screenHeight - safeAreaHeight - kToolbarHeight;

    if (isLoadingUserId) {
      return Scaffold(
        backgroundColor: const Color(0xFFE3F2FD),
        appBar: AppBar(
          title: Text(
            widget.connectedUsername,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (connectedUserId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFE3F2FD),
        appBar: AppBar(
          title: Text(
            widget.connectedUsername,
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 18),
          ),
          titleSpacing: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Text(
            "User data not available",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Users")
          .doc(connectedUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFFE3F2FD),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String username = data["username"] ?? widget.connectedUsername;
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

        int spent = monthlyBudget - remainingBudget;
        int categoriesCount = categoryBudgets.length;
        double usedPercent = monthlyBudget > 0 ? spent / monthlyBudget : 0;

        final now = DateTime.now();
        final lastDay = DateTime(now.year, now.month + 1, 0);
        int remainingDays = lastDay.difference(now).inDays + 1;

        // Calculate responsive sizes
        final daysLeftHeight = availableHeight * 0.12;
        final gridHeight = availableHeight * 0.65;
        final analyticsHeight = availableHeight * 0.18;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  "$username's",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: screenWidth * 0.045,
                  ),
                ),
                titleSpacing: 0,
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.black),
                actions: [
                  /// Toggle Switch
                  Container(
                    margin: EdgeInsets.only(right: screenWidth * 0.04),
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
                          onTap: _isNavigating ? null : _navigateToExpenseMode,
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
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.grey[600]!,
                                              ),
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
              body: SafeArea(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableHeight),
                    child: Column(
                      children: [
                        /// DAYS LEFT
                        Container(
                          height: daysLeftHeight.clamp(60.0, 100.0),
                          padding: EdgeInsets.fromLTRB(
                            screenWidth * 0.065,
                            screenHeight * 0.006,
                            screenWidth * 0.065,
                            screenHeight * 0.02,
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
                            ],
                          ),
                        ),

                        /// CATEGORY GRID
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.002,
                          ),
                          child: categoryBudgets.isEmpty
                              ? SizedBox(
                                  height: gridHeight.clamp(300.0, 500.0),
                                  child: Center(
                                    child: Text(
                                      "No budget categories set",
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontSize: screenWidth * 0.035,
                                      ),
                                    ),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Calculate number of rows needed
                                    int itemCount = categoryBudgets.length;
                                    int rows = (itemCount / 2).ceil();

                                    // Calculate item height based on aspect ratio
                                    double itemWidth =
                                        (constraints.maxWidth -
                                            screenWidth * 0.025) /
                                        2;
                                    double itemHeight = itemWidth / 1.1;

                                    // Calculate total grid height needed
                                    double calculatedHeight =
                                        (rows * itemHeight) +
                                        ((rows - 1) * screenHeight * 0.015);

                                    // Use the calculated height but ensure it fits within available space
                                    double finalHeight = calculatedHeight.clamp(
                                      200.0,
                                      gridHeight.clamp(300.0, 500.0),
                                    );

                                    return SizedBox(
                                      height: finalHeight,
                                      child: GridView.builder(
                                        physics: itemCount > 4
                                            ? const BouncingScrollPhysics()
                                            : const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing:
                                                  screenWidth * 0.025,
                                              mainAxisSpacing:
                                                  screenHeight * 0.015,
                                              childAspectRatio: 1.1,
                                            ),
                                        itemCount: categoryBudgets.length,
                                        itemBuilder: (context, index) {
                                          var entry = categoryBudgets.entries
                                              .elementAt(index);
                                          String categoryKey = entry.key;

                                          int originalBudget =
                                              originalCategoryBudgets[categoryKey] ??
                                              entry.value;
                                          int spentAmount =
                                              categorySpent[categoryKey] ?? 0;
                                          int remainingInCategory =
                                              originalBudget - spentAmount;
                                          double progress = originalBudget > 0
                                              ? (remainingInCategory /
                                                        originalBudget)
                                                    .clamp(0.0, 1.0)
                                              : 0.0;
                                          if (remainingInCategory < 0) {
                                            remainingInCategory = 0;
                                            progress = 0.0;
                                          }

                                          String emoji = extractEmoji(
                                            categoryKey,
                                          );
                                          String categoryName =
                                              extractCategoryName(categoryKey);
                                          Color categoryColor =
                                              getCategoryColor(categoryKey);

                                          Color liquidColor;
                                          if (progress > 0.5) {
                                            liquidColor = const Color(
                                              0xFF4CAF50,
                                            );
                                          } else if (progress > 0.25) {
                                            liquidColor = const Color(
                                              0xFF7931E1,
                                            );
                                          } else {
                                            liquidColor = const Color(
                                              0xFFFF3B30,
                                            );
                                          }

                                          return GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  title: Text(
                                                    "$emoji $categoryName",
                                                    style: GoogleFonts.poppins(
                                                      fontSize:
                                                          screenWidth * 0.045,
                                                    ),
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Original Budget: ₹$originalBudget",
                                                      ),
                                                      Text(
                                                        "Spent: ₹$spentAmount",
                                                      ),
                                                      Text(
                                                        "Remaining: ₹$remainingInCategory",
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Text(
                                                        "${(progress * 100).toStringAsFixed(1)}% remaining",
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  liquidColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text(
                                                        "Close",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                child: Stack(
                                                  children: [
                                                    // Liquid progress indicator with full opacity
                                                    TweenAnimationBuilder<
                                                      double
                                                    >(
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
                                                              Colors
                                                                  .transparent,
                                                          borderColor: Colors
                                                              .transparent,
                                                          borderWidth: 0,
                                                          borderRadius: 24.0,
                                                          direction:
                                                              Axis.vertical,
                                                          center: Container(),
                                                        );
                                                      },
                                                    ),
                                                    // Gradient overlay
                                                    Positioned.fill(
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                            colors: [
                                                              Colors.white
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                              Colors.white
                                                                  .withOpacity(
                                                                    0.05,
                                                                  ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Emoji
                                                    Center(
                                                      child: Text(
                                                        emoji,
                                                        style: TextStyle(
                                                          fontSize:
                                                              screenWidth *
                                                              0.15,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),

                        SizedBox(height: screenHeight * 0.01),

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
                            minHeight: analyticsHeight.clamp(100.0, 180.0),
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
                                "₹$remainingBudget",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "remaining of ₹$monthlyBudget",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.025,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              Container(
                                width: double.infinity,
                                height: screenHeight * 0.008,
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
                                        "₹$spent",
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

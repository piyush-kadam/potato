import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:slideme/screens/frndhome.dart';

class ConnectedUserExpensePage extends StatefulWidget {
  final String connectedUsername;
  final bool isDarkMode;

  const ConnectedUserExpensePage({
    super.key,
    required this.connectedUsername,
    this.isDarkMode = false,
  });

  @override
  State<ConnectedUserExpensePage> createState() =>
      _ConnectedUserExpensePageState();
}

class _ConnectedUserExpensePageState extends State<ConnectedUserExpensePage> {
  String? connectedUserId;
  bool isLoadingUserId = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fetchConnectedUserId();
  }

  /// Navigate to connected user's budget page
  Future<void> _navigateToBudgetMode() async {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    try {
      if (!mounted) return;

      // Import: import 'package:slideme/screens/connected_user_budget_page.dart';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConnectedUserBudgetPage(
            connectedUsername: widget.connectedUsername,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
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
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLoadingUserId) {
      return Scaffold(
        body: Stack(
          children: [
            // Color background
            Container(color: const Color(0xFFfde68a)),
            // Image overlay
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bgg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Column(
                children: [
                  AppBar(
                    title: Text(
                      widget.connectedUsername,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                    ),
                    titleSpacing: 0,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.black),
                  ),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (connectedUserId == null) {
      return Scaffold(
        body: Stack(
          children: [
            // Color background
            Container(color: const Color(0xFFfde68a)),
            // Image overlay
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bgg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Column(
                children: [
                  AppBar(
                    title: Text(
                      widget.connectedUsername,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.black),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "User data not available",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            body: Stack(
              children: [
                // Color background
                Container(color: const Color(0xFFfde68a)),
                // Image overlay
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/bgg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Content
                const Center(child: CircularProgressIndicator()),
              ],
            ),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String username = data["username"] ?? widget.connectedUsername;

        List<String> categories = [];
        if (data["expenseCategories"] != null) {
          categories = List<String>.from(data["expenseCategories"]);
        }

        Map<String, int> categorySpent = {};
        if (data["expenseCategorySpent"] != null ||
            data["expenseCategorySpent"] != null) {
          (data["expenseCategorySpent"] as Map<String, dynamic>).forEach((
            key,
            value,
          ) {
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

        return Scaffold(
          body: Stack(
            children: [
              // Color background
              Container(color: const Color(0xFFfde68a)),
              // Image overlay
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/bgg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Column(
                  children: [
                    /// AppBar - Fixed height
                    AppBar(
                      title: Text(
                        "$username's",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      titleSpacing: 0,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      iconTheme: const IconThemeData(color: Colors.black),
                      actions: [
                        /// Toggle Switch
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: _isNavigating
                                      ? SizedBox(
                                          width: 45,
                                          height: 14,
                                          child: Center(
                                            child: SizedBox(
                                              width: 10,
                                              height: 10,
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
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  "Expense",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// DAYS LEFT - Fixed height
                    Container(
                      height: screenHeight * 0.11,
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
                                  fontSize: screenHeight * 0.014,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "$remainingDays",
                                style: GoogleFonts.poppins(
                                  fontSize: screenHeight * 0.044,
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

                    /// Content with responsive sizing - Takes remaining space
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Reserve space for analytics container
                          final analyticsHeight = screenHeight * 0.20;
                          final availableGridHeight =
                              constraints.maxHeight -
                              analyticsHeight -
                              (screenHeight * 0.02);

                          return Column(
                            children: [
                              /// Category Grid - Fixed height with scrolling
                              SizedBox(
                                height: availableGridHeight,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.042,
                                  ),
                                  child: categories.isEmpty
                                      ? Center(
                                          child: Text(
                                            "No expense categories set",
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[600],
                                              fontSize: screenHeight * 0.018,
                                            ),
                                          ),
                                        )
                                      : GridView.builder(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                crossAxisSpacing:
                                                    screenWidth * 0.026,
                                                mainAxisSpacing:
                                                    screenHeight * 0.015,
                                                childAspectRatio: 1.1,
                                              ),
                                          itemCount: categories.length,
                                          itemBuilder: (context, index) {
                                            String categoryKey =
                                                categories[index];
                                            int spentAmount =
                                                categorySpent[categoryKey] ?? 0;

                                            double progress = totalSpent > 0
                                                ? (spentAmount / totalSpent)
                                                      .clamp(0.0, 1.0)
                                                : 0.0;

                                            String emoji = extractEmoji(
                                              categoryKey,
                                            );
                                            String categoryName =
                                                extractCategoryName(
                                                  categoryKey,
                                                );

                                            const Color liquidColor = Color(
                                              0xFF34C759,
                                            );

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
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 18,
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
                                                          "Total Spent: ₹$spentAmount",
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Text(
                                                          "${((spentAmount / (totalSpent > 0 ? totalSpent : 1)) * 100).toStringAsFixed(1)}% of total expenses",
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
                                                  color: Colors.white
                                                      .withOpacity(0.1),
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
                                                      // Liquid progress indicator
                                                      TweenAnimationBuilder<
                                                        double
                                                      >(
                                                        duration:
                                                            const Duration(
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
                                                                screenHeight *
                                                                0.063,
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
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.02),

                              /// ANALYTICS CONTAINER - Fixed at bottom
                              Container(
                                margin: EdgeInsets.fromLTRB(
                                  screenWidth * 0.042,
                                  0,
                                  screenWidth * 0.042,
                                  screenHeight * 0.02,
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
                                      "₹$totalSpent",
                                      style: GoogleFonts.poppins(
                                        fontSize: screenHeight * 0.03,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "spent this month",
                                      style: GoogleFonts.poppins(
                                        fontSize: screenHeight * 0.013,
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
                                        widthFactor: totalSpent > 0 ? 0.5 : 0.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),

                                    SizedBox(height: screenHeight * 0.013),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              "₹${categories.isNotEmpty ? (totalSpent / categories.length).round() : 0}",
                                              style: GoogleFonts.poppins(
                                                fontSize: screenHeight * 0.018,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              "avg/category",
                                              style: GoogleFonts.poppins(
                                                fontSize: screenHeight * 0.011,
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
                                                fontSize: screenHeight * 0.018,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              "categories",
                                              style: GoogleFonts.poppins(
                                                fontSize: screenHeight * 0.011,
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
                          );
                        },
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

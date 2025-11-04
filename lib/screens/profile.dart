import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slideme/auth/authservice.dart';
import 'package:slideme/auth/login.dart';
import 'package:slideme/auth/subscription.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String selectedMonth = 'current'; // 'current' or 'previous'

  @override
  void initState() {
    super.initState();
    _checkAndStoreMonthlyData();
  }

  // Check if it's last day of month at 11:59 PM and store data
  void _checkAndStoreMonthlyData() async {
    DateTime now = DateTime.now();

    // Check if it's 11:59 PM
    if (now.hour == 23 && now.minute == 59) {
      // Check if tomorrow is a new month (means today is last day)
      DateTime tomorrow = now.add(const Duration(days: 1));
      if (tomorrow.month != now.month) {
        // It's the last day at 11:59 PM - store the data!
        await _storeMonthlyAnalytics();
      }
    }
  }

  Future<void> _storeMonthlyAnalytics() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Get current user data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

      // Store previous month analytics (only store, don't reset)
      Map<String, dynamic> previousMonthData = {
        'categoryBudgets': data['categoryBudgets'] ?? {},
        'categorySpent': data['categorySpent'] ?? {},
        'month': DateTime.now().month,
        'year': DateTime.now().year,
        'savedAt': FieldValue.serverTimestamp(),
      };

      // Update database - only store previous month data
      await FirebaseFirestore.instance.collection("Users").doc(userId).update({
        'previousMonthAnalytics': previousMonthData,
      });

      print('✅ Monthly analytics stored!');
    } catch (e) {
      print('❌ Error storing analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

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
        String email = data["email"] ?? "Not available";
        String country = data["country"] ?? "India";
        int monthlyBudget = (data["monthlyBudget"] ?? 0).toInt();
        int remainingBudget = (data["remainingBudget"] ?? 0).toInt();
        int totalTransactions = (data["transactions"] ?? 0).toInt();

        // Get currency symbol based on country
        String currencySymbol = _getCurrencySymbol(country);

        // Get data based on selected month
        Map<String, dynamic> displayData = selectedMonth == 'current'
            ? data
            : (data["previousMonthAnalytics"] as Map<String, dynamic>? ?? {});

        // Parse categoryBudgets safely
        Map<String, int> categoryBudgets = {};
        if (displayData["categoryBudgets"] != null) {
          (displayData["categoryBudgets"] as Map<String, dynamic>).forEach((
            key,
            value,
          ) {
            if (value is num) {
              categoryBudgets[key] = value.toInt();
            }
          });
        }

        // Parse categorySpent safely
        Map<String, int> categorySpent = {};
        if (displayData["categorySpent"] != null) {
          (displayData["categorySpent"] as Map<String, dynamic>).forEach((
            key,
            value,
          ) {
            if (value is num) {
              categorySpent[key] = value.toInt();
            }
          });
        }

        // Calculate total spent from categorySpent (for current month stats)
        int totalSpent = 0;
        if (data["categorySpent"] != null) {
          (data["categorySpent"] as Map<String, dynamic>).forEach((key, value) {
            if (value is num) {
              totalSpent += value.toInt();
            }
          });
        }

        // Days active (based on createdAt timestamp)
        int daysActive = 0;
        if (data["createdAt"] != null) {
          DateTime createdAt = (data["createdAt"] as Timestamp).toDate();
          daysActive = DateTime.now().difference(createdAt).inDays;
          if (daysActive == 0) daysActive = 1; // Avoid division by zero
        }

        // Calculate daily average (total spent / days active)
        int dailyAverage = daysActive > 0
            ? (totalSpent / daysActive).round()
            : 0;

        // Find top spending category
        String topCategory = "None";
        int topCategoryAmount = 0;
        if (data["categorySpent"] != null) {
          (data["categorySpent"] as Map<String, dynamic>).forEach((key, value) {
            if (value is num) {
              int amount = value.toInt();
              if (amount > topCategoryAmount) {
                topCategoryAmount = amount;
                topCategory = key;
              }
            }
          });
        }

        // Budget progress %
        double budgetProgress = monthlyBudget > 0
            ? totalSpent / monthlyBudget
            : 0;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom AppBar with Close Icon
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          "Profile",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the layout
                      ],
                    ),
                  ),
                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Circle
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.green.shade300,
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : "U",
                              style: GoogleFonts.poppins(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            username,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Get PotatoBook Pro Banner
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SubscriptionPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.north_east_outlined,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Get PotatoBook Pro",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "How much you spent yesterday",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Stats Grid (4 cards)
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.account_balance_wallet,
                                  label: "Total Spent",
                                  value:
                                      "$currencySymbol${totalSpent.toString()}",
                                  color: Colors.red.shade50,
                                  iconColor: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.trending_up,
                                  label: "Remaining",
                                  value:
                                      "$currencySymbol${remainingBudget.toString()}",
                                  color: Colors.green.shade50,
                                  iconColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.calendar_today,
                                  label: "Daily Average",
                                  value:
                                      "$currencySymbol${dailyAverage.toString()}",
                                  color: Colors.blue.shade50,
                                  iconColor: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.shopping_bag,
                                  label: "Top Category",
                                  value: topCategory,
                                  subValue:
                                      "$currencySymbol${topCategoryAmount.toString()}",
                                  color: Colors.purple.shade50,
                                  iconColor: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Category Breakdown with Month Filter
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Title Section
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.bar_chart,
                                              color: Colors.orange.shade700,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              "Analytics",
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Month Filter (Dropdown)
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: selectedMonth,
                                            isDense: true,
                                            icon: Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey.shade700,
                                              size: 18,
                                            ),
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'current',
                                                child: Text('This Month'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'previous',
                                                child: Text('Last Month'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                selectedMonth = value!;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                if (categoryBudgets.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text(
                                        selectedMonth == 'previous'
                                            ? "No data for previous month"
                                            : "No categories set up yet",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...categoryBudgets.entries.map((entry) {
                                    String categoryKey = entry.key;
                                    int budget = entry.value;
                                    int spent = categorySpent[categoryKey] ?? 0;
                                    double percentage = budget > 0
                                        ? (spent / budget) * 100
                                        : 0;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                categoryKey,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                "$currencySymbol$spent",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: percentage / 100,
                                              minHeight: 8,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    _getCategoryColor(
                                                      percentage,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${percentage.toStringAsFixed(1)}% of budget used",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // This Month Summary Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.shade200,
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "This Month Summary",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Total Transactions",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$totalTransactions",
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Days Active",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$daysActive",
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Budget Progress",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            "${(budgetProgress * 100).toStringAsFixed(1)}%",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "$currencySymbol$totalSpent / $currencySymbol$monthlyBudget",
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Logout Button
                          GestureDetector(
                            onTap: () async {
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    "Logout",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  content: Text(
                                    "Are you sure you want to logout?",
                                    style: GoogleFonts.poppins(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                        "Cancel",
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        "Logout",
                                        style: GoogleFonts.poppins(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldLogout == true) {
                                try {
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  await AuthService().signOut();

                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LoginPage(onTap: () {}),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Error logging out: ${e.toString()}",
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Colors.red.shade700,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Logout",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subValue != null)
                Text(
                  subValue,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(double percentage) {
    if (percentage >= 80) {
      return Colors.red;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getCurrencySymbol(String country) {
    // Map of countries to their currency symbols
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

    return currencyMap[country] ?? '₹'; // Default to rupee if country not found
  }
}

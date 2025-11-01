import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class MonthlyWrapScreen extends StatefulWidget {
  const MonthlyWrapScreen({Key? key}) : super(key: key);

  @override
  State<MonthlyWrapScreen> createState() => _MonthlyWrapScreenState();
}

class _MonthlyWrapScreenState extends State<MonthlyWrapScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animationController;

  late Future<Map<String, dynamic>> _monthlyDataFuture;

  Map<String, dynamic>? monthlyData;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();

    _monthlyDataFuture = fetchMonthlyDataFromFirestore();
  }

  Future<Map<String, dynamic>> fetchMonthlyDataFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      if (data.containsKey('previousMonthAnalytics')) {
        return Map<String, dynamic>.from(data['previousMonthAnalytics']);
      } else {
        throw Exception("Previous month analytics data not found");
      }
    } else {
      throw Exception("User document does not exist");
    }
  }

  double get totalBudget {
    final budgets =
        monthlyData?['categoryBudgets'] as Map<String, dynamic>? ?? {};
    return budgets.values.fold(
      0.0,
      (sum, value) => sum + (value as num).toDouble(),
    );
  }

  double get totalSpent {
    final spent = monthlyData?['categorySpent'] as Map<String, dynamic>? ?? {};
    return spent.values.fold(
      0.0,
      (sum, value) => sum + (value as num).toDouble(),
    );
  }

  double get remaining => totalBudget - totalSpent;

  MapEntry<String, double> get topCategory {
    final spent = monthlyData?['categorySpent'] as Map<String, dynamic>? ?? {};
    if (spent.isEmpty) return MapEntry('No Data', 0.0);

    var entries =
        spent.entries
            .map((e) => MapEntry(e.key as String, (e.value as num).toDouble()))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first;
  }

  String get monthName {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    int month = monthlyData?['month'] ?? DateTime.now().month;
    return months[month - 1];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _monthlyDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('No data found')));
        }

        monthlyData = snapshot.data!;
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Animated background gradient
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(
                            const Color(0xFF1a1a2e),
                            const Color(0xFF16213e),
                            _animationController.value,
                          )!,
                          Color.lerp(
                            const Color(0xFF0f3460),
                            const Color(0xFF533483),
                            _animationController.value,
                          )!,
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your $monthName Wrap',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Page indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Pages
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                          _animationController.reset();
                          _animationController.forward();
                        },
                        children: [
                          _buildTopCategoryPage(),
                          _buildAnalyticsPage(),
                          _buildSummaryPage(),
                        ],
                      ),
                    ),

                    // Navigation hint
                    if (_currentPage < 2)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Swipe for more',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withOpacity(0.7),
                              size: 16,
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

  Widget _buildTopCategoryPage() {
    final category = topCategory;
    final budgets =
        monthlyData?['categoryBudgets'] as Map<String, dynamic>? ?? {};
    final budget = (budgets[category.key] as num?)?.toDouble() ?? 0.0;
    final percentage = budget > 0
        ? (category.value / budget * 100).clamp(0, 100)
        : 0.0;

    return FadeTransition(
      opacity: _animationController,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Your top spending category',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 40),

              // Category emoji in circle
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.withOpacity(0.3),
                      Colors.pink.withOpacity(0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category.key.split(' ')[0],
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Text(
                category.key.substring(category.key.indexOf(' ') + 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '₹${category.value.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${percentage.toStringAsFixed(0)}% of budget used',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsPage() {
    final spent = monthlyData?['categorySpent'] as Map<String, dynamic>? ?? {};
    final budgets =
        monthlyData?['categoryBudgets'] as Map<String, dynamic>? ?? {};

    List<MapEntry<String, double>> sortedCategories =
        spent.entries
            .map((e) => MapEntry(e.key as String, (e.value as num).toDouble()))
            .where((e) => e.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return FadeTransition(
      opacity: _animationController,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Category Breakdown',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: sortedCategories.length,
                itemBuilder: (context, index) {
                  final category = sortedCategories[index];
                  final budget =
                      (budgets[category.key] as num?)?.toDouble() ?? 0.0;
                  final percentage = budget > 0
                      ? (category.value / budget * 100).clamp(0, 100)
                      : 0.0;

                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 500 + (index * 100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      category.key.split(' ')[0],
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category.key.substring(
                                              category.key.indexOf(' ') + 1,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '₹${category.value.toStringAsFixed(0)} of ₹${budget.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: percentage > 90
                                            ? Colors.red
                                            : Colors.greenAccent,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value:
                                        (percentage / 100).clamp(0.0, 1.0) *
                                        value,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      percentage > 90
                                          ? Colors.red
                                          : Colors.greenAccent,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPage() {
    final savingsPercentage = totalBudget > 0
        ? (remaining / totalBudget * 100).clamp(0, 100)
        : 0.0;

    return FadeTransition(
      opacity: _animationController,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Your Financial Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 60),

              _buildSummaryCard(
                'Total Budget',
                '₹${totalBudget.toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                Colors.blue,
              ),
              const SizedBox(height: 20),

              _buildSummaryCard(
                'Total Spent',
                '₹${totalSpent.toStringAsFixed(0)}',
                Icons.trending_up,
                Colors.orange,
              ),
              const SizedBox(height: 20),

              _buildSummaryCard(
                'Remaining',
                '₹${remaining.toStringAsFixed(0)}',
                Icons.savings,
                remaining >= 0 ? Colors.green : Colors.red,
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.3),
                      Colors.pink.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      remaining >= 0 ? '🎉 Great job!' : '⚠️ Over budget',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      remaining >= 0
                          ? 'You saved ${savingsPercentage.toStringAsFixed(0)}% of your budget!'
                          : 'You went over budget by ₹${(-remaining).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

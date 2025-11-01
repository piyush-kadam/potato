import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:slideme/auth/authservice.dart';
import 'package:slideme/auth/login.dart';
import 'package:slideme/auth/subscription.dart';
import 'package:slideme/screens/motnhlywrap.dart';
import 'package:slideme/screens/profile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _resetMonthlyDataIfNeeded();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final doc = await docRef.get();
    if (doc.exists) {
      setState(() {
        userData = doc.data();
        isLoading = false;
      });
    }
  }

  Future<void> _resetMonthlyDataIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final lastReset = data['lastResetDate'];
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);

    // Only reset if we have a lastResetDate AND it's from a previous month
    if (lastReset != null && lastReset != currentMonth) {
      // This means a new month has started since the last reset
      await docRef.update({
        'categorySpent': _resetMapValues(data['categorySpent']),
        'expenseCategorySpent': _resetMapValues(data['expenseCategorySpent']),
        'lastResetDate': currentMonth,
      });
    } else if (lastReset == null) {
      // First time - just set the lastResetDate without resetting
      await docRef.update({'lastResetDate': currentMonth});
    }
  }

  Map<String, dynamic> _resetMapValues(Map? map) {
    if (map == null) return {};
    final resetMap = <String, dynamic>{};
    map.forEach((key, value) => resetMap[key] = 0);
    return resetMap;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Extract data safely
    final username = userData?['username'] ?? "User";
    final monthlyBudget = userData?['monthlyBudget'] ?? 0;
    final remaining = userData?['remainingBudget'] ?? 0;
    final spent = monthlyBudget - remaining;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 18,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                username,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildBudgetStat(
                                    "Budget",
                                    "₹${monthlyBudget.toString()}",
                                    Colors.blue,
                                  ),
                                  _buildBudgetStat(
                                    "Spent",
                                    "₹$spent",
                                    Colors.orange,
                                  ),
                                  _buildBudgetStat(
                                    "Remaining",
                                    "₹${remaining.toString()}",
                                    Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SubscriptionPage(),
                              ),
                            );
                          },
                          child: _buildActionCard(
                            title: "Get Pro",
                            icon: Icons.north_east_outlined,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _logoutUser,
                          child: _buildActionCard(
                            title: "Logout",
                            icon: Icons.logout_rounded,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    child: Text("wrapper", style: GoogleFonts.poppins()),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MonthlyWrapScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logoutUser() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Logout",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Are you sure you want to logout?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
        }

        await AuthService().signOut();

        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginPage(onTap: () {})),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
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
  }
}

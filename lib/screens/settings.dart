import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:slideme/auth/authservice.dart';
import 'package:slideme/auth/login.dart';
import 'package:slideme/auth/subscription.dart';
import 'package:slideme/info_pages/faq.dart';
import 'package:slideme/info_pages/policy.dart';
import 'package:slideme/info_pages/report.dart';
import 'package:slideme/info_pages/terms.dart';
import 'package:slideme/screens/monthlywrap.dart';
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
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);
    final lastReset = data['lastResetDate'];

    // 🆕 New user (no reset date yet)
    if (lastReset == null) {
      await docRef.update({'lastResetDate': currentMonth});
      debugPrint('🆕 First-time user detected — set lastResetDate only.');
      return;
    }

    // 📅 Month changed — reset monthly fields
    if (lastReset != currentMonth) {
      await docRef.update({
        'categorySpent': _resetMapValues(data['categorySpent'] ?? {}),
        'expenseCategorySpent': _resetMapValues(
          data['expenseCategorySpent'] ?? {},
        ),
        'lastResetDate': currentMonth,
      });
      debugPrint('✅ Monthly data reset for $currentMonth');
    } else {
      debugPrint('⏸ No reset needed — same month ($currentMonth)');
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null) {
          return const Scaffold(
            body: Center(child: Text("No User Data Found")),
          );
        }

        // Currency mapping
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

        // Extract data
        final username = userData['username'] ?? "User";
        final monthlyBudget = userData['monthlyBudget'] ?? 0;
        final remaining = userData['remainingBudget'] ?? 0;
        final spent = monthlyBudget - remaining;
        final country = userData['country'] as String?;
        final profilePic = userData['pfp'] as String?;

        final currencySymbol =
            (country != null && currencyMap.containsKey(country))
            ? currencyMap[country]!
            : '₹';

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
                      // Profile Container
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 34,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.3,
                                      ),
                                      backgroundImage:
                                          (profilePic != null &&
                                              profilePic.isNotEmpty)
                                          ? NetworkImage(profilePic)
                                          : null,
                                      child:
                                          (profilePic == null ||
                                              profilePic.isEmpty)
                                          ? const Icon(
                                              Icons.person,
                                              size: 32,
                                              color: Colors.green,
                                            )
                                          : null,
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
                                        "$currencySymbol${monthlyBudget.toString()}",
                                        Colors.blue,
                                      ),
                                      _buildBudgetStat(
                                        "Spent",
                                        "$currencySymbol$spent",
                                        Colors.orange,
                                      ),
                                      _buildBudgetStat(
                                        "Remaining",
                                        "$currencySymbol${remaining.toString()}",
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

                      // Pro Container
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionPage(),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.7),
                                    Colors.green.shade700.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
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
                                          "Unlock premium features",
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
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Settings Options
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Column(
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.help_outline_rounded,
                                  title: "FAQ",
                                  onTap: () {
                                    HapticFeedback.heavyImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const FAQScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                _buildSettingsTile(
                                  icon: Icons.privacy_tip_outlined,
                                  title: "Privacy Policy",
                                  onTap: () {
                                    HapticFeedback.heavyImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PrivacyPolicyPage(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                _buildSettingsTile(
                                  icon: Icons.description_outlined,
                                  title: "Terms and Conditions",
                                  onTap: () {
                                    HapticFeedback.heavyImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TermsAndConditionsPage(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                _buildSettingsTile(
                                  icon: Icons.privacy_tip_outlined,
                                  title: "Report an Issue",
                                  onTap: () {
                                    HapticFeedback.heavyImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ReportIssuePage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54, size: 24),
          ],
        ),
      ),
    );
  }
}

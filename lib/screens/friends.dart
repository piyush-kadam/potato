import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slideme/screens/frndexpense.dart';
import 'package:slideme/screens/frndhome.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';

class FriendsAndFamilyPage extends StatefulWidget {
  final bool isDarkMode;
  final String username;

  const FriendsAndFamilyPage({
    super.key,
    required this.isDarkMode,
    required this.username,
  });

  @override
  State<FriendsAndFamilyPage> createState() => _FriendsAndFamilyPageState();
}

class _FriendsAndFamilyPageState extends State<FriendsAndFamilyPage> {
  final TextEditingController _codeController = TextEditingController();
  final List<String> connectedUsers = [];

  String userCode = "";
  bool isLoadingCode = true;

  // Emoji list for avatars
  final List<String> emojis = ['👨', '👩', '👦', '👧', '🧒', '👴', '👵', '🧑'];

  @override
  void initState() {
    super.initState();
    _loadUserInviteCode();
    _loadLinkedUsers();
  }

  /// 🔹 Load current user's inviteCode from Firestore
  Future<void> _loadUserInviteCode() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .get();

    if (userDoc.exists && userDoc.data()?['inviteCode'] != null) {
      setState(() {
        userCode = userDoc['inviteCode'];
        isLoadingCode = false;
      });
    } else {
      // Generate and save if not present
      final generatedCode = widget.username.hashCode.abs().toString().substring(
        0,
        6,
      );
      await FirebaseFirestore.instance.collection("Users").doc(userId).update({
        'inviteCode': generatedCode,
      });
      setState(() {
        userCode = generatedCode;
        isLoadingCode = false;
      });
    }
  }

  /// 🔹 Load linked users list from Firestore
  Future<void> _loadLinkedUsers() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .get();

    if (userDoc.exists && userDoc.data()?['linkedUsers'] != null) {
      List<dynamic> list = userDoc['linkedUsers'];
      setState(() => connectedUsers.addAll(list.cast<String>()));
    }
  }

  /// 🔹 Share invite code using system share sheet
  void _shareInviteCode() {
    final shareText = 'Join me on SlideMe! Use my invite code: $userCode';
    Share.share(shareText, subject: 'SlideMe Invite Code');
  }

  /// 🔹 Show bottom sheet to add friend
  void _showAddFriendSheet() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Connect with Family or Friend",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              style: GoogleFonts.poppins(
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: "Enter invite code",
                hintStyle: GoogleFonts.poppins(
                  color: widget.isDarkMode
                      ? Colors.grey[500]
                      : Colors.grey[600],
                ),
                filled: true,
                fillColor: widget.isDarkMode
                    ? const Color(0xFF1A1A1A)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.vpn_key,
                  color: widget.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(context);
                  _connectUser(_codeController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Connect",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 🔹 Connect using invite code
  Future<void> _connectUser(String code) async {
    if (code.isEmpty) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final currentUserRef = firestore.collection("Users").doc(currentUserId);

      // 🔹 Find user by inviteCode
      final querySnapshot = await firestore
          .collection("Users")
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Invalid code entered.",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final connectedUsername = querySnapshot.docs.first['username'];

      // 🔹 Add connected user to Firestore field
      await currentUserRef.update({
        "linkedUsers": FieldValue.arrayUnion([connectedUsername]),
      });

      // 🔹 Update local list to reflect immediately
      if (!connectedUsers.contains(connectedUsername)) {
        setState(() {
          connectedUsers.add(connectedUsername);
        });
      }

      _codeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Connected with $connectedUsername!",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error linking user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error linking user.", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔹 Show dialog to choose Budget or Expense mode for connected user
  Future<void> _showConnectedUserOptions(String username) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "View $username's Data",
          style: GoogleFonts.poppins(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          "Choose which mode to view:",
          style: GoogleFonts.poppins(
            color: widget.isDarkMode ? Colors.grey[300] : Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            icon: const Icon(Icons.account_balance_wallet, size: 18),
            label: Text("Budget", style: GoogleFonts.poppins()),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConnectedUserBudgetPage(
                    connectedUsername: username,
                    isDarkMode: widget.isDarkMode,
                  ),
                ),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            icon: const Icon(Icons.receipt_long, size: 18),
            label: Text("Expense", style: GoogleFonts.poppins()),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConnectedUserExpensePage(
                    connectedUsername: username,
                    isDarkMode: widget.isDarkMode,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.only(bottom: 50),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar WITHOUT back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      "Family & Friends",
                      style: GoogleFonts.poppins(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    // Optional: Add a swipe hint icon
                    Icon(
                      Icons.swipe,
                      color: Colors.grey.withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
              ),

              // Top Section with subtitle and button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      "Manage shared budgets",
                      style: GoogleFonts.poppins(
                        color: widget.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add Family or Friend Button (Green)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _showAddFriendSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: Text(
                          "Add Family or Friend",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Connected Users Grid in Glass Container
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: connectedUsers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 80,
                                      color: widget.isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No connections yet",
                                      style: GoogleFonts.poppins(
                                        color: widget.isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Add family or friends to share budgets",
                                      style: GoogleFonts.poppins(
                                        color: widget.isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(20),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.0,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                itemCount: connectedUsers.length,
                                itemBuilder: (context, index) {
                                  final user = connectedUsers[index];
                                  final emoji = emojis[index % emojis.length];

                                  return GestureDetector(
                                    onTap: () =>
                                        _showConnectedUserOptions(user),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 5,
                                          sigmaY: 5,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: widget.isDarkMode
                                                ? Colors.white.withOpacity(0.15)
                                                : Colors.white.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.3,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              // Emoji Avatar
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFFF3CD),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    emoji,
                                                    style: const TextStyle(
                                                      fontSize: 32,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              // Name
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                child: Text(
                                                  user,
                                                  style: GoogleFonts.poppins(
                                                    color: widget.isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // Role/Relationship
                                              Text(
                                                "Member",
                                                style: GoogleFonts.poppins(
                                                  color: widget.isDarkMode
                                                      ? Colors.grey[400]
                                                      : Colors.grey[700],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Invite Code Section with Glass Effect
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Your Invite Code",
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.isDarkMode
                                            ? Colors.white.withOpacity(0.15)
                                            : Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: isLoadingCode
                                          ? const Center(
                                              child: SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xFF4CAF50),
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                          : Text(
                                              userCode,
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF4CAF50),
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      onPressed: _shareInviteCode,
                                      icon: const Icon(
                                        Icons.share,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom bubbles (pill + circle)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

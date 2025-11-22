import 'package:flutter/material.dart';
import 'package:slideme/screens/friends.dart';
import 'package:slideme/screens/expensehomepage.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpensePageWithSlider extends StatefulWidget {
  const ExpensePageWithSlider({super.key});

  @override
  State<ExpensePageWithSlider> createState() => _ExpensePageWithSliderState();
}

class _ExpensePageWithSliderState extends State<ExpensePageWithSlider> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        bool isDarkMode = data["isDarkMode"] ?? false;

        return Scaffold(
          body: Stack(
            children: [
              // PageView with both pages
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // Friends page (index 0 - left side)
                  FriendsAndFamilyPage(
                    isDarkMode: isDarkMode,
                    username: username,
                  ),
                  // ExpenseHomePage (index 1 - center/right side)
                  const ExpenseHomePage(),
                ],
              ),

              // Fixed Page Indicators at bottom (stays persistent across pages)
              Positioned(
                bottom: 25,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: false,
                  child: Center(
                    child: PageIndicators(
                      currentPage: _currentPage,
                      onTap: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
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

// Page Indicators Widget
class PageIndicators extends StatelessWidget {
  final int currentPage;
  final Function(int) onTap;

  const PageIndicators({
    super.key,
    required this.currentPage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIndicator(0),
          const SizedBox(width: 8),
          _buildIndicator(1),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = currentPage == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4CAF50)
              : Colors.grey.withOpacity(0.4),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

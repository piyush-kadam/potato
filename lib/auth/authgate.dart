import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:slideme/auth/lr.dart';
import 'package:slideme/auth/signup.dart';
import 'package:slideme/screens/category.dart';
import 'package:slideme/screens/homepage.dart';
import 'package:slideme/screens/monthly_budget.dart';
import 'package:slideme/screens/welcome.dart';
import 'package:slideme/screens/wrapper.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _getStartPage(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      // New user, no document yet → go to Welcome
      return const NamePage();
    }

    final data = doc.data() ?? {};

    // Username check
    if (!data.containsKey("username") || (data["username"] as String).isEmpty) {
      return const NamePage();
    }

    // Budget check
    if (!data.containsKey("monthlyBudget")) {
      return const NamePage(); // you already have this
    }

    // Category Budgets check
    if (!data.containsKey("categoryBudgets")) {
      return const CategoryBudgetPage();
    }

    // All fields exist → go to home
    return const MainPageWithSlider();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            return FutureBuilder<Widget>(
              future: _getStartPage(snapshot.data!),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(child: Text("Something went wrong"));
                }
                return snap.data!;
              },
            );
          } else {
            return SignUpPage(onTap: () {});
          }
        },
      ),
    );
  }
}

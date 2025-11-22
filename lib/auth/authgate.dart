import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:slideme/auth/age.dart';
import 'package:slideme/auth/country.dart';

import 'package:slideme/auth/signup.dart';
import 'package:slideme/auth/gphone.dart';
import 'package:slideme/screens/category.dart';
import 'package:slideme/screens/expensecategory.dart';
import 'package:slideme/screens/expensewrap.dart';
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
      return GPhoneInputPage(isAfterGoogleSignIn: true, userId: user.uid);
    }

    final data = doc.data() ?? {};

    // PHONE VERIFIED CHECK
    final phoneVerified = data['phoneVerified'] ?? false;
    if (!phoneVerified) {
      return GPhoneInputPage(isAfterGoogleSignIn: true, userId: user.uid);
    }

    // USERNAME
    if (!data.containsKey("username") || (data["username"] as String).isEmpty) {
      return const NamePage();
    }

    // AGE
    if (!data.containsKey("age") || data["age"] == null) {
      return AgePage(userName: data["username"]);
    }

    // COUNTRY
    if (!data.containsKey("country") || (data["country"] as String).isEmpty) {
      return CountryPage(userName: data["username"]);
    }

    // MODE CHECK
    // MODE CHECK
    if (!data.containsKey("mode")) {
      return const BudgetPage(); // fallback if mode missing
    }

    final String mode = data["mode"];

    if (mode == "budget") {
      // Only run budget flow
      if (!data.containsKey("monthlyBudget") || data["monthlyBudget"] == null) {
        return const BudgetPage();
      }

      if (!data.containsKey("categoryBudgets") ||
          data["categoryBudgets"] == null) {
        return const CategoryBudgetPage();
      }

      return const MainPageWithSlider();
    } else if (mode == "expense") {
      // Only run expense flow
      if (!data.containsKey("expenseCategories") ||
          data["expenseCategories"] == null) {
        return const ExpenseCategoryPage();
      }

      return const ExpensePageWithSlider();
    }

    // fallback
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

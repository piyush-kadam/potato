import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> sections = [
      {
        "title": "1. Overview",
        "content":
            "1.1 What We Do\nPotatoPay is a personal finance platform designed to help users manage expenses, create budgets, analyze spending patterns, and make smarter financial decisions. Users can track spending by category, create custom budgets, collaborate with friends & family, and access AI-powered insights.\n\n"
            "1.2 Changes to Terms\nPotatoPay may update these Terms periodically to reflect product improvements or regulatory compliance. Any major changes will be communicated through the app or email. Continued use of the platform means you accept the latest Terms.",
      },
      {
        "title": "2. Account Access & Responsibilities",
        "content":
            "You must create an account to use core features such as expense tracking, budget planning, AI insights, and shared dashboards.\n\n"
            "By registering, you agree to provide accurate and updated personal information.\n\n"
            "You are responsible for safeguarding your login credentials and activity within your account.\n\n"
            "PotatoPay may limit or suspend accounts that misuse features, violate security, or provide false information.",
      },
      {
        "title": "3. Expense Tracking & Budgeting",
        "content":
            "3.1 Adding Expenses\nTrack daily expenses by assigning categories such as Food, Travel, Shopping, Bills, etc. You may also create custom categories.\nReal-time insights will update your spending summary and analytics dashboard.\n\n"
            "3.2 Budget Mode\nBudget Mode enables users to set weekly or monthly spending limits per category. Alerts notify you when you're nearing or exceeding limits.\n\n"
            "3.3 Data Accuracy & Editing\nUsers are responsible for ensuring correct financial entries. Expenses and budgets can be edited or deleted unless locked for reporting.",
      },
      {
        "title": "4. Shared Dashboards & Group Finance",
        "content":
            "PotatoPay allows sharing dashboards with friends and family for group budgeting, bill splitting, and collective tracking.\n• You determine permissions such as view-only or edit access.\n• Shared groups must follow respectful and transparent financial behavior.\nPotatoPay may restrict groups that violate community safety or trust guidelines.",
      },
      {
        "title": "5. AI Insights & Assistance",
        "content":
            "PotatoPay includes an AI financial assistant that provides smart insights, budget recommendations, spending analysis, and predictive suggestions.\nThe chatbot may analyze expense history to improve accuracy and personalization.\nAI responses should be used as guidance and not as certified financial or legal advice.",
      },
      {
        "title": "6. Subscription & Payment",
        "content":
            "Some premium features such as advanced analytics, multi-group collaboration, and personalized AI recommendations may require subscription.\nPayments are securely processed through certified third-party gateways.\nPotatoPay does not store any card, UPI, or banking information internally.",
      },
      {
        "title": "7. Content & Usage Guidelines",
        "content":
            "Users agree not to:\n• Upload incorrect or misleading data\n• Use PotatoPay for fraudulent accounting or illegal activity\n• Share offensive, harmful, or abusive content within group dashboards\nPotatoPay may review and remove inappropriate content or restrict accounts accordingly.",
      },
      {
        "title": "8. Platform Availability",
        "content":
            "PotatoPay strives for smooth and reliable service, but we do not guarantee uninterrupted accessibility, real-time backups, or error-free operation at all times. Maintenance, upgrades, or network issues may temporarily limit functionality.",
      },
      {
        "title": "9. Limitation of Liability",
        "content":
            "PotatoPay is a financial tracking tool and not a registered financial advisory service. We are not responsible for:\n• Personal misuse or incorrect data entries\n• Losses due to financial decisions based on app analytics\n• Banking, payment gateway, or third-party service failures\nBy using the platform, you agree to hold PotatoPay harmless regarding such outcomes.",
      },
      {
        "title": "10. Termination",
        "content":
            "PotatoPay may suspend or terminate account access without notice for policy violations, fraudulent activity, or security breaches.",
      },
      {
        "title": "11. Governing Law",
        "content":
            "These Terms are governed by the laws of India. Any disputes shall be resolved under the exclusive jurisdiction of courts in Mumbai, Maharashtra.",
      },
      {
        "title": "12. Contact Us",
        "content":
            "For help or support, reach out at:\nPotatoPay Support\n📧 support@potatopay.in\n📍 Mumbai, Maharashtra – India",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Terms & Conditions",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
      ),
      backgroundColor: Colors.white,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: sections.length + 1, // extra item for footer
        separatorBuilder: (context, index) =>
            Divider(color: Colors.grey.withOpacity(0.2)),
        itemBuilder: (context, index) {
          if (index < sections.length) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sections[index]["title"]!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sections[index]["content"]!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

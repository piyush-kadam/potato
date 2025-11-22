import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportIssuePage extends StatelessWidget {
  const ReportIssuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> sections = [
      {
        "title": "Report an Issue — Potato Book",
        "content":
            "At Potato Book, we work hard to provide a smooth and reliable financial tracking experience. If something isn’t working as expected, we truly appreciate you taking the time to report it.\n\nYour report helps us fix issues faster and improve the app for everyone.",
      },
      {
        "title": "What You Can Report",
        "content":
            "You may report any of the following:\n\n"
            "• App crashes, freezing, or sudden shutdowns\n"
            "• Problems with adding, editing, or deleting entries\n"
            "• Issues with login or account access\n"
            "• Sync or backup issues\n"
            "• Incorrect or missing data\n"
            "• Design/UI layout errors\n"
            "• Notification issues\n"
            "• Performance slowdown\n"
            "• Any unusual or unexpected behavior\n\n"
            "If your concern relates to data privacy or security, please mention it so we can prioritize it.",
      },
      {
        "title": "What to Include in Your Report",
        "content":
            "Providing detailed information helps us resolve the issue much faster.\nPlease include:\n\n"
            "• A short description of the issue\n"
            "• The exact action you were performing\n"
            "• Steps to reproduce the issue\n"
            "• Screenshot or screen recording (if possible)\n"
            "• Your device model (e.g., iPhone 14, iPhone XR)\n"
            "• iOS version (e.g., iOS 17.2)\n"
            "• App version installed\n"
            "• Network type (WiFi / Mobile Data)",
      },
      {
        "title": "How to Contact Us",
        "content":
            "You can reach our support team through the following channel:\n\n"
            "📧 Email Support\npotatopayco@gmail.com\n\n"
            "Attach screenshots or screen recordings for faster diagnosis.",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Report an Issue",
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
        itemCount: sections.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.grey.withOpacity(0.2)),
        itemBuilder: (context, index) {
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
        },
      ),
    );
  }
}

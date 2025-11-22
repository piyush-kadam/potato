import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> sections = [
      {
        "title": "1. Company Information",
        "content":
            "Potato Book is a digital finance management application developed by Hyphen Corporation, a registered proprietorship based in India. The application provides tools to help individuals record, organize, and track their personal finances securely and efficiently.\n\nThese Terms govern your use of the Potato Book app and all related services offered by Hyphen Corporation.",
      },
      {
        "title": "2. Acceptance of Terms",
        "content":
            "By downloading, accessing, or using this app, you confirm that you:\n• Have read, understood, and agree to be bound by these Terms\n• Are legally capable of entering a binding contract\n• Are at least 18 years old, or using the app under supervision of a parent or guardian\n\nHyphen Corporation reserves the right to modify or update these Terms at any time without prior notice. Continued use of the app constitutes acceptance of revised Terms.",
      },
      {
        "title": "3. Use of the Application",
        "content":
            "You agree to use Potato Book solely for lawful and personal financial management purposes.\n\nYou must not:\n• Use the app for fraudulent or illegal activities\n• Interfere with or disrupt the app’s functionality\n• Attempt to reverse engineer, copy, or modify the app\n• Use the app to transmit malware or harmful content\n• Share false or misleading information\n\nHyphen Corporation may suspend or terminate accounts that violate these terms.",
      },
      {
        "title": "4. User Account & Security",
        "content":
            "To access certain features, you may be required to create an account.\nYou are responsible for:\n• Maintaining the confidentiality of login credentials\n• Providing accurate and up-to-date information\n• Notifying support immediately in case of unauthorized access\n\nHyphen Corporation is not liable for losses caused by failure to secure account access.",
      },
      {
        "title": "5. Data & Privacy",
        "content":
            "Your privacy is important to us. All personal information is handled in accordance with our Privacy Policy, which forms an integral part of these Terms.\n\nYou can review the full Privacy Policy at: _____",
      },
      {
        "title": "6. Intellectual Property Rights",
        "content":
            "All intellectual property in Potato Book—including the app design, features, content, and code—is owned or licensed by Hyphen Corporation.\nUsers are granted a limited, non-exclusive, non-transferable license for personal use.\n\nYou may not copy, distribute, or create derivative works from any part of the app without written permission.",
      },
      {
        "title": "7. Disclaimer of Warranties",
        "content":
            "Potato Book is provided on an 'as is' and 'as available' basis.\n\nWe do not guarantee that:\n• The app will always function without errors or interruptions\n• Data will always be accurate or up-to-date\n• Bugs or issues will be immediately fixed\n\nAll warranties, express or implied, are disclaimed including merchantability and fitness for a particular purpose.",
      },
      {
        "title": "8. Limitation of Liability",
        "content":
            "Hyphen Corporation is not liable for any direct, indirect, incidental, or consequential damages arising from:\n• Your use or inability to use the app\n• Data loss or corruption\n• Unauthorized account access\n• Technical failures\n\nYou agree that using the app is at your sole risk.",
      },
      {
        "title": "9. Third-Party Services",
        "content":
            "Potato Book may include integrations or links to third-party services. Hyphen Corporation is not responsible for their content, performance, or policies.\nUsers are encouraged to review third-party terms and privacy policies independently.",
      },
      {
        "title": "10. Termination",
        "content":
            "We may suspend or terminate your access to the app if:\n• You violate these terms\n• Your actions risk system security or other users\n• You misuse app data or features\n\nUpon termination, all rights granted to you under these terms end immediately.",
      },
      {
        "title": "11. Indemnification",
        "content":
            "You agree to indemnify and hold harmless Hyphen Corporation and affiliates against claims or losses arising from:\n• Violation of these terms\n• Misuse of the app\n• Infringement of rights or intellectual property.",
      },
      {
        "title": "12. Governing Law & Jurisdiction",
        "content":
            "These Terms are governed by the laws of India.\nAll legal disputes shall be under the exclusive jurisdiction of courts in Mainpuri, Uttar Pradesh.",
      },
      {
        "title": "13. Contact Information",
        "content":
            "Hyphen Corporation\nBuilding No./Flat No.: 1289\nIn front of Sardar Bant Singh Dhaba\nG.T. Road Highway, Bewar\nMainpuri, Uttar Pradesh – 205301\n\n📧 Email: potatopayco@gmail.com",
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

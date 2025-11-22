import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Privacy Policy",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: "Privacy Policy for Potato Book",
              content:
                  "Welcome to Potato Book, a finance management and fund-tracking application developed and owned by Hyphen Corporation. Your privacy is important to us, and this policy explains how we collect, use, store, and protect your information.",
            ),
            _divider(),
            _buildSection(
              title: "1. Company Information",
              content:
                  "Potato Book is a financial management application created by Hyphen Corporation, a registered proprietorship in India. The company develops digital tools designed to help users track expenses, manage funds, and organize financial activities with clarity and convenience.\n\n"
                  "We value transparency and follow responsible data handling practices to ensure user privacy and security.",
            ),
            _divider(),
            _buildSection(
              title: "2. Information We Collect",
              content:
                  "We collect information to provide and improve the app’s functionality.\n\n"
                  "2.1 Personal Information\n"
                  "• Name (if provided)\n"
                  "• Email address\n"
                  "• Phone number (optional)\n"
                  "• Login credentials\n"
                  "• Manually entered financial notes or categories\n\n"
                  "2.2 Financial Information\n"
                  "Potato Book allows users to manually enter their financial data. We do not access bank accounts or perform any automated financial operations.\n"
                  "Information you may choose to enter includes:\n"
                  "• Income records\n• Expenses\n• Savings or budget entries\n• User-added notes\n\n"
                  "2.3 Device & Usage Information\n"
                  "Automatically collected technical data may include:\n"
                  "• Device type and operating system\n"
                  "• IP address\n"
                  "• App performance analytics\n"
                  "• Crash logs or error reports",
            ),
            _divider(),
            _buildSection(
              title: "3. How We Use Your Information",
              content:
                  "We use the information you provide to:\n"
                  "• Enable core app functions\n"
                  "• Maintain account access\n"
                  "• Improve app performance and reliability\n"
                  "• Provide support and respond to inquiries\n"
                  "• Analyze general trends to enhance user experience\n"
                  "• Send notifications (only when permitted by the user)\n\n"
                  "We do not use your financial entries for advertising or profiling.",
            ),
            _divider(),
            _buildSection(
              title: "4. Data Storage & Security",
              content:
                  "We take appropriate security measures to protect your data against unauthorized access or misuse.\n\n"
                  "4.1 Data Storage\n"
                  "Your information may be stored securely in:\n"
                  "• Encrypted cloud servers\n"
                  "• Local device storage (depending on design)\n\n"
                  "4.2 Protection Measures\n"
                  "• Encrypted data transfer (SSL/HTTPS)\n"
                  "• Authentication safeguards\n"
                  "• Controlled access to data\n"
                  "• Regular monitoring for vulnerabilities\n\n"
                  "While no system is completely immune to security risks, we follow standard protective practices.",
            ),
            _divider(),
            _buildSection(
              title: "5. Sharing of Information",
              content:
                  "We do not sell or trade your personal data.\n\nInformation may be shared only under limited circumstances:\n\n"
                  "5.1 Service Providers\n"
                  "We may use trusted third-party services for:\n"
                  "• Hosting\n• Analytics\n• Crash reporting\n• Performance optimization\n"
                  "These partners follow strict confidentiality requirements.\n\n"
                  "5.2 Legal Requirements\n"
                  "We may disclose data if required by law, judicial process, or government authorities.",
            ),
            _divider(),
            _buildSection(
              title: "6. Your Rights",
              content:
                  "Depending on your region, you may have rights such as:\n"
                  "• Access to your data\n"
                  "• Correction of incorrect information\n"
                  "• Request for deletion\n"
                  "• Withdrawal of consent\n"
                  "• Restriction on processing\n"
                  "• Account closure\n\n"
                  "You may contact us to exercise any of these rights.",
            ),
            _divider(),
            _buildSection(
              title: "7. Data Retention",
              content:
                  "We retain information only as long as necessary for:\n"
                  "• Providing services\n"
                  "• Maintaining account operations\n"
                  "• Complying with legal obligations\n"
                  "• Security or troubleshooting purposes\n\n"
                  "You may request data deletion at any time.",
            ),
            _divider(),
            _buildSection(
              title: "8. Cookies & Tracking Technologies",
              content:
                  "The app may use:\n"
                  "• Local storage\n"
                  "• Tracking tools for performance enhancement\n\n"
                  "These technologies help improve functionality. Users may manage permissions through device settings.",
            ),
            _divider(),
            _buildSection(
              title: "9. Children’s Privacy",
              content:
                  "This app is not intended for users under the age of 13.\nWe do not knowingly collect personal data from children. If such data is identified, it will be removed promptly.",
            ),
            _divider(),
            _buildSection(
              title: "10. Third-Party Links",
              content:
                  "The app may contain links to third-party services.\nWe are not responsible for the privacy practices or content of these external platforms. Users should review third-party privacy policies before engaging with them.",
            ),
            _divider(),
            _buildSection(
              title: "11. Updates to This Policy",
              content:
                  "We may update this Privacy Policy from time to time.\nRevisions will be indicated by the 'Last Updated' date.\nContinued use of the app after updates constitutes acceptance of the revised policy.",
            ),
            _divider(),
            _buildSection(
              title: "12. Contact Information",
              content:
                  "For questions, feedback, or data-related requests, you may contact us at:\n\n"
                  "Hyphen Corporation\n"
                  "Building No./Flat No.: 1289\n"
                  "In front of Sardar Bant Singh Dhaba\n"
                  "G.T. Road Highway, Bewar\n"
                  "Mainpuri, Uttar Pradesh – 205301\n\n"
                  "Email: potatopayco@gmail.com",
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Hyphen Corporation',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSection({required String title, required String content}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        content,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.black,
          height: 1.5,
        ),
      ),
    ],
  );
}

Widget _divider() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    height: 1,
    color: Colors.grey.withOpacity(0.2),
  );
}

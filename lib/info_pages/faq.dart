import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<Map<String, dynamic>> _faqList = [
    {
      "question": "Is my financial data safe?",
      "answer":
          "Yes. We use encrypted storage and secure communication methods to protect your data. Your entries are stored safely, and we never share your personal or financial information with advertisers.",
      "isOpen": true,
    },
    {
      "question": "Does Potato Book connect to my bank?",
      "answer":
          "No. All financial entries are added manually by you. We do not access your bank accounts, bank credentials, or transaction history.",
      "isOpen": false,
    },
    {
      "question": "Can I use the app on multiple devices?",
      "answer":
          "Yes, as long as you log in with the same account credentials. Your data will sync securely.",
      "isOpen": false,
    },
    {
      "question": "What happens if I reinstall the app?",
      "answer":
          "Once you log in again, your entries will be restored automatically.",
      "isOpen": false,
    },
    {
      "question": "How do I delete my account?",
      "answer":
          "You can request account deletion by contacting us at: [Insert Support Email]. We will verify your request and delete your data upon confirmation.",
      "isOpen": false,
    },
    {
      "question": "Can I export my data?",
      "answer":
          "This depends on the version of the app. If enabled, you can export data through the account settings. If not, you may request export via email.",
      "isOpen": false,
    },
    {
      "question": "Why am I not receiving notifications?",
      "answer":
          "Ensure notifications are enabled in iOS settings, you are logged in, and your device is connected to the internet.",
      "isOpen": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff4A8C51);
    const bgColor = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,

        titleSpacing: 0,
        title: Text(
          "How can we help you?",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: primaryColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Search FAQs",
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: _faqList.length,
                itemBuilder: (context, index) {
                  final faq = _faqList[index];
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _faqList[index]["isOpen"] =
                                !_faqList[index]["isOpen"];
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  faq["question"],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              Icon(
                                faq["isOpen"]
                                    ? Icons.remove_circle_outline
                                    : Icons.add_circle_outline,
                                color: Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (faq["isOpen"])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            faq["answer"],
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade800,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      Divider(color: Colors.grey.shade300),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

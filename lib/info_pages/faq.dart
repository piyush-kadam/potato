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
      "question": "How do I add an expense or budget in PotatoPay?",
      "answer":
          "Go to the home screen and select either Expense or Budget mode. Add a category, enter an amount, and choose a date. PotatoPay automatically updates your summary and analytics in real-time.",
      "isOpen": true,
    },
    {
      "question":
          "What is the difference between Expense mode and Budget mode?",
      "answer":
          "Expense mode helps you track daily spending category-wise. Budget mode helps you plan monthly or weekly limits for categories like Food, Travel, Bills, and more — and alerts you before you overspend.",
      "isOpen": false,
    },
    {
      "question": "How does the AI chatbot help me manage finances?",
      "answer":
          "PotatoPay’s AI assistant analyzes your spending patterns, suggests saving tips, helps you set smarter budgets, and can answer financial queries instantly like ‘How much did I spend on food last month?’",
      "isOpen": false,
    },
    {
      "question": "Can I share my dashboard with friends or family?",
      "answer":
          "Yes! You can securely share your dashboard with selected contacts for split bills, shared expenses, or family finance tracking. You have full control over permissions and visibility.",
      "isOpen": false,
    },
    {
      "question": "How do categories work in PotatoPay?",
      "answer":
          "You can choose from built-in categories such as Food, Travel, Bills, Shopping, Health, etc. You can also create custom categories with icons and colors to personalize your tracking style.",
      "isOpen": false,
    },
    {
      "question": "What should I do if I face syncing or payment issues?",
      "answer":
          "If something doesn’t look right, contact support at support@potatopay.in or use the ‘Chat with Support’ button. Our team typically responds within a few hours.",
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

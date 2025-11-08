import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpensePayNowPopup extends StatefulWidget {
  final List<String> categories;

  const ExpensePayNowPopup({super.key, required this.categories});

  @override
  State<ExpensePayNowPopup> createState() => _ExpensePayNowPopupState();
}

class _ExpensePayNowPopupState extends State<ExpensePayNowPopup> {
  int currentStep = 0;
  int enteredAmount = 0;
  String? selectedCategory;
  String? paymentMethod;
  String currencySymbol = '₹'; // Default to Rupee
  bool isLoadingCurrency = true;
  final TextEditingController _amountController = TextEditingController();

  final Map<String, String> _currencyMap = {
    'India': '₹',
    'United States': '\$',
    'United Kingdom': '£',
    'Canada': 'C\$',
    'Australia': 'A\$',
    'Germany': '€',
    'France': '€',
    'Japan': '¥',
    'China': '¥',
    'Brazil': 'R\$',
    'Mexico': 'MX\$',
    'Spain': '€',
    'Italy': '€',
    'South Korea': '₩',
    'Singapore': 'S\$',
    'Netherlands': '€',
    'Sweden': 'kr',
    'Norway': 'kr',
    'Denmark': 'kr',
    'Switzerland': 'CHF',
    'Russia': '₽',
    'South Africa': 'R',
    'New Zealand': 'NZ\$',
    'Ireland': '€',
    'United Arab Emirates': 'د.إ',
    'Saudi Arabia': '﷼',
    'Turkey': '₺',
    'Argentina': 'AR\$',
    'Chile': 'CL\$',
    'Indonesia': 'Rp',
    'Thailand': '฿',
    'Philippines': '₱',
    'Vietnam': '₫',
    'Malaysia': 'RM',
    'Pakistan': '₨',
    'Bangladesh': '৳',
    'Nepal': '₨',
    'Sri Lanka': '₨',
    'Nigeria': '₦',
    'Kenya': 'KSh',
    'Egypt': 'E£',
    'Israel': '₪',
    'Portugal': '€',
    'Poland': 'zł',
    'Finland': '€',
    'Greece': '€',
    'Austria': '€',
    'Belgium': '€',
    'Czech Republic': 'Kč',
    'Hungary': 'Ft',
    'Romania': 'lei',
    'Colombia': 'COL\$',
    'Peru': 'S/',
    'Ukraine': '₴',
    'Morocco': 'د.م.',
    'Qatar': '﷼',
    'Kuwait': 'د.ك',
    'Oman': '﷼',
  };

  @override
  void initState() {
    super.initState();
    _fetchUserCurrency();
  }

  Future<void> _fetchUserCurrency() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final country = data?['country'] as String?;

        if (country != null && _currencyMap.containsKey(country)) {
          setState(() {
            currencySymbol = _currencyMap[country]!;
            isLoadingCurrency = false;
          });
        } else {
          setState(() {
            isLoadingCurrency = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching currency: $e");
      setState(() {
        isLoadingCurrency = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Extract emoji from category name
  String extractEmoji(String categoryName) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
      unicode: true,
    );
    final match = emojiRegex.firstMatch(categoryName);
    return match?.group(0) ?? '📦';
  }

  // Extract category name without emoji
  String extractCategoryName(String categoryName) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
      unicode: true,
    );
    return categoryName.replaceAll(emojiRegex, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenWidth - 32,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 20, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Green Circle Icon
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_card,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              "Pay Now",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentStep == 0
                  ? "Enter amount"
                  : currentStep == 1
                  ? "Select category"
                  : "Confirm payment",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= currentStep
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            // Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: IndexedStack(
                    index: currentStep,
                    sizing: StackFit.loose,
                    children: [
                      _buildAmountScreen(),
                      _buildCategoryScreen(),
                      _buildConfirmScreen(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: currentStep > 0
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => currentStep--),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4CAF50)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.arrow_back,
                                  size: 18,
                                  color: Color(0xFF4CAF50),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Back",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildContinueButton()),
                      ],
                    )
                  : _buildContinueButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        onPressed: _canProceed() ? () async => await _handleNext() : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currentStep == 2 ? "Confirm" : "Continue",
              style: GoogleFonts.poppins(
                color: _canProceed() ? Colors.white : Colors.grey[500],
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (currentStep < 2) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                color: _canProceed() ? Colors.white : Colors.grey[500],
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    if (currentStep == 0) return enteredAmount > 0;
    if (currentStep == 1) return selectedCategory != null;
    if (currentStep == 2) return paymentMethod != null;
    return false;
  }

  Future<void> _handleNext() async {
    if (currentStep == 0) {
      FocusScope.of(context).unfocus();
    }

    if (currentStep < 2) {
      setState(() => currentStep++);
    } else {
      await _processPayment();
    }
  }

  Future<void> _processPayment() async {
    if (selectedCategory == null ||
        enteredAmount <= 0 ||
        paymentMethod == null) {
      print("❌ Missing required fields");
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = FirebaseFirestore.instance
          .collection("Users")
          .doc(userId);

      print("🔄 Fetching user document...");
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        print("❌ User document doesn't exist");
        return;
      }

      final data = snapshot.data()!;

      // Get current spent amounts
      Map<String, int> categorySpent = {};
      if (data['categorySpent'] != null) {
        final rawSpent = data['categorySpent'] as Map<String, dynamic>;
        rawSpent.forEach((key, value) {
          if (value is int) {
            categorySpent[key] = value;
          } else if (value is double) {
            categorySpent[key] = value.toInt();
          } else {
            categorySpent[key] = int.tryParse(value.toString()) ?? 0;
          }
        });
      }

      print("💸 Expense category spent: $categorySpent");
      print("💸 Payment amount: $enteredAmount");
      print("📂 Selected category: $selectedCategory");

      // Add payment to category
      int alreadySpentInCategory = categorySpent[selectedCategory] ?? 0;
      Map<String, int> updatedExpenseCategorySpent = Map.from(categorySpent);
      updatedExpenseCategorySpent[selectedCategory!] =
          alreadySpentInCategory + enteredAmount;

      // Close popup immediately (UI feedback)
      Navigator.pop(context, {
        "success": true,
        "amount": enteredAmount,
        "category": selectedCategory,
        "paymentMethod": paymentMethod,
      });

      // Wait a short delay before updating Firestore
      await Future.delayed(const Duration(seconds: 1));

      // Update user data
      await userDoc.update({
        'categorySpent': updatedExpenseCategorySpent,
        'remainingBudget': (data['remainingBudget'] ?? 0) - enteredAmount,
        'transactions': (data['transactions'] ?? 0) + 1,
      });

      print("✅ User document updated!");

      // Add to Transactions Subcollection
      final transactionRef = userDoc.collection('transactions').doc();

      final now = DateTime.now();
      final timestampMs = now.millisecondsSinceEpoch;

      await transactionRef.set({
        "amount": enteredAmount,
        "category": selectedCategory,
        "paymentMethod": paymentMethod,
        "date": Timestamp.fromDate(now),
        "timestamp": timestampMs,
        "userId": userId,
      });

      print("🧾 Transaction added to subcollection successfully!");
    } catch (e) {
      print("❌ Error processing payment: $e");
      _showError("Failed to process payment: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildAmountScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Credit card icon
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.credit_card, size: 32, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Text(
          "How much?",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Enter the payment amount",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 60, top: 20),
                child: Text(
                  "$currencySymbol ",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              hintText: "5000",
              hintStyle: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            onChanged: (value) {
              setState(() => enteredAmount = int.tryParse(value) ?? 0);
            },
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCategoryScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Box icon
        const Text("📦", style: TextStyle(fontSize: 22)),
        Text(
          "Which category?",
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Select where this payment belongs",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: widget.categories.map((category) {
            bool isSelected = category == selectedCategory;
            String emoji = extractEmoji(category);
            String categoryName = extractCategoryName(category);

            return GestureDetector(
              onTap: () => setState(() => selectedCategory = category),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF4CAF50), width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      categoryName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildConfirmScreen() {
    String emoji = extractEmoji(selectedCategory ?? "");
    String categoryName = extractCategoryName(
      selectedCategory ?? "No category",
    );
    bool isIndia = currencySymbol == '₹';
    String digitalPaymentLabel = isIndia ? "UPI" : "Digital";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 38)),
        Text(
          "$currencySymbol${enteredAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          categoryName,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _paymentMethodButton(
                digitalPaymentLabel,
                "📱",
                "Quick Pay",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _paymentMethodButton("Cash", "💵", "Manual")),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _paymentMethodButton(String method, String emoji, String subtitle) {
    bool isSelected = paymentMethod == method;

    return GestureDetector(
      onTap: () => setState(() => paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              method,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.black,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AllTransactionsPage extends StatefulWidget {
  final String? initialCategory;
  final Map<String, int>? categoryBudgets; // Made optional

  const AllTransactionsPage({
    super.key,
    this.initialCategory,
    this.categoryBudgets, // No longer required
  });

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  String selectedMonth = "All";
  String selectedCategory = "All";
  List<String> availableCategories = ["All"]; // Store fetched categories
  bool _isLoadingCategories = true;

  final List<String> months = [
    "All",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      selectedCategory = widget.initialCategory!;
    }
    // Only fetch categories if categoryBudgets is not provided
    if (widget.categoryBudgets == null) {
      _fetchCategoriesFromDB();
    } else {
      _isLoadingCategories = false;
    }
  }

  Future<void> _fetchCategoriesFromDB() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final expenseCategories = data['expenseCategories'] as List<dynamic>?;

        if (expenseCategories != null && expenseCategories.isNotEmpty) {
          setState(() {
            availableCategories = ["All", ...expenseCategories.cast<String>()];
            _isLoadingCategories = false;
          });
        } else {
          setState(() {
            availableCategories = ["All"];
            _isLoadingCategories = false;
          });
        }
      } else {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  List<String> get categoryOptions {
    // If categoryBudgets is provided (budget mode), use it
    if (widget.categoryBudgets != null) {
      List<String> categories = ["All"];
      categories.addAll(widget.categoryBudgets!.keys);
      return categories;
    }
    // Otherwise use fetched categories from expenseCategories (expense mode)
    return availableCategories;
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    if (selectedCategory != "All") {
      final transactionCategory = data['category'] as String?;
      if (transactionCategory != selectedCategory) {
        return false;
      }
    }
    if (selectedMonth != "All") {
      final timestamp = data['date'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        final monthIndex = months.indexOf(selectedMonth);
        if (date.month != monthIndex) {
          return false;
        }
      }
    }
    return true;
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown date";
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours > 0) {
        return "${difference.inHours}h ago";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes}m ago";
      } else {
        return "Just now";
      }
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else {
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${monthNames[date.month - 1]} ${date.day}, ${date.year}";
    }
  }

  String _getMethodIcon(String method) {
    if (method.toLowerCase().contains("cash")) return "💵";
    if (method.toLowerCase().contains("upi")) return "📱";
    if (method.toLowerCase().contains("card")) return "💳";
    return "💳";
  }

  String _extractEmoji(String categoryKey) {
    final match = RegExp(
      r'^(\p{Emoji})',
      unicode: true,
    ).firstMatch(categoryKey);
    return match?.group(0) ?? "📦";
  }

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
          "All Transactions",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoadingCategories
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedMonth,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              items: months.map((String month) {
                                return DropdownMenuItem<String>(
                                  value: month,
                                  child: Text(month),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedMonth = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              items: categoryOptions.map((String category) {
                                String displayText = category;
                                if (category != "All") {
                                  displayText = category.replaceFirst(
                                    RegExp(r'^(\p{Emoji}\s*)', unicode: true),
                                    '',
                                  );
                                }
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(
                                    displayText,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCategory = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("Users")
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection("transactions")
                        .orderBy("timestamp", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4CAF50),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("⚠️", style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                "Error loading transactions",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("💸", style: TextStyle(fontSize: 64)),
                              const SizedBox(height: 16),
                              Text(
                                "No transactions yet",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Your transactions will appear here",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final filteredTransactions = snapshot.data!.docs.where((
                        doc,
                      ) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _matchesFilters(data);
                      }).toList();

                      if (filteredTransactions.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("🔍", style: TextStyle(fontSize: 64)),
                              const SizedBox(height: 16),
                              Text(
                                "No transactions found",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Try adjusting your filters",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      Map<String, List<QueryDocumentSnapshot>>
                      groupedTransactions = {};
                      for (var doc in filteredTransactions) {
                        final data = doc.data() as Map<String, dynamic>;
                        final timestamp = data['date'] as Timestamp?;
                        String dateKey = "Unknown";
                        if (timestamp != null) {
                          final date = timestamp.toDate();
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final transactionDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          if (transactionDate == today) {
                            dateKey = "Today";
                          } else if (transactionDate ==
                              today.subtract(const Duration(days: 1))) {
                            dateKey = "Yesterday";
                          } else {
                            final monthNames = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec',
                            ];
                            dateKey =
                                "${monthNames[date.month - 1]} ${date.day}, ${date.year}";
                          }
                        }
                        if (!groupedTransactions.containsKey(dateKey)) {
                          groupedTransactions[dateKey] = [];
                        }
                        groupedTransactions[dateKey]!.add(doc);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedTransactions.length,
                        itemBuilder: (context, index) {
                          final dateKey = groupedTransactions.keys.elementAt(
                            index,
                          );
                          final transactions = groupedTransactions[dateKey]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  dateKey,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              ...transactions.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final amount = data['amount'] as int? ?? 0;
                                final category =
                                    data['category'] as String? ?? "Unknown";
                                final method =
                                    data['paymentMethod'] as String? ??
                                    "Payment";
                                final timestamp = data['date'] as Timestamp?;
                                final categoryEmoji = _extractEmoji(category);
                                final methodIcon = _getMethodIcon(method);
                                final formattedTime = _formatDate(timestamp);

                                final DateTime transactionDate =
                                    timestamp?.toDate() ?? DateTime.now();
                                final DateTime now = DateTime.now();
                                final bool isCurrentMonth =
                                    now.year == transactionDate.year &&
                                    now.month == transactionDate.month;

                                return Dismissible(
                                  key: Key(doc.id),
                                  direction: isCurrentMonth
                                      ? DismissDirection.endToStart
                                      : DismissDirection.none,
                                  confirmDismiss: (_) async {
                                    if (!isCurrentMonth) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Only current month transactions can be deleted.",
                                          ),
                                        ),
                                      );
                                      return false;
                                    }
                                    return await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Delete Transaction?'),
                                        content: Text(
                                          'Are you sure you want to delete this transaction? The category spend will be updated.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (_) async {
                                    final userDoc = FirebaseFirestore.instance
                                        .collection("Users")
                                        .doc(
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                        );
                                    final String catKey = category;
                                    final categorySpentPath =
                                        "categorySpent.$catKey";
                                    await userDoc.update({
                                      categorySpentPath: FieldValue.increment(
                                        -amount,
                                      ),
                                    });
                                    await userDoc
                                        .collection("transactions")
                                        .doc(doc.id)
                                        .delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Transaction deleted and category spend updated.",
                                        ),
                                      ),
                                    );
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F9F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF4CAF50,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              categoryEmoji,
                                              style: const TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                category.replaceFirst(
                                                  RegExp(
                                                    r'^(\p{Emoji}\s*)',
                                                    unicode: true,
                                                  ),
                                                  '',
                                                ),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    methodIcon,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "$method • $formattedTime",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          "₹${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

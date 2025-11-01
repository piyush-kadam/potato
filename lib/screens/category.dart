import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slideme/screens/homepage.dart';
import 'package:slideme/screens/wrapper.dart';

class CategoryBudgetPage extends StatefulWidget {
  const CategoryBudgetPage({super.key});

  @override
  State<CategoryBudgetPage> createState() => _CategoryBudgetPageState();
}

class _CategoryBudgetPageState extends State<CategoryBudgetPage> {
  double _monthlyBudget = 0;
  String _currencySymbol = '₹';
  String _countryCode = 'IN';

  Map<String, double> _categories = {
    "🍔 Food": 0,
    "🛍️ Shopping": 0,
    "✈️ Travel": 0,
    "🎬 Entertainment": 0,
    "💰 Savings": 0,
  };

  bool _loading = true;

  final Map<String, double> _defaultWeights = {
    "Food": 0.30,
    "Shopping": 0.20,
    "Travel": 0.15,
    "Entertainment": 0.10,
    "Savings": 0.25,
  };

  final Map<String, String> _currencyMap = {
    'IN': '₹',
    'US': '\$',
    'GB': '£',
    'EU': '€',
    'JP': '¥',
    'AU': 'A\$',
    'CA': 'C\$',
  };

  @override
  void initState() {
    super.initState();
    _fetchBudget();
  }

  Future<void> _fetchBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;

      // Fetch country code and set currency
      if (data["country"] != null) {
        setState(() {
          _countryCode = data["country"];
          _currencySymbol = _currencyMap[_countryCode] ?? '₹';
        });
      }

      if (data["monthlyBudget"] != null) {
        setState(() {
          _monthlyBudget = (data["monthlyBudget"]).toDouble();
        });
      }

      if (data["categoryBudgets"] != null && data["categoryBudgets"] is Map) {
        final Map saved = Map<String, dynamic>.from(data["categoryBudgets"]);
        final newMap = <String, double>{};
        for (var e in saved.entries) {
          newMap[e.key as String] = (saved[e.key] as num).toDouble();
        }
        for (var key in _categories.keys) {
          if (!newMap.containsKey(key)) newMap[key] = 0;
        }
        setState(() {
          _categories = newMap;
        });
      }
    }

    setState(() => _loading = false);
  }

  double get _allocated =>
      _categories.values.fold(0.0, (sum, value) => sum + value);

  double get _remaining => _monthlyBudget - _allocated;

  bool get _isBudgetAllocated => _allocated > 0 && _remaining >= 0;

  String? _matchBaseName(String key) {
    final low = key.toLowerCase();
    for (var base in _defaultWeights.keys) {
      if (low.contains(base.toLowerCase())) return base;
    }
    return null;
  }

  void _autoSetBudgets() {
    if (_monthlyBudget <= 0) return;

    final keys = _categories.keys.toList();
    final baseKeys = <String>[];
    final newKeys = <String>[];
    final Map<String, String> keyToBase = {};

    for (var k in keys) {
      final base = _matchBaseName(k);
      if (base != null) {
        baseKeys.add(k);
        keyToBase[k] = base;
      } else {
        newKeys.add(k);
      }
    }

    final int baseCount = baseKeys.length;
    final int newCount = newKeys.length;

    if (baseCount == 0) {
      final int budgetInt = _monthlyBudget.round();
      final rawPer = _monthlyBudget / keys.length;
      final Map<String, double> raw = {for (var k in keys) k: rawPer};
      _applyRoundingAndSet(raw, budgetInt);
      return;
    }

    double W_base = 0.0;
    for (var bk in baseKeys) {
      final baseName = keyToBase[bk]!;
      W_base += _defaultWeights[baseName]!;
    }

    final double newTotalShare = (newCount == 0)
        ? 0.0
        : W_base * (newCount / (baseCount + newCount));
    final double baseScale =
        (W_base - newTotalShare) / (W_base == 0 ? 1 : W_base);

    final Map<String, double> rawAlloc = {};
    for (var bk in baseKeys) {
      final baseName = keyToBase[bk]!;
      final double weight = _defaultWeights[baseName]! * baseScale;
      rawAlloc[bk] = weight * _monthlyBudget;
    }

    if (newCount > 0) {
      final double perNewWeight = (W_base / (baseCount + newCount));
      for (var nk in newKeys) {
        rawAlloc[nk] = (perNewWeight) * _monthlyBudget;
      }
    }

    for (var k in keys) {
      rawAlloc.putIfAbsent(k, () => 0.0);
    }

    final int budgetInt = _monthlyBudget.round();
    _applyRoundingAndSet(rawAlloc, budgetInt);
  }

  void _applyRoundingAndSet(Map<String, double> rawAlloc, int budgetInt) {
    final Map<String, int> floored = {};
    final Map<String, double> fractions = {};
    int sumFloor = 0;

    rawAlloc.forEach((k, v) {
      final int f = v.floor();
      floored[k] = f;
      fractions[k] = v - f;
      sumFloor += f;
    });

    int remaining = budgetInt - sumFloor;
    final sortedByFraction = fractions.keys.toList()
      ..sort((a, b) => fractions[b]!.compareTo(fractions[a]!));

    int idx = 0;
    while (remaining > 0) {
      final k = sortedByFraction[idx % sortedByFraction.length];
      floored[k] = floored[k]! + 1;
      remaining--;
      idx++;
    }

    while (remaining < 0) {
      final sortedAsc = fractions.keys.toList()
        ..sort((a, b) => fractions[a]!.compareTo(fractions[b]!));
      final k = sortedAsc[0];
      if (floored[k]! > 0) {
        floored[k] = floored[k]! - 1;
        remaining++;
      } else {
        break;
      }
    }

    setState(() {
      floored.forEach((k, v) {
        _categories[k] = v.toDouble();
      });
    });
  }

  void _openCategoryDialog(String category) {
    final TextEditingController controller = TextEditingController(
      text: _categories[category]!.round().toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(category, style: GoogleFonts.poppins(fontSize: 20)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: "$_currencySymbol ",
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text) ?? 0;
                if (val >= 0 && val <= _monthlyBudget) {
                  setState(() {
                    _categories[category] = val;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Set"),
            ),
          ],
        );
      },
    );
  }

  void _addNewCategory() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emojiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(hintText: "Emoji (e.g. 🍕)"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "Category name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () {
                final emoji = emojiController.text.trim();
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final key = (emoji.isEmpty) ? name : "$emoji $name";

                var newKey = key;
                int i = 1;
                while (_categories.containsKey(newKey)) {
                  newKey = "$key ($i)";
                  i++;
                }

                setState(() {
                  _categories[newKey] = 0;
                });
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveBudgets() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("Users").doc(user.uid).set({
      "categoryBudgets": _categories,
      "remainingBudget": _monthlyBudget,
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPageWithSlider()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMoreThanSixCategories = _categories.length >= 6;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/bg.png', fit: BoxFit.cover),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          "Set Category Budgets",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap categories to allocate your budget",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Expanded(
                          child: GridView.count(
                            physics: hasMoreThanSixCategories
                                ? const AlwaysScrollableScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.0,
                            children: [
                              ..._categories.keys.map((category) {
                                return GestureDetector(
                                  onTap: () => _openCategoryDialog(category),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.6),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          category.split(" ").first,
                                          style: const TextStyle(fontSize: 42),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          category.substring(
                                            category.indexOf(" ") + 1,
                                          ),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$_currencySymbol${_categories[category]!.round()}k",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList()..add(
                                GestureDetector(
                                  onTap: _addNewCategory,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 42,
                                          color: Colors.black.withOpacity(0.7),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Add",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Summary card
                        /// Summary card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _summaryItem(
                                "Total",
                                "$_currencySymbol${(_monthlyBudget / 1000).toStringAsFixed(0)}k",
                                Colors.black87,
                              ),
                              _summaryItem(
                                "Allocated",
                                "$_currencySymbol${(_allocated / 1000).toStringAsFixed(0)}k",
                                Colors.blue,
                              ),
                              _summaryItem(
                                "Remaining",
                                "$_currencySymbol${(_remaining / 1000).toStringAsFixed(0)}k",
                                Colors.green,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.25),
                                      Colors.white.withOpacity(0.15),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _autoSetBudgets,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            size: 18,
                                            color: Colors.yellow,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Auto-set",
                                            style: GoogleFonts.poppins(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isBudgetAllocated
                                    ? _saveBudgets
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isBudgetAllocated
                                      ? const Color(0xff4A8C51)
                                      : Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: _isBudgetAllocated ? 4 : 0,
                                ),
                                child: const Text(
                                  "START!",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddCategoryPopup extends StatefulWidget {
  final int remainingBudget;
  final Map<String, int> categoryBudgets;

  const AddCategoryPopup({
    super.key,
    required this.remainingBudget,
    required this.categoryBudgets,
  });

  @override
  State<AddCategoryPopup> createState() => _AddCategoryPopupState();
}

class _AddCategoryPopupState extends State<AddCategoryPopup> {
  final TextEditingController _emojiController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool _showCustomForm = false;
  String? _selectedQuickCategory;

  final List<Map<String, String>> quickCategories = [
    {'emoji': '🍔', 'name': 'Food', 'color': 'orange'},
    {'emoji': '🛍️', 'name': 'Shopping', 'color': 'blue'},
    {'emoji': '✈️', 'name': 'Travel', 'color': 'purple'},
    {'emoji': '🎬', 'name': 'Entertainment', 'color': 'pink'},
    {'emoji': '💰', 'name': 'Savings', 'color': 'yellow'},
    {'emoji': '🚗', 'name': 'Transport', 'color': 'red'},
    {'emoji': '📱', 'name': 'Bills', 'color': 'indigo'},
    {'emoji': '🏥', 'name': 'Health', 'color': 'green'},
  ];

  Color _getCategoryColor(String colorName) {
    switch (colorName) {
      case 'orange':
        return Colors.orange.shade100;
      case 'blue':
        return Colors.blue.shade100;
      case 'purple':
        return Colors.purple.shade100;
      case 'pink':
        return Colors.pink.shade100;
      case 'yellow':
        return Colors.yellow.shade100;
      case 'red':
        return Colors.red.shade100;
      case 'indigo':
        return Colors.indigo.shade100;
      case 'green':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Add New Category",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),

                Text(
                  "Create a new spending category to organize your budget",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 16),

                // Remaining Budget
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "₹${widget.remainingBudget} remaining",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (!_showCustomForm) ...[
                  Text(
                    "Quick Categories",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: quickCategories.length,
                    itemBuilder: (context, index) {
                      final category = quickCategories[index];
                      final isSelected =
                          _selectedQuickCategory == category['name'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedQuickCategory = isSelected
                                ? null
                                : category['name'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade100
                                : _getCategoryColor(category['color']!),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade300
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                category['emoji']!,
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: Text(
                                  category['name']!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showCustomForm = true;
                          _selectedQuickCategory = null;
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: Text(
                        "Create Custom Category",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],

                if (_showCustomForm) ...[
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showCustomForm = false;
                            _emojiController.clear();
                            _nameController.clear();
                          });
                        },
                        icon: const Icon(Icons.arrow_back, size: 20),
                      ),
                      Text(
                        "Create Custom Category",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    "Emoji",
                    _emojiController,
                    hint: "Enter an emoji (e.g., 🎯)",
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    "Category Name",
                    _nameController,
                    hint: "Enter category name",
                  ),
                ],

                if (_selectedQuickCategory != null || _showCustomForm) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    "Budget Amount",
                    _amountController,
                    hint: "0",
                    prefix: "₹ ",
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleAddCategory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Add Category",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: prefix != null
              ? TextInputType.number
              : TextInputType.text,
          decoration: InputDecoration(
            prefixText: prefix,
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _handleAddCategory() {
    int amount = int.tryParse(_amountController.text) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please enter a valid amount")));
      return;
    }

    if (amount > widget.remainingBudget) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Amount exceeds remaining budget")),
      );
      return;
    }

    String emoji = "";
    String name = "";

    if (_selectedQuickCategory != null) {
      final selectedCat = quickCategories.firstWhere(
        (cat) => cat['name'] == _selectedQuickCategory,
      );
      emoji = selectedCat['emoji']!;
      name = selectedCat['name']!;
    } else if (_showCustomForm) {
      emoji = _emojiController.text.trim();
      name = _nameController.text.trim();
      if (emoji.isEmpty || name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please fill in both emoji and category name"),
          ),
        );
        return;
      }
    }

    Map<String, int> updatedBudgets = {};
    int totalExisting = widget.categoryBudgets.values.fold(0, (a, b) => a + b);

    widget.categoryBudgets.forEach((key, value) {
      double ratio = totalExisting > 0 ? value / totalExisting : 0;
      int deduction = (amount * ratio).round();
      updatedBudgets[key] = value - deduction;
    });

    updatedBudgets["$emoji $name"] = amount;

    Navigator.pop(context, updatedBudgets);
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

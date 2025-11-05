import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String _selectedPlan = '12'; // Default selection

  Package? _selectedPackage;
  Offerings? _offerings;

  final Map<String, Color> planColors = {
    '30': Colors.green,
    '12': Colors.redAccent,
    'lifetime': Colors.amber,
  };

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    try {
      _offerings = await Purchases.getOfferings();
      _updateSelectedPackage();
    } catch (e) {
      print("Error fetching offerings: $e");
    }
  }

  void _updateSelectedPackage() {
    if (_offerings == null) return;

    if (_selectedPlan == '30' && _offerings?.current?.monthly != null) {
      _selectedPackage = _offerings!.current!.monthly;
    } else if (_selectedPlan == '12' && _offerings?.current?.annual != null) {
      _selectedPackage = _offerings!.current!.annual;
    } else if (_selectedPlan == 'lifetime' &&
        _offerings?.current?.lifetime != null) {
      _selectedPackage = _offerings!.current!.lifetime;
    } else {
      _selectedPackage = null;
    }
    setState(() {});
  }

  Future<void> _onSubscribe() async {
    if (_selectedPackage == null) {
      print('No package selected');
      return;
    }
    try {
      await Purchases.purchasePackage(_selectedPackage!);
      // TODO: Show success UI or unlock features
      print('Purchase Successful');
    } catch (e) {
      print('Purchase failed: $e');
      // TODO: Show error to user if necessary
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = planColors[_selectedPlan]!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87, size: 26),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/mascot3.png',
                      width: 120,
                      height: 130,
                    ),
                    Text(
                      "MyPotato Pro",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildPlanCard(
                              title: "30",
                              subtitle: "DAYS",
                              price: "₹149",
                              color: planColors['30']!,
                              isSelected: _selectedPlan == '30',
                              onTap: () {
                                setState(() {
                                  _selectedPlan = '30';
                                  _updateSelectedPackage();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPlanCard(
                              title: "12",
                              subtitle: "Months",
                              price: "₹999",
                              color: planColors['12']!,
                              isSelected: _selectedPlan == '12',
                              onTap: () {
                                setState(() {
                                  _selectedPlan = '12';
                                  _updateSelectedPackage();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPlanCard(
                              title: "∞",
                              subtitle: "LIFETIME",
                              price: "₹1999",
                              color: planColors['lifetime']!,
                              isSelected: _selectedPlan == 'lifetime',
                              onTap: () {
                                setState(() {
                                  _selectedPlan = 'lifetime';
                                  _updateSelectedPackage();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: selectedColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _onSubscribe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Subscribe",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Cancel anytime",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required String price,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 140,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                letterSpacing: 0.5,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

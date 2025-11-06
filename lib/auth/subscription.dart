import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  Offerings? _offerings;
  Package? _selectedPackage;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      print('Offerings fetched: ${offerings.all.keys}');
      if (offerings.current != null) {
        print('Current offering: ${offerings.current!.identifier}');
        for (var pkg in offerings.current!.availablePackages) {
          print(
            'Package: ${pkg.identifier}, Product: ${pkg.storeProduct.identifier}',
          );
        }
      }

      if (offerings.current?.availablePackages.isNotEmpty ?? false) {
        // Find the monthly package as default selection (middle option with "Save 45%")
        Package? defaultPackage;
        for (var pkg in offerings.current!.availablePackages) {
          if (pkg.packageType == PackageType.monthly ||
              pkg.identifier.toLowerCase().contains('month')) {
            defaultPackage = pkg;
            break;
          }
        }

        setState(() {
          _offerings = offerings;
          _selectedPackage =
              defaultPackage ?? offerings.current!.availablePackages.first;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching offerings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onPurchase() async {
    if (_selectedPackage == null || _isPurchasing) return;

    setState(() => _isPurchasing = true);

    try {
      CustomerInfo customerInfo =
          (await Purchases.purchasePackage(_selectedPackage!)) as CustomerInfo;

      // Check if the purchase was successful
      if (customerInfo.entitlements.all.isNotEmpty) {
        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to MyPotato Pro! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back after a short delay
        await Future.delayed(Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Purchase failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase cancelled or failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  String _getPackageLabel(Package package) {
    if (package.packageType == PackageType.lifetime) {
      return 'LIFETIME';
    } else if (package.packageType == PackageType.annual) {
      return 'MONTHS';
    } else if (package.packageType == PackageType.monthly) {
      return 'MONTHS';
    }

    // Fallback based on identifier
    String id = package.identifier.toLowerCase();
    if (id.contains('lifetime')) return 'LIFETIME';
    if (id.contains('year') || id.contains('annual')) return 'MONTHS';
    if (id.contains('month')) return 'MONTHS';

    return 'DAYS';
  }

  String _getPackageDuration(Package package) {
    if (package.packageType == PackageType.lifetime) {
      return '∞';
    } else if (package.packageType == PackageType.annual) {
      return '12';
    } else if (package.packageType == PackageType.monthly) {
      return '12';
    }

    // Fallback
    String id = package.identifier.toLowerCase();
    if (id.contains('lifetime')) return '∞';
    if (id.contains('year') || id.contains('annual')) return '12';
    if (id.contains('month')) return '12';

    return '30';
  }

  bool _shouldShowBadge(Package package) {
    // Show "Save 45%" badge on monthly/annual packages (middle option)
    return package.packageType == PackageType.monthly ||
        package.packageType == PackageType.annual;
  }

  Color _getPackageColor(Package package, bool isSelected) {
    if (!isSelected) {
      return Colors.white;
    }

    if (package.packageType == PackageType.lifetime) {
      return const Color(0xFFFFC107); // Yellow/Gold
    } else if (package.packageType == PackageType.annual ||
        package.packageType == PackageType.monthly) {
      return const Color(0xFFFF6B6B); // Coral/Red
    }

    return const Color(0xFF4CAF50); // Green for default
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Background decorative circles
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE8F5E9).withOpacity(0.5),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: -80,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF9C4).withOpacity(0.5),
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      // Close button
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.grey[700],
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Mascot
                      Container(
                        width: 140,
                        height: 140,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB2DFDB),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/mascot3.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.local_fire_department,
                                size: 80,
                                color: Colors.orange,
                              ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: 'MyPotato ',
                              style: TextStyle(color: const Color(0xFFFF6B6B)),
                            ),
                            TextSpan(
                              text: 'Pro',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Subscription options
                      if (_offerings?.current?.availablePackages != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _offerings!.current!.availablePackages.map((
                              package,
                            ) {
                              final isSelected =
                                  package.identifier ==
                                  _selectedPackage?.identifier;
                              final packageColor = _getPackageColor(
                                package,
                                isSelected,
                              );
                              final showBadge = _shouldShowBadge(package);

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPackage = package;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          height: 140,
                                          decoration: BoxDecoration(
                                            color: packageColor,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? packageColor
                                                  : Colors.grey.shade300,
                                              width: isSelected ? 3 : 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isSelected
                                                    ? packageColor.withOpacity(
                                                        0.3,
                                                      )
                                                    : Colors.black.withOpacity(
                                                        0.05,
                                                      ),
                                                blurRadius: isSelected ? 15 : 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _getPackageDuration(package),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                _getPackageLabel(package),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black54,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                package
                                                    .storeProduct
                                                    .priceString,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (showBadge)
                                          Positioned(
                                            top: -12,
                                            left: 0,
                                            right: 0,
                                            child: Center(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  'Save 45%',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFFFF6B6B,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 40),

                      // Subscribe button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isPurchasing ? null : _onPurchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedPackage != null
                                  ? _getPackageColor(_selectedPackage!, true)
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 8,
                              shadowColor: _selectedPackage != null
                                  ? _getPackageColor(
                                      _selectedPackage!,
                                      true,
                                    ).withOpacity(0.4)
                                  : Colors.grey.withOpacity(0.4),
                            ),
                            child: _isPurchasing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Subscribe',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Cancel anytime text
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: Text(
                          'Cancel anytime',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

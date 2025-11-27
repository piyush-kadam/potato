import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';

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
      print('RevenueCat: Offerings object: $offerings');

      print('RevenueCat: offerings.all keys = ${offerings.all.keys}');
      offerings.all.forEach((k, v) {
        print(
          'Offering key: $k, identifier: ${v.identifier}, packages: ${v.availablePackages.length}',
        );
      });

      Offering? chosenOffering = offerings.current;
      if (chosenOffering == null && offerings.all.isNotEmpty) {
        chosenOffering = offerings.all.values.first;
        print(
          'RevenueCat: current offering is null — falling back to ${chosenOffering.identifier}',
        );
      }

      if (chosenOffering != null &&
          chosenOffering.availablePackages.isNotEmpty) {
        for (var pkg in chosenOffering.availablePackages) {
          print(
            'RevenueCat: package -> ${pkg.identifier} (${pkg.packageType}) productId=${pkg.storeProduct.identifier}',
          );
        }

        setState(() {
          _offerings = offerings;
          _selectedPackage = chosenOffering!.availablePackages.first;
          _isLoading = false;
        });
      } else {
        print('RevenueCat: No packages available in chosen offering.');
        setState(() => _isLoading = false);
      }
    } catch (e, st) {
      print('Error fetching offerings: $e\n$st');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onPurchase() async {
    if (_selectedPackage == null || _isPurchasing) return;

    setState(() => _isPurchasing = true);

    try {
      CustomerInfo customerInfo =
          (await Purchases.purchasePackage(_selectedPackage!)) as CustomerInfo;

      if (customerInfo.entitlements.all.isNotEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to MyPotato Pro! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff5FB567),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Stack(
              children: [
                // Main scrollable content
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header with close button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                              Text(
                                'PRO Content',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    await Purchases.restorePurchases();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Purchases restored'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print('Restore failed: $e');
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Mascot Image
                        Container(
                          width: 120,
                          height: 120,
                          child: Image.asset(
                            'assets/images/mascot4.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.emoji_emotions,
                                  size: 80,
                                  color: Colors.white,
                                ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // PRO Features Grid
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 4,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.75,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildFeatureItem(
                                Icon(
                                  Icons.mic,
                                  color: const Color(0xFF5856D6),
                                  size: 28,
                                ),
                                'Siri',
                              ),
                              _buildFeatureItem(
                                Icon(
                                  Bootstrap.bell_fill,
                                  color: const Color(0xFFFF3B30),
                                  size: 28,
                                ),
                                'Push\nNotifications',
                              ),
                              _buildFeatureItem(
                                Icon(
                                  Bootstrap.grid_3x3_gap_fill,
                                  color: const Color(0xFFFF9500),
                                  size: 28,
                                ),
                                'Unlimited\nCategories',
                              ),
                              _buildFeatureItem(
                                Icon(
                                  Bootstrap.wallet2,
                                  color: const Color(0xFF34C759),
                                  size: 28,
                                ),
                                'Budget +\nExpense',
                              ),
                              _buildFeatureItem(
                                Icon(
                                  Bootstrap.people_fill,
                                  color: const Color(0xFF007AFF),
                                  size: 28,
                                ),
                                'Multiperson\nTracking',
                              ),
                              _buildFeatureItem(
                                Icon(
                                  Bootstrap.graph_up,
                                  color: const Color(0xFFAF52DE),
                                  size: 28,
                                ),
                                'Download\nAnalytics',
                              ),
                              _buildFeatureItem(
                                Icon(
                                  Bootstrap.x_circle_fill,
                                  color: const Color(0xFFFF2D55),
                                  size: 28,
                                ),
                                'No Ads',
                              ),
                              _buildFeatureItem(
                                Icon(
                                  Bootstrap.three_dots,
                                  color: const Color(0xFF00C7BE),
                                  size: 28,
                                ),
                                'More\nFeatures',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 300),
                      ],
                    ),
                  ),
                ),

                // Bottom drawer section
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 24.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Subscription packages
                            if (_offerings?.current?.availablePackages != null)
                              ...(_offerings!.current!.availablePackages.map((
                                package,
                              ) {
                                final isSelected =
                                    package.identifier ==
                                    _selectedPackage?.identifier;
                                final priceString =
                                    package.storeProduct.priceString;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPackage = package;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xffF0F9F1)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xff5FB567)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xff5FB567)
                                                  : Colors.grey,
                                              width: 2,
                                            ),
                                            color: isSelected
                                                ? const Color(0xff5FB567)
                                                : Colors.transparent,
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 16,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            package.identifier,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          priceString,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList()),

                            const SizedBox(height: 16),

                            // Subscribe button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isPurchasing ? null : _onPurchase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff0A84FF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isPurchasing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Subscribe Now',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Terms text
                            Text(
                              'The subscription fee is charged to your iTunes account when you confirm your purchase. Subscription automatically renews unless auto-renew is turned off at least 24 hours prior to the current subscription period.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Links
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Privacy Policy',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[700],
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text(
                                  ' • ',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Terms of Use',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[700],
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeatureItem(Widget icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: icon),
        ),
        const SizedBox(height: 6),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  Offerings? _offerings;
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();

      if (_offerings != null &&
          _offerings!.current != null &&
          _offerings!.current!.availablePackages.isNotEmpty) {
        setState(() {
          _selectedPackage = _offerings!
              .current!
              .availablePackages
              .first; // default select first package
        });
      }
    } catch (e) {
      print('Error fetching offerings: $e');
    }
  }

  Future<void> _onPurchase() async {
    if (_selectedPackage == null) return;

    try {
      await Purchases.purchasePackage(_selectedPackage!);
      // TODO: Show success/confirmation and unlock premium features
      print('Purchase successful');
    } catch (e) {
      print('Purchase failed: $e');
      // Optionally show error message to user
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_offerings == null || _selectedPackage == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<Package> packages = _offerings!.current!.availablePackages;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...packages.map((package) {
              final isSelected =
                  package.identifier == _selectedPackage!.identifier;
              return ListTile(
                title: Text(package.storeProduct.title),
                subtitle: Text(package.storeProduct.priceString),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () => setState(() => _selectedPackage = package),
              );
            }).toList(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onPurchase,
              child: const Text('Subscribe'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

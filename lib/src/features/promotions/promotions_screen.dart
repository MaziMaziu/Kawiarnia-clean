import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final db = FirebaseFirestore.instance;
  String? _promotedProductId;
  int _selectedDiscount = 20; // Domyślna wartość zniżki
  final List<int> _discountOptions = [10, 15, 20, 25, 50];

  @override
  void initState() {
    super.initState();
    _fetchCurrentPromotion();
  }

  void _fetchCurrentPromotion() {
    db.collection('promotions').doc('daily_special').get().then((doc) {
      if (mounted && doc.exists && doc.data()?['active'] == true) {
        setState(() {
          _promotedProductId = doc.data()!['productId'];
          _selectedDiscount = (doc.data()!['discountPercentage'] as num).toInt();
        });
      }
    }).catchError((_) {});
  }

  Future<void> _togglePromotion(String productId, String productName) async {
    final promoRef = db.collection('promotions').doc('daily_special');

    if (_promotedProductId == productId) {
      await promoRef.set({'active': false, 'productId': null, 'discountPercentage': _selectedDiscount});
      setState(() => _promotedProductId = null);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wyłączono promocję dla $productName'), backgroundColor: Colors.red),
      );
    } else {
      await promoRef.set({
        'active': true,
        'productId': productId,
        'discountPercentage': _selectedDiscount,
      });
      setState(() => _promotedProductId = productId);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Włączono promocję -$_selectedDiscount% na $productName!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zarządzaj Promocją Dnia')),
      body: Column(
        children: [
          // Selektor zniżki
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Wysokość zniżki: ', style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<int>(
                  value: _selectedDiscount,
                  items: _discountOptions.map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value%'),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedDiscount = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista produktów
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('products').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Brak produktów do objęcia promocją.'));
                }

                final products = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final productId = product.id;
                    final productName = product['name'] as String? ?? 'Brak nazwy';
                    final isPromoted = _promotedProductId == productId;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                      elevation: isPromoted ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isPromoted ? Colors.teal : Colors.transparent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SwitchListTile(
                        title: Text(productName, style: TextStyle(fontWeight: isPromoted ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(isPromoted ? 'Promocja aktywna (-$_selectedDiscount%)' : 'Włącz promocję'),
                        value: isPromoted,
                        onChanged: (value) {
                          _togglePromotion(productId, productName);
                        },
                        activeColor: Colors.teal,
                      ),
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

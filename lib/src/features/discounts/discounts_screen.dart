import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DiscountsScreen extends StatefulWidget {
  const DiscountsScreen({super.key});

  @override
  State<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends State<DiscountsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateDiscount(String productId, double? newPrice) async {
    if (newPrice != null && newPrice >= 0) {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({'discountPrice': newPrice});
    } else {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({'discountPrice': FieldValue.delete()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarządzaj zniżkami'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Wystąpił błąd podczas ładowania produktów.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Brak produktów.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var product = snapshot.data!.docs[index];
              var productName = product['name'] ?? 'Brak nazwy';
              var productPrice = (product['price'] as num).toDouble();
              var discountPrice = (product.data() as Map<String, dynamic>)
                      .containsKey('discountPrice')
                  ? (product['discountPrice'] as num).toDouble()
                  : null;

              return ListTile(
                title: Text(productName),
                subtitle: Text(
                    'Cena: ${productPrice.toStringAsFixed(2)} zł' + (discountPrice != null ? ' | Zniżka: ${discountPrice.toStringAsFixed(2)} zł' : '')) ,
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showDiscountDialog(product.id, productName, discountPrice),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDiscountDialog(String productId, String productName, double? currentDiscount) {
    final TextEditingController controller = TextEditingController(
      text: currentDiscount?.toStringAsFixed(2) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edytuj zniżkę dla $productName'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nowa cena promocyjna',
              hintText: 'np. 8.99',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Anuluj'),
              onPressed: () => Navigator.of(context).pop(),
            ),
             TextButton(
              child: const Text('Usuń zniżkę'),
              onPressed: () {
                _updateDiscount(productId, null);
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Zapisz'),
              onPressed: () {
                final newPrice = double.tryParse(controller.text);
                _updateDiscount(productId, newPrice);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

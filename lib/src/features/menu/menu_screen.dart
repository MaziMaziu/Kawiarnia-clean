import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kawiarnia/src/features/cart/cart_provider.dart';
import 'package:kawiarnia/src/features/achievements/services/achievements_service.dart';
import 'package:provider/provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final db = FirebaseFirestore.instance;
  Map<String, dynamic>? _activePromotion;
  String _selectedCategory = 'Wszystko';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    db.collection('promotions').doc('daily_special').snapshots().listen((doc) {
      if (mounted) {
        setState(() {
          if (doc.exists && doc.data()?['active'] == true) {
            _activePromotion = doc.data();
          } else {
            _activePromotion = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buySubscription(BuildContext context, String productId, String productName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdź zakup'),
        content: Text('Czy na pewno chcesz kupić subskrypcję na 5x $productName?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Anuluj')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Kup')),
        ],
      ),
    );

    if (result != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Musisz być zalogowany.')));
      return;
    }

    final userRef = db.collection('users').doc(user.uid);

    try {
      await userRef.set({'subscriptions': {productId: FieldValue.increment(5)}}, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kupiono subskrypcję na 5x $productName!')));
        
        // Sprawdź osiągnięcie "Mistrz subskrypcji"
        final achievementsService = AchievementsService();
        await achievementsService.checkAndNotify(context, 'subscription_pro', 1);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_cafe_rounded, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Nasze Menu'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_activePromotion != null)
            _buildPromotionBanner(context, _activePromotion!['discountPercentage'] as num? ?? 0),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Szukaj produktów...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Category filters
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                'Wszystko',
                'Kawa',
                'Herbata',
                'Ciasta',
                'Napoje',
              ].map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('products').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_rounded, size: 80, color: theme.colorScheme.primary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'Brak produktów w menu',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final products = snapshot.data!.docs;

                // Filtrowanie po kategorii i wyszukiwaniu
                final filteredProducts = products.where((product) {
                  final productData = product.data() as Map<String, dynamic>;
                  final name = (productData['name'] ?? '').toString().toLowerCase();
                  final category = (productData['category'] ?? 'Inne').toString();
                  
                  // Filtr wyszukiwania
                  if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) {
                    return false;
                  }
                  
                  // Filtr kategorii
                  if (_selectedCategory != 'Wszystko' && category != _selectedCategory) {
                    return false;
                  }
                  
                  return true;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 80, color: theme.colorScheme.primary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'Nie znaleziono produktów',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Symuluj odświeżanie (Firestore automatycznie aktualizuje dane)
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final productId = product.id;
                    final productData = product.data() as Map<String, dynamic>;
                    final name = productData['name'] ?? 'Brak nazwy';
                    final price = (productData['price'] as num).toDouble();
                    final isCoffee = productData['isCoffee'] as bool? ?? false;
                    
                    bool isPromoted = _activePromotion != null && _activePromotion!['productId'] == productId;
                    double? discountedPrice;
                    if (isPromoted) {
                      final discountPercentage = (_activePromotion!['discountPercentage'] as num).toDouble() / 100;
                      discountedPrice = price * (1 - discountPercentage);
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: isPromoted 
                            ? LinearGradient(
                                colors: [
                                  theme.colorScheme.surface,
                                  theme.colorScheme.tertiary.withOpacity(0.1),
                                ],
                              )
                            : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.local_cafe_rounded,
                              size: 32,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isPromoted)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-${(_activePromotion!['discountPercentage'] as num).toInt()}%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildPriceWidget(context, price, discountedPrice),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCoffee)
                                IconButton(
                                  icon: const Icon(Icons.card_membership_rounded),
                                  tooltip: 'Kup subskrypcję (5 szt.)',
                                  onPressed: () => _buySubscription(context, productId, name),
                                  color: theme.colorScheme.secondary,
                                ),
                              IconButton(
                                icon: const Icon(Icons.add_shopping_cart_rounded),
                                tooltip: 'Dodaj do koszyka',
                                onPressed: () {
                                  cart.addItem(productId, name, price, isCoffee);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text('Dodano $name do koszyka'),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Banner promocji
  Widget _buildPromotionBanner(BuildContext context, num discount) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.tertiary,
            theme.colorScheme.tertiary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.tertiary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_offer_rounded,
              size: 32,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROMOCJA DNIA!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wybrany produkt -${discount.toInt()}% taniej',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widżet ceny
  Widget _buildPriceWidget(BuildContext context, double originalPrice, double? discountedPrice) {
    final theme = Theme.of(context);
    if (discountedPrice != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '${originalPrice.toStringAsFixed(2)} zł',
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${discountedPrice.toStringAsFixed(2)} zł',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      );
    }
    return Text(
      '${originalPrice.toStringAsFixed(2)} zł',
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

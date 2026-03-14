import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kawiarnia/src/features/cart/cart_provider.dart';
import 'package:kawiarnia/src/features/cart/qr_scanner_screen.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Provider.of<CartProvider>(context, listen: false).fetchUserData();
  }

  Future<void> _placeOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    // Najpierw zapytaj o numer stolika
    final tableNumber = await _showTableNumberDialog();
    if (tableNumber == null) return; // Użytkownik anulował

    setState(() => _isLoading = true);

    try {
      await cart.placeOrder(context, tableNumber);
      if (mounted) {
        // Pobierz numer zamówienia z ostatniego zamówienia
        final user = FirebaseAuth.instance.currentUser!;
        final latestOrder = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        
        final orderNumber = latestOrder.docs.isNotEmpty 
            ? latestOrder.docs.first.id.substring(0, 8).toUpperCase()
            : 'XXXX';

        Navigator.of(context).pop();
        
        // Pokaż dialog z numerem zamówienia
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.receipt_long_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 64,
            ),
            title: const Text('Zamówienie przyjęte!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Twój numer zamówienia:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    orderNumber,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Do zapłaty: ${cart.totalPrice.toStringAsFixed(2)} zł',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.table_restaurant_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Stolik: $tableNumber',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Zapłać przy odbiorze',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showTableNumberDialog() async {
    final tableController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.table_restaurant_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 64,
        ),
        title: const Text('Numer stolika'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Zeskanuj QR kod lub wpisz numer stolika',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: tableController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'np. 5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.table_restaurant_rounded),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final scannedCode = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (context) => const QrScannerScreen(),
                  ),
                );
                if (scannedCode != null && scannedCode.isNotEmpty) {
                  tableController.text = scannedCode;
                }
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Skanuj QR kod'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tableController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wpisz numer stolika')),
                );
                return;
              }
              Navigator.of(context).pop(tableController.text.trim());
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_rounded, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Twój Koszyk'),
          ],
        ),
      ),
      body: Column(
        children: [
          const Expanded(child: _CartListView()),
          const _VoucherSwitch(),
          _CheckoutPanel(isLoading: _isLoading, onPlaceOrder: _placeOrder),
        ],
      ),
    );
  }
}

// --- NOWE, LOGICZNE KOMPONENTY EKRANU ---

class _CartListView extends StatelessWidget {
  const _CartListView();

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    if (cart.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 100,
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'Twój koszyk jest pusty',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dodaj produkty z menu',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          onDismissed: (direction) {
            // Usuń wszystkie sztuki tego produktu
            for (int i = 0; i < item.quantity; i++) {
              cart.removeSingleItem(item.id);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.name} usunięty z koszyka'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'Cofnij',
                  onPressed: () {
                    // Dodaj z powrotem
                    for (int i = 0; i < item.quantity; i++) {
                      cart.addItem(item.id, item.name, item.price, item.isCoffee);
                    }
                  },
                ),
              ),
            );
          },
          child: _CartItemCard(item: item).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
        );
      },
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final theme = Theme.of(context);
    final availableSubscriptions = cart.getSubscriptionsRemaining(item.id);
    final canUseSubscription = availableSubscriptions > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.price.toStringAsFixed(2)} zł/szt.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item.finalPrice.toStringAsFixed(2)} zł',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ilość:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _QuantitySelector(
                  quantity: item.quantity,
                  onAdd: () => cart.addItem(item.id, item.name, item.price, item.isCoffee),
                  onRemove: () => cart.removeSingleItem(item.id),
                ),
              ],
            ),
            if (canUseSubscription) ...[
              const SizedBox(height: 12),
              _SubscriptionManager(
                item: item,
                available: availableSubscriptions,
                onToggle: (use) => cart.toggleSubscriptionUsage(item.id, use),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantitySelector({required this.quantity, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: onRemove, color: Theme.of(context).colorScheme.error),
        Text(quantity.toString(), style: Theme.of(context).textTheme.titleLarge),
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onAdd, color: Theme.of(context).colorScheme.primary),
      ],
    );
  }
}

class _SubscriptionManager extends StatelessWidget {
  final CartItem item;
  final int available;
  final ValueChanged<bool> onToggle;

  const _SubscriptionManager({required this.item, required this.available, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.remove), onPressed: () => onToggle(false)),
            Column(
              children: [
                Text('Z subskrypcji: ${item.subscribedQuantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('(Dostępne: $available)', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: () => onToggle(true)),
          ],
        ),
      ),
    );
  }
}

class _VoucherSwitch extends StatelessWidget {
  const _VoucherSwitch();

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final hasVouchers = cart.userVouchers > 0;
        final hasCoffeeInCart = cart.items.any((item) => item.isCoffee);
        final canUseVoucher = hasVouchers && hasCoffeeInCart;

        if (!canUseVoucher) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.tertiary.withOpacity(0.1),
                ],
              ),
            ),
            child: SwitchListTile(
              secondary: Icon(
                Icons.redeem_rounded,
                color: theme.colorScheme.secondary,
              ),
              title: Text(
                'Użyj bon na darmową kawę',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Dostępne bony: ${cart.userVouchers}',
                style: theme.textTheme.bodySmall,
              ),
              value: cart.isVoucherUsed,
              onChanged: (bool value) => cart.toggleVoucherUsage(value),
              activeColor: theme.colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPlaceOrder;
  const _CheckoutPanel({required this.isLoading, required this.onPlaceOrder});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Do zapłaty',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cart.totalPrice.toStringAsFixed(2)} zł',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ElevatedButton(
                onPressed: (cart.items.isEmpty || isLoading) ? null : onPlaceOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ZŁÓŻ ZAMÓWIENIE',
                  style: TextStyle(fontSize: 16, letterSpacing: 1.2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

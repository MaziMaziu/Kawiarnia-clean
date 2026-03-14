import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kawiarnia/src/features/achievements/services/achievements_service.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final bool isCoffee;
  int quantity;
  int subscribedQuantity;
  bool isPaidByVoucher;
  double discount;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.isCoffee,
    required this.quantity,
    this.subscribedQuantity = 0,
    this.isPaidByVoucher = false,
    this.discount = 0.0,
  });

  double get itemSubtotal {
     return price * (1 - discount);
  }

  double get finalPrice {
    int paidQuantity = quantity - subscribedQuantity;
    if (isPaidByVoucher) paidQuantity--;
    return itemSubtotal * (paidQuantity > 0 ? paidQuantity : 0);
  }
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  Map<String, dynamic> _userSubscriptions = {};
  int _userVouchers = 0;
  bool _useVoucher = false;
  
  // ROZBUDOWANE PREFERENCJE UŻYTKOWNIKA
  bool _userPrefersLactoseFree = false;
  bool _userPrefersOatMilk = false;
  bool _userPrefersSyrup = false;
  bool _userPrefersNoSugar = false; // DODANE POLE

  Map<String, dynamic>? _activePromotion;
  StreamSubscription? _promotionSubscription;

  CartProvider() {
    _listenForPromotions();
    fetchUserData();
  }

  @override
  void dispose() {
    _promotionSubscription?.cancel();
    super.dispose();
  }

  void _listenForPromotions() {
    _promotionSubscription = FirebaseFirestore.instance
        .collection('promotions')
        .doc('daily_special')
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data()?['active'] == true) {
        _activePromotion = doc.data();
      } else {
        _activePromotion = null;
      }
      _updateDiscounts();
    });
  }

  void _updateDiscounts() {
    if (_activePromotion != null) {
      final promoId = _activePromotion!['productId'];
      final discountPercentage = (_activePromotion!['discountPercentage'] as num).toDouble() / 100;

      for (var item in _items.values) {
        item.discount = (item.id == promoId) ? discountPercentage : 0.0;
      }
    } else {
       for (var item in _items.values) {
        item.discount = 0.0;
      }
    }
    notifyListeners();
  }

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.length;
  int get userVouchers => _userVouchers;
  bool get isVoucherUsed => _useVoucher;

  int getSubscriptionsRemaining(String productId) {
    return (_userSubscriptions[productId] as int?) ?? 0;
  }

  double get totalPrice {
    var total = 0.0;
    _items.forEach((key, cartItem) {
       total += cartItem.finalPrice;
    });
    if (_useVoucher) {
      final coffeeToDiscount = _getMostExpensiveCoffee();
      if (coffeeToDiscount != null) {
        total -= coffeeToDiscount.price;
      }
    }
    return total > 0 ? total : 0.0;
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      _userSubscriptions = data?['subscriptions'] ?? {};
      _userVouchers = data?['vouchers'] ?? 0;
      
      _userPrefersLactoseFree = data?['prefersLactoseFreeMilk'] ?? false;
      _userPrefersOatMilk = data?['prefersOatMilk'] ?? false;
      _userPrefersSyrup = data?['prefersSyrup'] ?? false;
      _userPrefersNoSugar = data?['prefersNoSugar'] ?? false; // DODANE POBIERANIE PREFERENCJI
      
      notifyListeners();
    } catch (e) {
      print("Błąd pobierania danych użytkownika: $e");
    }
  }

  void toggleVoucherUsage(bool use) {
    final coffeesInCart = items.any((item) => item.isCoffee);
    if (use && _userVouchers > 0 && coffeesInCart) {
      _useVoucher = true;
    } else {
      _useVoucher = false;
    }
    notifyListeners();
  }

  CartItem? _getMostExpensiveCoffee() {
    CartItem? mostExpensive;
    items
        .where((item) => item.isCoffee && !item.isPaidByVoucher && item.subscribedQuantity < item.quantity)
        .forEach((item) {
      if (mostExpensive == null || item.price > mostExpensive!.price) {
        mostExpensive = item;
      }
    });
    return mostExpensive;
  }

  void addItem(String productId, String name, double price, bool isCoffee) {
    if (_items.containsKey(productId)) {
      _items.update(productId, (e) => CartItem(id: e.id, name: e.name, price: e.price, isCoffee: e.isCoffee, quantity: e.quantity + 1, subscribedQuantity: e.subscribedQuantity));
    } else {
      _items.putIfAbsent(productId, () => CartItem(id: productId, name: name, price: price, isCoffee: isCoffee, quantity: 1));
    }
    _updateDiscounts();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    final item = _items[productId]!;
    if (item.quantity > 1) {
      item.quantity--;
      if (item.subscribedQuantity > item.quantity) {
        item.subscribedQuantity = item.quantity;
      }
    } else {
      _items.remove(productId);
    }
    if (items.where((i) => i.isCoffee).isEmpty) {
      _useVoucher = false;
    }
    notifyListeners();
  }

  void toggleSubscriptionUsage(String productId, bool use) {
    final item = _items[productId];
    if (item == null) return;
    final available = getSubscriptionsRemaining(productId);
    if (use) {
      if (available > item.subscribedQuantity) item.subscribedQuantity++;
    } else {
      if (item.subscribedQuantity > 0) item.subscribedQuantity--;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _useVoucher = false;
    notifyListeners();
  }

  Future<void> placeOrder(BuildContext context, String tableNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Użytkownik nie jest zalogowany.');
    if (_items.isEmpty) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final orderRef = FirebaseFirestore.instance.collection('orders').doc();

    final bool containsCoffee = _items.values.any((item) => item.isCoffee);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) throw Exception("Użytkownik nie istnieje!");

      final Map<String, dynamic> updates = {};
      int pointsToAward = 0;

      CartItem? discountedCoffee;
      if (_useVoucher) {
        final vouchers = (userSnapshot.data()?['vouchers'] as int?) ?? 0;
        if (vouchers < 1) throw Exception('Brak dostępnych bonów!');
        discountedCoffee = _getMostExpensiveCoffee();
        if (discountedCoffee == null) throw Exception('W koszyku nie ma kawy, aby użyć bonu!');
        updates['vouchers'] = FieldValue.increment(-1);
        discountedCoffee.isPaidByVoucher = true;
      }

      for (final item in _items.values) {
        int paidWithMoney = item.quantity - item.subscribedQuantity;
        if (item.isPaidByVoucher) paidWithMoney--;
        if (paidWithMoney > 0) pointsToAward += paidWithMoney;

        if (item.subscribedQuantity > 0) {
          final currentSubscriptions = userSnapshot.data()?['subscriptions'] as Map<String, dynamic>? ?? {};
          final available = (currentSubscriptions[item.id] as int?) ?? 0;
          if (available < item.subscribedQuantity) throw Exception('Za mało ${item.name} w subskrypcji!');
          updates['subscriptions.${item.id}'] = FieldValue.increment(-item.subscribedQuantity);
        }
      }
      
      if (pointsToAward > 0) updates['points'] = FieldValue.increment(pointsToAward);
      if (updates.isNotEmpty) transaction.update(userRef, updates);

      final orderData = {
        'userId': user.uid, 'userEmail': user.email, 'totalPrice': totalPrice,
        'createdAt': Timestamp.now(), 'status': 'Oczekujące',
        'tableNumber': tableNumber,
        'isPaid': false,
        'lactoseFree': (_userPrefersLactoseFree && containsCoffee),
        'oatMilk': (_userPrefersOatMilk && containsCoffee),
        'withSyrup': _userPrefersSyrup,
        'noSugar': _userPrefersNoSugar, // DODANE POLE
        'products': _items.values.map((item) => {
          'productId': item.id, 'name': item.name, 'quantity': item.quantity, 'price': item.price,
          'subscribedQuantity': item.subscribedQuantity, 'paidByVoucher': item.isPaidByVoucher,
          'discount': item.discount
        }).toList(),
      };
      transaction.set(orderRef, orderData);
    });

    // Sprawdź osiągnięcia z powiadomieniami
    await _checkOrderAchievements(context, totalPrice);

    clear();
  }

  Future<void> _checkOrderAchievements(BuildContext context, double orderTotal) async {
    final achievementsService = AchievementsService();
    
    // Pierwsze zamówienie
    await achievementsService.checkAndNotify(context, 'first_order', 1);
    
    // Zamówienia ogólnie (10, 50, 100)
    await achievementsService.checkAndNotify(context, 'orders_10', 1);
    await achievementsService.checkAndNotify(context, 'orders_50', 1);
    await achievementsService.checkAndNotify(context, 'orders_100', 1);
    
    // Sprawdź godzinę zamówienia
    final now = DateTime.now();
    if (now.hour < 8) {
      // Wczesny ptak (przed 8:00)
      await achievementsService.checkAndNotify(context, 'early_bird', 1);
    } else if (now.hour >= 20) {
      // Nocny marek (po 20:00)
      await achievementsService.checkAndNotify(context, 'night_owl', 1);
    }
    
    // Weekend
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      await achievementsService.checkAndNotify(context, 'weekend_warrior', 1);
    }
    
    // Duże zamówienie (powyżej 100 zł)
    if (orderTotal > 100) {
      await achievementsService.checkAndNotify(context, 'big_spender', 1);
    }
  }
}

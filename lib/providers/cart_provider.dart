import 'package:flutter/foundation.dart';
import '../modules/products/models/product_model.dart';
import '../services/email_service.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });

  // Helper to convert back to a Product for certain operations
  Product toProduct() {
    return Product(
      id: id,
      name: name,
      price: price,
      description: '', // Not needed for cart logic
      image: image,
    );
  }
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addToCart(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existing) => CartItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          image: existing.image,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(
          id: product.id,
          name: product.name,
          price: product.price,
          image: product.image,
        ),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          image: existing.image,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Prepares cart data for email and sends confirmation
  Future<bool> checkout({required String userEmail}) async {
    if (_items.isEmpty) return false;

    // Prepare items for email
    final itemsForEmail = _items.entries.map((e) => {
      'name': e.value.name,
      'price': e.value.price,
      'quantity': e.value.quantity,
    }).toList();

    // Send confirmation email
    final success = await EmailService.sendCartConfirmation(
      recipientEmail: userEmail,
      cartItems: itemsForEmail,
      totalPrice: totalAmount,
    );

    if (success) {
      clear(); // Clear cart after successful email
    }

    return success;
  }
}

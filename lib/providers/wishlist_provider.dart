import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/products/models/product_model.dart';

class WishlistProvider with ChangeNotifier {
  List<Product> _favorites = [];
  Set<String> _wishlistIds = {}; // Keep IDs for quick lookup

  static const _wishlistKey = 'wishlist_ids';

  WishlistProvider() {
    loadWishlist();
  }

  List<Product> get favorites => [..._favorites];
  Set<String> get wishlist => {..._wishlistIds};

  bool isFavorite(String productId) {
    return _wishlistIds.contains(productId);
  }

  Future<void> toggleFavorite(Product product) async {
    if (_wishlistIds.contains(product.id)) {
      _wishlistIds.remove(product.id);
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      _wishlistIds.add(product.id);
      _favorites.add(product);
    }
    await _saveWishlist();
    notifyListeners();
  }

  Future<void> loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistData = prefs.getStringList(_wishlistKey);
    if (wishlistData != null) {
      _wishlistIds = wishlistData.toSet();
      notifyListeners();
    }
  }

  Future<void> _saveWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_wishlistKey, _wishlistIds.toList());
  }

  /// Add products to favorites list (used by product provider to sync)
  void syncFavorites(List<Product> allProducts) {
    _favorites = allProducts.where((p) => _wishlistIds.contains(p.id)).toList();
    notifyListeners();
  }
}

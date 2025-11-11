import 'package:flutter/foundation.dart';
import '../modules/products/models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends  ChangeNotifier {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _productService.fetchProducts();
    } catch (e) {
      print("❌ Error loading products: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> addProduct(Product product) async {
    try {
      final newId = await _productService.addProduct(product);
      // Create a product instance with the DB-assigned id to keep IDs consistent.
      final persisted = Product(
        id: newId.toString(),
        name: product.name,
        description: product.description,
        price: product.price,
        image: product.image,
      );
      _products.add(persisted);
      notifyListeners();
      print("✅ Product added: ${product.name}");
    } catch (e) {
      print("❌ Error adding product: $e");
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    try {
      await _productService.updateProduct(newProduct);
      final index = _products.indexWhere((p) => p.id == id);
      if (index >= 0) {
        _products[index] = newProduct;
        notifyListeners();
        print("✅ Product updated: ${newProduct.name}");
      }
    } catch (e) {
      print("❌ Error updating product: $e");
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      print("✅ Product deleted with id: $id");
    } catch (e) {
      print("❌ Error deleting product: $e");
    }
  }
}

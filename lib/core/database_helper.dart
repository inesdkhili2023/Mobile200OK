import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../modules/products/models/product_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('products.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Use a custom path (e.g., D:/your-folder/products.db) for debugging
    // Ensure the path is valid for your platform; this only works on certain environments.
    final customPath = 'D:/outils_app/$filePath';

    // Uncomment the line below if you want to see the custom database path for debugging
    if (kDebugMode) {
      print("Custom Database path: $customPath");
    }

    return await openDatabase(customPath, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      price REAL NOT NULL,
      image TEXT NOT NULL
    )
    ''');
  }

  Future<void> cacheProducts(List<Product> products) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var product in products) {
      batch.insert(
        'products',
        product.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Product>> getCachedProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromJson(json)).toList();
  }

  Future<void> clearProducts() async {
    final db = await instance.database;
    await db.delete('products');
  }
}

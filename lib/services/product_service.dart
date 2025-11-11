import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../modules/products/models/product_model.dart';

class ProductService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('products.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // This will now print to your console successfully on all platforms.
    if (kDebugMode) {
      print('===========================================================');
      print('✅ Database file is located at: $path');
      print('===========================================================');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        price REAL,
        image TEXT
      )
    ''');
  }

  Future<List<Product>> fetchProducts() async {
    final db = await database;
    final maps = await db.query('products');

    if (maps.isEmpty) {
      await insertDemoProducts();
      return await fetchProducts();
    }

    return maps.map((e) => Product.fromJson(e)).toList();
  }

  /// Inserts [product] into the database and returns the new row id.
  Future<int> addProduct(Product product) async {
    final db = await database;
    final id = await db.insert('products', {
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'image': product.image,
    });
    return id;
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    final intId = int.tryParse(product.id);
    if (intId == null) {
      throw ArgumentError('Product id is not a valid integer: ${product.id}');
    }
    await db.update(
      'products',
      {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'image': product.image,
      },
      where: 'id = ?',
      whereArgs: [intId],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    final intId = int.tryParse(id);
    if (intId == null) {
      // If id is not an integer, nothing to delete in the integer PK table.
      return;
    }
    await db.delete('products', where: 'id = ?', whereArgs: [intId]);
  }

  Future<void> insertDemoProducts() async {
    final db = await database;
    final demoData = [
      {
        'name': 'Marteau Pro',
        'description': 'Marteau professionnel 500g',
        'price': 45.0,
        'image': 'https://cdn-icons-png.flaticon.com/512/685/685655.png',
      },
      {
        'name': 'Perceuse Électrique',
        'description': 'Perceuse sans fil 18V',
        'price': 120.0,
        'image': 'https://cdn-icons-png.flaticon.com/512/685/685644.png',
      },
    ];

    for (var item in demoData) {
      await db.insert('products', item);
    }
  }
}

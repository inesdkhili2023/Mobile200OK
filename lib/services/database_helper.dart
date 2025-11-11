import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/worker_model.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('service_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Delete existing database to force recreation with new schema
    try {
      await deleteDatabase(path);
    } catch (e) {
      debugPrint('Error deleting database: $e');
    }

    return await openDatabase(
      path,
      version: 3, // Incremented version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        email TEXT NOT NULL,
        workType TEXT NOT NULL,
        yearsOfExperience INTEGER NOT NULL,
        price INTEGER NOT NULL,
        rating REAL NOT NULL,
        profileImage TEXT,
        portfolioImages TEXT,
        description TEXT,
        latitude REAL,
        longitude REAL,
        address TEXT,
        totalReviews INTEGER DEFAULT 0,
        isSelected INTEGER DEFAULT 0
      )
    ''');

    // Insert sample data
    await _insertSampleWorkers(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE workers ADD COLUMN description TEXT');
      await db.execute('ALTER TABLE workers ADD COLUMN totalReviews INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE workers ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE workers ADD COLUMN longitude REAL');
      await db.execute('ALTER TABLE workers ADD COLUMN address TEXT');
    }
  }

  Future<void> _insertSampleWorkers(Database db) async {
    final workers = [
      {
        'fullName': 'Samir Tifafi',
        'phoneNumber': '25 589 561',
        'email': 'Samir.Tifafi@gmail.com',
        'workType': 'Electrician',
        'yearsOfExperience': 8,
        'rating': 4.8,
        'price': 70,
        'isSelected': 0,
        'description': 'Experienced electrician specializing in residential and commercial installations.',
        'totalReviews': 96,
        'latitude': 36.8065,
        'longitude': 10.1815,
        'address': 'Tunis, Tunisia',
      },
      {
        'fullName': 'Seml el Felahl',
        'phoneNumber': '25 589 562',
        'email': 'Seml.Felahl@gmail.com',
        'workType': 'Electrician',
        'yearsOfExperience': 6,
        'rating': 4.5,
        'price': 100,
        'isSelected': 0,
        'description': 'Professional electrician with expertise in electrical repairs and maintenance.',
        'totalReviews': 90,
        'latitude': 36.8025,
        'longitude': 10.1795,
        'address': 'Ariana, Tunisia',
      },
      {
        'fullName': 'Chokri Atia',
        'phoneNumber': '25 589 563',
        'email': 'Chokri.Atia@gmail.com',
        'workType': 'Electrician',
        'yearsOfExperience': 5,
        'rating': 4.3,
        'price': 75,
        'isSelected': 0,
        'description': 'Skilled electrician offering quality electrical services at affordable rates.',
        'totalReviews': 86,
        'latitude': 36.8005,
        'longitude': 10.1775,
        'address': 'Ben Arous, Tunisia',
      },
      {
        'fullName': 'Ahmed Ben Ali',
        'phoneNumber': '25 589 564',
        'email': 'Ahmed.BenAli@gmail.com',
        'workType': 'Plumber',
        'yearsOfExperience': 10,
        'rating': 4.9,
        'price': 85,
        'isSelected': 0,
        'description': 'Master plumber with 10 years of experience in all plumbing services.',
        'totalReviews': 98,
        'latitude': 36.8045,
        'longitude': 10.1835,
        'address': 'Tunis, Tunisia',
      },
      {
        'fullName': 'Mohamed Salah',
        'phoneNumber': '25 589 565',
        'email': 'Mohamed.Salah@gmail.com',
        'workType': 'Carpenter',
        'yearsOfExperience': 7,
        'rating': 4.6,
        'price': 90,
        'isSelected': 0,
        'description': 'Expert carpenter specializing in custom furniture and woodwork.',
        'totalReviews': 92,
        'latitude': 36.8085,
        'longitude': 10.1855,
        'address': 'Manouba, Tunisia',
      },
      {
        'fullName': 'Youssef Mansour',
        'phoneNumber': '25 589 566',
        'email': 'Youssef.Mansour@gmail.com',
        'workType': 'Cleaning',
        'yearsOfExperience': 4,
        'rating': 4.4,
        'price': 50,
        'isSelected': 0,
        'description': 'Professional cleaning service for homes and offices.',
        'totalReviews': 88,
        'latitude': 36.8105,
        'longitude': 10.1875,
        'address': 'Tunis, Tunisia',
      },
      {
        'fullName': 'Karim Hamdi',
        'phoneNumber': '25 589 567',
        'email': 'Karim.Hamdi@gmail.com',
        'workType': 'Repairing',
        'yearsOfExperience': 9,
        'rating': 4.7,
        'price': 80,
        'isSelected': 0,
        'description': 'General repair specialist for home appliances and fixtures.',
        'totalReviews': 94,
        'latitude': 36.8125,
        'longitude': 10.1895,
        'address': 'Tunis, Tunisia',
      },
    ];

    for (var worker in workers) {
      await db.insert('workers', worker);
    }
  }

  // CRUD Operations for Workers
  Future<int> insertWorker(WorkerModel worker) async {
    final db = await database;
    return await db.insert('workers', worker.toMap());
  }

  Future<List<WorkerModel>> getAllWorkers() async {
    final db = await database;
    final result = await db.query('workers', orderBy: 'rating DESC');
    return result.map((map) => WorkerModel.fromMap(map)).toList();
  }

  Future<List<WorkerModel>> getWorkersByType(String workType) async {
    final db = await database;
    final result = await db.query(
      'workers',
      where: 'workType = ?',
      whereArgs: [workType],
      orderBy: 'rating DESC',
    );
    return result.map((map) => WorkerModel.fromMap(map)).toList();
  }

  Future<WorkerModel?> getWorkerById(int id) async {
    final db = await database;
    final result = await db.query(
      'workers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return WorkerModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateWorker(WorkerModel worker) async {
    final db = await database;
    return await db.update(
      'workers',
      worker.toMap(),
      where: 'id = ?',
      whereArgs: [worker.id],
    );
  }

  Future<int> updateWorkerRating(int workerId, double rating) async {
    final db = await database;
    return await db.update(
      'workers',
      {'rating': rating},
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }

  Future<int> toggleWorkerSelection(int workerId, bool isSelected) async {
    final db = await database;
    return await db.update(
      'workers',
      {'isSelected': isSelected ? 1 : 0},
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }

  Future<int> deleteWorker(int id) async {
    final db = await database;
    return await db.delete(
      'workers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search and Filter Methods
  Future<List<WorkerModel>> searchWorkers(String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'workers',
      where: '''
        fullName LIKE ? OR 
        workType LIKE ? OR 
        email LIKE ? OR 
        description LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'rating DESC, yearsOfExperience DESC',
    );

    return maps.map((map) => WorkerModel.fromMap(map)).toList();
  }

  Future<List<WorkerModel>> getWorkersByRating(double minRating, double maxRating) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workers',
      where: 'rating BETWEEN ? AND ?',
      whereArgs: [minRating, maxRating],
      orderBy: 'rating DESC',
    );

    return maps.map((map) => WorkerModel.fromMap(map)).toList();
  }

  Future<List<WorkerModel>> getWorkersByPriceRange(int minPrice, int maxPrice) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workers',
      where: 'price BETWEEN ? AND ?',
      whereArgs: [minPrice, maxPrice],
      orderBy: 'price ASC',
    );

    return maps.map((map) => WorkerModel.fromMap(map)).toList();
  }

  // Statistics Methods
  Future<Map<String, dynamic>> getWorkerStats() async {
    final db = await database;
    
    final totalWorkers = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM workers'),
    );
    
    final avgRating = await db.rawQuery(
      'SELECT AVG(rating) as avg FROM workers',
    );
    
    final topRated = await db.query(
      'workers',
      orderBy: 'rating DESC',
      limit: 1,
    );

    return {
      'totalWorkers': totalWorkers ?? 0,
      'averageRating': avgRating.first['avg'] ?? 0.0,
      'topRated': topRated.isNotEmpty 
          ? WorkerModel.fromMap(topRated.first) 
          : null,
    };
  }

  Future<List<WorkerModel>> getSelectedWorkers() async {
    final db = await database;
    final result = await db.query(
      'workers',
      where: 'isSelected = ?',
      whereArgs: [1],
    );
    return result.map((map) => WorkerModel.fromMap(map)).toList();
  }

  Future<int> clearAllSelections() async {
    final db = await database;
    return await db.update(
      'workers',
      {'isSelected': 0},
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
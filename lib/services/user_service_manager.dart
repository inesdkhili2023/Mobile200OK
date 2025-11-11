// services/user_service_manager.dart
import 'package:sqflite/sqflite.dart';
import '../models/user_service.dart';
import 'database_helper.dart';

class UserServiceManager {
  static final UserServiceManager _instance = UserServiceManager._internal();
  factory UserServiceManager() => _instance;
  UserServiceManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Initialiser la table des services utilisateur
  Future<void> initUserServicesTable() async {
    final db = await _dbHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_services(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        priceType TEXT NOT NULL,
        images TEXT,
        location TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  // Récupérer TOUS les services (sans filtre utilisateur)
  Future<List<UserService>> getAllServices() async {
    await initUserServicesTable();
    final db = await _dbHelper.database;
    final result = await db.query(
      'user_services',
      orderBy: 'createdAt DESC',
    );
    
    return result.map((map) => UserService.fromMap(map)).toList();
  }

  // Récupérer les services d'un utilisateur spécifique (optionnel)
  Future<List<UserService>> getUserServices(String userId) async {
    await initUserServicesTable();
    final db = await _dbHelper.database;
    final result = await db.query(
      'user_services',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    
    return result.map((map) => UserService.fromMap(map)).toList();
  }
  // Dans UserServiceManager
Future<List<UserService>> getServicesByCategory(String category) async {
  final allServices = await getAllServices();
  return allServices.where((service) => 
    service.category.toLowerCase() == category.toLowerCase()
  ).toList();
}

  // Ajouter un service
  Future<int> addUserService(UserService service) async {
    await initUserServicesTable();
    final db = await _dbHelper.database;
    return await db.insert('user_services', service.toMap());
  }

  // Modifier un service (sans vérification utilisateur)
  Future<int> updateUserService(UserService service) async {
    final db = await _dbHelper.database;
    return await db.update(
      'user_services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  // Supprimer un service (sans vérification utilisateur) - CORRIGÉ ICI
  Future<int> deleteUserService(int serviceId) async { // Changé de String à int
    final db = await _dbHelper.database;
    return await db.delete(
      'user_services',
      where: 'id = ?',
      whereArgs: [serviceId],
    );
  }

  // Récupérer un service par ID (sans vérification utilisateur) - CORRIGÉ ICI
  Future<UserService?> getServiceById(int serviceId) async { // Changé de String à int
    final db = await _dbHelper.database;
    final result = await db.query(
      'user_services',
      where: 'id = ?',
      whereArgs: [serviceId],
    );
    
    if (result.isNotEmpty) {
      return UserService.fromMap(result.first);
    }
    return null;
  }

  // Rechercher des services par catégorie
  Future<List<UserService>> searchServicesByCategory(String category) async {
    await initUserServicesTable();
    final db = await _dbHelper.database;
    final result = await db.query(
      'user_services',
      where: 'category LIKE ?',
      whereArgs: ['%$category%'],
      orderBy: 'createdAt DESC',
    );
    
    return result.map((map) => UserService.fromMap(map)).toList();
  }

  // Rechercher des services par mot-clé
  Future<List<UserService>> searchServices(String query) async {
    await initUserServicesTable();
    final db = await _dbHelper.database;
    final result = await db.query(
      'user_services',
      where: 'title LIKE ? OR description LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    
    return result.map((map) => UserService.fromMap(map)).toList();
  }

  // Récupérer les services par localisation
  Future<List<UserService>> getServicesByLocation(String location) async {
    await initUserServicesTable();
    final db = await _dbHelper.database;
    final result = await db.query(
      'user_services',
      where: 'location LIKE ?',
      whereArgs: ['%$location%'],
      orderBy: 'createdAt DESC',
    );
    
    return result.map((map) => UserService.fromMap(map)).toList();
  }
}
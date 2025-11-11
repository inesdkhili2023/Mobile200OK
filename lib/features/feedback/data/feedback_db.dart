import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/feedback_model.dart';

class FeedbackDb {
  FeedbackDb._();
  static final FeedbackDb instance = FeedbackDb._();

  static const _dbName = 'feedback_app.db';
  static const _dbVersion = 1;
  static const _table = 'feedbacks';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service TEXT NOT NULL,
            status TEXT NOT NULL,
            rating INTEGER NOT NULL,
            comment TEXT NOT NULL,
            price_label TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // CRUD
  Future<int> insert(FeedbackModel f) async {
    final db = await database;
    return db.insert(_table, f.toMap());
  }

  Future<List<FeedbackModel>> getAll() async {
    final db = await database;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map((e) => FeedbackModel.fromMap(e)).toList();
  }

  Future<int> update(FeedbackModel f) async {
    final db = await database;
    return db.update(_table, f.toMap(), where: 'id = ?', whereArgs: [f.id]);
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // Stats
  Future<double> getAverageRating() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT AVG(rating) as avg FROM $_table WHERE rating > 0');
    final value = rows.first['avg'] as num?;
    return (value ?? 0).toDouble();
  }

  Future<Map<String, int>> countByStatus() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT status, COUNT(*) as c FROM $_table GROUP BY status');
    final map = <String, int>{};
    for (final r in rows) {
      map[r['status'] as String] = (r['c'] as int?) ?? 0;
    }
    return map;
  }

  Future<double> getAverageForService(String service) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT AVG(rating) as avg FROM $_table WHERE rating > 0 AND service = ?',
      [service],
    );
    final value = rows.first['avg'] as num?;
    return (value ?? 0).toDouble();
  }
}

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDb {
  static Database? _db;
  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'handicraft.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
CREATE TABLE worker_availability(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  worker_id TEXT,
  date TEXT,
  slots TEXT,
  is_holiday INTEGER,
  latitude REAL,
  longitude REAL
);
''');
        await db.execute('''
CREATE TABLE booking(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  worker_id TEXT,
  worker_name TEXT,
  city TEXT,
  date TEXT,
  slot TEXT,
  description TEXT,
  address TEXT,
  pax INTEGER,
  price_cents INTEGER,
  status TEXT,
  email TEXT,
   latitude REAL,
  longitude REAL
);
''');
      },
    );
    return _db!;
  }
}

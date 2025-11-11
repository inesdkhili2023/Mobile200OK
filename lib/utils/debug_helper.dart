// utils/debug_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../services/database_helper.dart';

class DebugHelper {
  static Future<void> printDatabaseInfo() async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, 'service_app.db');
      
      print('=== DATABASE DEBUG INFO ===');
      print('Database path: $dbPath');
      
      final db = await DatabaseHelper.instance.database;
      
      // Afficher toutes les tables
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      print('Tables in database:');
      for (var table in tables) {
        final tableName = table['name'];
        print(' - $tableName');
        
        // Compter les lignes
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableName')
        );
        print('   Rows: $count');
        
        // Afficher les premières lignes
        if (count != null && count > 0) {
          final sample = await db.query(tableName.toString(), limit: 2);
          print('   Sample data: $sample');
        }
      }
      
      print('=== END DEBUG INFO ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  static Future<void> exportTableData(String tableName) async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query(tableName);
    print('=== $tableName Data ===');
    for (var row in data) {
      print(row);
    }
  }
}
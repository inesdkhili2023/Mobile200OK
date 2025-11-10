import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chats.db');

    return await openDatabase(
      path,
      version: 3, // 🔥 Version augmentée à 3 pour audioPath
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase, // 🔥 Ajout de la méthode de migration
    );
  }

  // 🔥 EXTRACT: Méthode de création séparée
  Future<void> _createDatabase(Database db, int version) async {
    // Table des conversations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        name TEXT,
        message TEXT,
        time TEXT,
        avatar TEXT
      )
    ''');

    // Table des messages
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        text TEXT,
        isMe INTEGER,
        timestamp TEXT,
        isRead INTEGER DEFAULT 0,
        audioPath TEXT
      )
    ''');
    print('✅ Database created with audioPath column');
  }

  // 🔥 NOUVELLE MÉTHODE: Migration de la base de données
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('🔄 Migration de la base: v$oldVersion -> v$newVersion');
    
    if (oldVersion < 2) {
      try {
        // Vérifier si la colonne isRead existe déjà
        final columns = await db.rawQuery('PRAGMA table_info(messages)');
        bool hasIsRead = columns.any((col) => col['name'] == 'isRead');
        
        if (!hasIsRead) {
          await db.execute('ALTER TABLE messages ADD COLUMN isRead INTEGER DEFAULT 0');
          print('✅ Colonne isRead ajoutée à la table messages');
        } else {
          print('✅ Colonne isRead existe déjà');
        }
      } catch (e) {
        print('❌ Erreur lors de l\'ajout de isRead: $e');
      }
    }
    
    if (oldVersion < 3) {
      try {
        // Vérifier si la colonne audioPath existe déjà
        final columns = await db.rawQuery('PRAGMA table_info(messages)');
        bool hasAudioPath = columns.any((col) => col['name'] == 'audioPath');
        
        if (!hasAudioPath) {
          await db.execute('ALTER TABLE messages ADD COLUMN audioPath TEXT');
          print('✅ Colonne audioPath ajoutée à la table messages');
        } else {
          print('✅ Colonne audioPath existe déjà');
        }
      } catch (e) {
        print('❌ Erreur lors de l\'ajout de audioPath: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MESSAGE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Insérer un message
  Future<void> insertMessage(String userId, String text, bool isMe, {String? audioPath}) async {
    final db = await database;
    
    try {
      await db.insert('messages', {
        'userId': userId,
        'text': text,
        'isMe': isMe ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': isMe ? 1 : 0,
        'audioPath': audioPath,
      });
      print('✅ Message inséré pour $userId: "$text" (isMe: $isMe, audioPath: $audioPath)');
    } catch (e) {
      print('❌ Erreur insertion message: $e');
      // 🔥 FALLBACK: Réessayer sans audioPath si erreur
      try {
        await db.insert('messages', {
          'userId': userId,
          'text': text,
          'isMe': isMe ? 1 : 0,
          'timestamp': DateTime.now().toIso8601String(),
          'isRead': isMe ? 1 : 0,
        });
        print('✅ Message inséré (sans audioPath) pour $userId: "$text"');
      } catch (e2) {
        print('❌ Erreur critique insertion message: $e2');
        rethrow;
      }
    }
  }

  /// Récupérer les messages pour un utilisateur
  Future<List<Map<String, dynamic>>> getMessages(String userId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
    
    // Return a new mutable list to avoid read-only errors
    return List<Map<String, dynamic>>.from(result);
  }

  /// Modifier un message
  Future<void> updateMessage(int messageId, String newText) async {
    final db = await database;
    await db.update(
      'messages',
      {
        'text': newText,
        'timestamp': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
    print('✅ Message $messageId modifié: "$newText"');
  }

  /// Supprimer un message spécifique
  Future<void> deleteMessage(int messageId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
    print('✅ Message $messageId supprimé');
  }

  /// Supprimer les messages d'un utilisateur
  Future<void> deleteMessages(String userId) async {
    final db = await database;
    final count = await db.delete(
      'messages',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print('✅ $count messages supprimés pour l\'utilisateur $userId');
  }

  /// Supprimer tous les messages
  Future<void> clearAllMessages() async {
    final db = await database;
    final count = await db.delete('messages');
    print('🗑️ $count messages supprimés de la base de données');
  }

  /// 🔥 CORRECTION: Compter les messages non lus pour un utilisateur
  Future<int> getUnreadCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM messages 
      WHERE userId = ? AND isMe = 0 AND (isRead = 0 OR isRead IS NULL)
    ''', [userId]);
    
    final count = Sqflite.firstIntValue(result) ?? 0;
    print('🔍 Unread count for $userId: $count');
    return count;
  }

  /// Récupérer tous les messages non lus pour un utilisateur
  Future<List<Map<String, dynamic>>> getUnreadMessages(String userId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'userId = ? AND isMe = 0 AND (isRead = 0 OR isRead IS NULL)',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    
    return List<Map<String, dynamic>>.from(result);
  }

  /// Récupérer tous les utilisateurs avec des messages non lus
  Future<List<String>> getUsersWithUnreadMessages() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT userId 
      FROM messages 
      WHERE isMe = 0 AND (isRead = 0 OR isRead IS NULL)
    ''');
    
    return result.map((row) => row['userId'] as String).toList();
  }

  /// 🔥 CORRECTION: Marquer tous les messages comme lus pour un utilisateur
  Future<void> markMessagesAsRead(String userId) async {
    final db = await database;
    
    // D'abord, compter combien de messages seront mis à jour
    final beforeCount = await getUnreadCount(userId);
    
    // Marquer comme lus
    final result = await db.update(
      'messages',
      {'isRead': 1},
      where: 'userId = ? AND isMe = 0 AND (isRead = 0 OR isRead IS NULL)',
      whereArgs: [userId],
    );
    
    // Vérifier après
    final afterCount = await getUnreadCount(userId);
    
    print('✅ $result messages marqués comme lus pour $userId');
    print('🔍 Avant: $beforeCount non lus, Après: $afterCount non lus');
  }

  /// Obtenir le dernier message d'un utilisateur
  Future<Map<String, dynamic>?> getLastMessage(String userId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  // ═══════════════════════════════════════════════════════════
  // CHAT OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Insérer ou mettre à jour un chat
  Future<void> insertOrUpdateChat(Map<String, dynamic> chat) async {
    final db = await database;
    await db.insert(
      'chats',
      chat,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ Chat mis à jour pour ${chat['name']}');
  }

  /// Récupérer tous les chats
  Future<List<Map<String, dynamic>>> getAllChats() async {
    final db = await database;
    final result = await db.query('chats', orderBy: 'time DESC');
    return List<Map<String, dynamic>>.from(result);
  }

  /// Mettre à jour le dernier message d'un chat
  Future<void> updateLastMessage(String userId, String message, String time) async {
    final db = await database;
    await db.update(
      'chats',
      {
        'message': message,
        'time': time,
      },
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print('✅ Dernier message mis à jour pour $userId: "$message"');
  }

  /// Récupérer un chat spécifique par userId
  Future<Map<String, dynamic>?> getChat(String userId) async {
    final db = await database;
    final result = await db.query(
      'chats',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  /// Supprimer un chat spécifique
  Future<void> deleteChat(String userId) async {
    final db = await database;
    await db.delete(
      'chats',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print('🗑️ Chat supprimé pour userId: $userId');
  }

  // ═══════════════════════════════════════════════════════════
  // NOTIFICATION HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Obtenir les informations pour les notifications
  Future<List<Map<String, dynamic>>> getNotificationData() async {
    final db = await database;
    
    // Récupérer tous les utilisateurs avec des messages non lus
    final usersWithUnread = await getUsersWithUnreadMessages();
    
    List<Map<String, dynamic>> notificationData = [];
    
    for (String userId in usersWithUnread) {
      // Récupérer le chat pour avoir le nom
      final chat = await getChat(userId);
      
      if (chat != null) {
        // Compter les messages non lus
        final unreadCount = await getUnreadCount(userId);
        
        // Récupérer les messages non lus
        final unreadMessages = await getUnreadMessages(userId);
        
        notificationData.add({
          'userId': userId,
          'userName': chat['name'],
          'avatar': chat['avatar'],
          'unreadCount': unreadCount,
          'unreadMessages': unreadMessages.map((m) => m['text']).toList(),
          'lastMessage': unreadMessages.isNotEmpty ? unreadMessages.first['text'] : '',
        });
      }
    }
    
    return notificationData;
  }

  /// Vérifier si un utilisateur a des messages non lus
  Future<bool> hasUnreadMessages(String userId) async {
    final count = await getUnreadCount(userId);
    return count > 0;
  }

  // ═══════════════════════════════════════════════════════════
  // DEBUG & UTILITY METHODS
  // ═══════════════════════════════════════════════════════════

  /// Afficher tous les messages dans la console
  Future<void> printAllMessages() async {
    final db = await database;
    final messages = await db.query('messages', orderBy: 'timestamp ASC');
    
    print('\n═══════════════════════════════════════');
    print('📨 DATABASE MESSAGES (Total: ${messages.length})');
    print('═══════════════════════════════════════');
    
    if (messages.isEmpty) {
      print('  (No messages found)');
    } else {
      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final isRead = msg['isRead'] == 1 ? 'LUE' : 'NON LUE';
        print('\nMessage #${i + 1}:');
        print('  ID: ${msg['id']}');
        print('  User ID: ${msg['userId']}');
        print('  Text: ${msg['text']}');
        print('  Is Me: ${msg['isMe'] == 1 ? 'Yes' : 'No'}');
        print('  Status: $isRead');
        print('  Timestamp: ${msg['timestamp']}');
        print('  Audio Path: ${msg['audioPath'] ?? 'null'}');
      }
    }
    print('═══════════════════════════════════════\n');
  }

  /// Afficher tous les chats dans la console
  Future<void> printAllChats() async {
    final db = await database;
    final chats = await db.query('chats');
    
    print('\n═══════════════════════════════════════');
    print('💬 DATABASE CHATS (Total: ${chats.length})');
    print('═══════════════════════════════════════');
    
    if (chats.isEmpty) {
      print('  (No chats found)');
    } else {
      for (var i = 0; i < chats.length; i++) {
        final chat = chats[i];
        print('\nChat #${i + 1}:');
        print('  User ID: ${chat['userId']}');
        print('  Name: ${chat['name']}');
        print('  Last Message: ${chat['message']}');
        print('  Time: ${chat['time']}');
      }
    }
    print('\n═══════════════════════════════════════\n');
  }

  /// Afficher les statistiques des messages non lus
  Future<void> printUnreadStats() async {
    final usersWithUnread = await getUsersWithUnreadMessages();
    
    print('\n═══════════════════════════════════════');
    print('📬 UNREAD MESSAGES STATISTICS');
    print('═══════════════════════════════════════');
    
    if (usersWithUnread.isEmpty) {
      print('  ✅ No unread messages!');
    } else {
      print('Users with unread messages: ${usersWithUnread.length}\n');
      
      for (String userId in usersWithUnread) {
        final count = await getUnreadCount(userId);
        final chat = await getChat(userId);
        final userName = chat?['name'] ?? 'Unknown';
        
        print('  👤 $userName (ID: $userId): $count unread');
      }
    }
    print('═══════════════════════════════════════\n');
  }

  /// Obtenir le chemin de la base de données
  Future<String> getDatabasePath() async {
    final db = await database;
    return db.path;
  }

  /// Obtenir le nombre de messages par utilisateur
  Future<Map<String, int>> getMessageCountByUser() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT userId, COUNT(*) as count 
      FROM messages 
      GROUP BY userId
    ''');
    
    Map<String, int> counts = {};
    for (var row in result) {
      counts[row['userId'] as String] = row['count'] as int;
    }
    return counts;
  }

  /// Obtenir les statistiques complètes
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    
    final messageCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM messages')
    ) ?? 0;
    
    final chatCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM chats')
    ) ?? 0;
    
    final unreadCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM messages WHERE isMe = 0 AND (isRead = 0 OR isRead IS NULL)')
    ) ?? 0;
    
    final userCounts = await getMessageCountByUser();
    final usersWithUnread = await getUsersWithUnreadMessages();
    
    return {
      'totalMessages': messageCount,
      'totalChats': chatCount,
      'totalUnread': unreadCount,
      'usersWithUnread': usersWithUnread.length,
      'messagesByUser': userCounts,
      'databasePath': await getDatabasePath(),
    };
  }

  /// Afficher les statistiques complètes
  Future<void> printDatabaseStats() async {
    final stats = await getDatabaseStats();
    
    print('\n═══════════════════════════════════════');
    print('📊 DATABASE STATISTICS');
    print('═══════════════════════════════════════');
    print('Total Messages: ${stats['totalMessages']}');
    print('Total Chats: ${stats['totalChats']}');
    print('Total Unread Messages: ${stats['totalUnread']}');
    print('Users with Unread: ${stats['usersWithUnread']}');
    print('\nMessages by User:');
    
    final messagesByUser = stats['messagesByUser'] as Map<String, int>;
    if (messagesByUser.isEmpty) {
      print('  (No messages yet)');
    } else {
      messagesByUser.forEach((userId, count) {
        print('  User $userId: $count messages');
      });
    }
    
    print('\nDatabase Location:');
    print('  ${stats['databasePath']}');
    print('═══════════════════════════════════════\n');
  }

  /// Supprimer toute la base de données (reset complet)
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chats.db');
    
    await deleteDatabase(path);
    _db = null;
    
    print('🗑️ Database completely reset!');
    
    // Réinitialiser la base de données
    await database;
  }

  /// Exporter les données en JSON (utile pour debug)
  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    
    final messages = await db.query('messages');
    final chats = await db.query('chats');
    final notificationData = await getNotificationData();
    
    return {
      'messages': messages,
      'chats': chats,
      'notificationData': notificationData,
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Fermer la base de données proprement
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      print('🔒 Database closed');
    }
  }

  /// 🔥 NOUVELLE MÉTHODE: Vérifier la structure de la base de données
  Future<void> checkDatabaseStructure() async {
    final db = await database;
    
    print('\n🔍 CHECKING DATABASE STRUCTURE');
    
    // Vérifier la table messages
    final messageColumns = await db.rawQuery('PRAGMA table_info(messages)');
    print('Messages table columns:');
    for (var col in messageColumns) {
      print('  - ${col['name']} (${col['type']})');
    }
    
    // Vérifier la table chats
    final chatColumns = await db.rawQuery('PRAGMA table_info(chats)');
    print('Chats table columns:');
    for (var col in chatColumns) {
      print('  - ${col['name']} (${col['type']})');
    }
    
    print('🔍 END OF STRUCTURE CHECK\n');
  }
}
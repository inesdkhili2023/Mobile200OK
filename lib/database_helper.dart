import 'dart:io';

import 'package:path_provider/path_provider.dart';
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
      version: 4, // 🔥 Version augmentée à 4 pour gifUrl
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

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

    // Table des messages - AVEC TOUTES LES COLONNES
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        text TEXT,
        isMe INTEGER,
        timestamp TEXT,
        isRead INTEGER DEFAULT 0,
        audioPath TEXT,
        gifUrl TEXT
      )
    ''');
    print('✅ Database created with all columns (audioPath, gifUrl)');
  }

  // 🔥 CORRECTION: Migration complète avec gifUrl
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('🔄 Migration de la base: v$oldVersion -> v$newVersion');
    
    // Migration de v1 à v2
    if (oldVersion < 2) {
      try {
        final columns = await db.rawQuery('PRAGMA table_info(messages)');
        bool hasIsRead = columns.any((col) => col['name'] == 'isRead');
        
        if (!hasIsRead) {
          await db.execute('ALTER TABLE messages ADD COLUMN isRead INTEGER DEFAULT 0');
          print('✅ Colonne isRead ajoutée');
        }
      } catch (e) {
        print('❌ Erreur lors de l\'ajout de isRead: $e');
      }
    }
    
    // Migration de v2 à v3
    if (oldVersion < 3) {
      try {
        final columns = await db.rawQuery('PRAGMA table_info(messages)');
        bool hasAudioPath = columns.any((col) => col['name'] == 'audioPath');
        
        if (!hasAudioPath) {
          await db.execute('ALTER TABLE messages ADD COLUMN audioPath TEXT');
          print('✅ Colonne audioPath ajoutée');
        }
      } catch (e) {
        print('❌ Erreur lors de l\'ajout de audioPath: $e');
      }
    }
    
    // 🔥 NOUVEAU: Migration de v3 à v4
    if (oldVersion < 4) {
      try {
        final columns = await db.rawQuery('PRAGMA table_info(messages)');
        bool hasGifUrl = columns.any((col) => col['name'] == 'gifUrl');
        
        if (!hasGifUrl) {
          await db.execute('ALTER TABLE messages ADD COLUMN gifUrl TEXT');
          print('✅ Colonne gifUrl ajoutée');
        }
      } catch (e) {
        print('❌ Erreur lors de l\'ajout de gifUrl: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MESSAGE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Insérer un message
  Future<int> insertMessage(String userId, String text, bool isMe, {String? audioPath, String? gifUrl}) async {
    final db = await database;
    
    try {
      final id = await db.insert('messages', {
        'userId': userId,
        'text': text,
        'isMe': isMe ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': isMe ? 1 : 0,
        'audioPath': audioPath,
        'gifUrl': gifUrl
      });
      print('✅ Message inséré pour $userId: "$text" (isMe: $isMe, audioPath: $audioPath, gifUrl: $gifUrl)');
      return id;
    } catch (e) {
      print('❌ Erreur insertion message: $e');
      // Fallback sans les colonnes optionnelles
      try {
        final id = await db.insert('messages', {
          'userId': userId,
          'text': text,
          'isMe': isMe ? 1 : 0,
          'timestamp': DateTime.now().toIso8601String(),
          'isRead': isMe ? 1 : 0,
        });
        print('✅ Message inséré (sans médias) pour $userId: "$text"');
        return id;
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
    
    // DEBUG: Afficher le contenu des messages pour vérifier
    print('🔍 Récupération de ${result.length} messages pour $userId');
    for (var msg in result) {
      print('  - "${msg['text']}" | audioPath: ${msg['audioPath']} | gifUrl: ${msg['gifUrl']}');
    }
    
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
 /// Supprimer un message ET son fichier associé
Future<void> deleteMessage(int messageId) async {
  final db = await database;
  
  // D'abord supprimer les fichiers multimédias
  await _deleteMediaFiles(messageId);
  
  // Ensuite supprimer le message de la base
  await db.delete(
    'messages',
    where: 'id = ?',
    whereArgs: [messageId],
  );
}
  /// 🆕 Supprimer les fichiers multimédias associés à un message
Future<void> _deleteMediaFiles(int messageId) async {
  final db = await database;
  
  // Récupérer le message pour obtenir le chemin du fichier
  final messages = await db.query(
    'messages',
    where: 'id = ?',
    whereArgs: [messageId],
  );
  
  if (messages.isNotEmpty) {
    final message = messages.first;
    final String? mediaPath = message['audio_path'] as String?;
    final String text = message['text'] as String;
    
    // Vérifier si c'est un message vocal ou image
    final bool isVoice = text.contains("🎵");
    final bool isImage = text.contains("📷");
    
    if (mediaPath != null && mediaPath.isNotEmpty) {
      try {
        final file = File(mediaPath);
        if (await file.exists()) {
          await file.delete();
          print('🗑️ Fichier ${isVoice ? 'vocal' : 'image'} supprimé: $mediaPath');
        }
      } catch (e) {
        print('❌ Erreur suppression fichier: $e');
      }
    }
  }
}
/// 🆕 Nettoyer les fichiers multimédias qui ne sont plus référencés dans la base
Future<void> cleanupOrphanedMediaFiles() async {
  final db = await database;
  
  // Récupérer tous les chemins de fichiers valides dans la base
  final messages = await db.query('messages', 
    where: 'audio_path IS NOT NULL AND audio_path != ""');
  
  final validPaths = messages
      .map((msg) => msg['audio_path'] as String)
      .where((path) => path.isNotEmpty)
      .toSet();
  
  print('🔍 ${validPaths.length} chemins valides trouvés dans la base');
  
  // Dossier temporaire où sont stockés les fichiers
  final directory = await getTemporaryDirectory();
  final tempDir = Directory(directory.path);
  
  if (await tempDir.exists()) {
    final files = tempDir.listSync();
    int deletedCount = 0;
    
    for (var file in files) {
      if (file is File) {
        final filePath = file.path;
        
        // Vérifier si c'est un fichier audio ou image de notre app
        if ((filePath.contains('audio_') || filePath.contains('.jpg') || filePath.contains('.png')) &&
            !validPaths.contains(filePath)) {
          try {
            await file.delete();
            deletedCount++;
            print('🧹 Fichier orphelin supprimé: ${file.path}');
          } catch (e) {
            print('❌ Erreur suppression fichier orphelin: $e');
          }
        }
      }
    }
    
    print('🧹 Nettoyage terminé: $deletedCount fichiers orphelins supprimés');
    
    if (deletedCount == 0) {
      print('✅ Aucun fichier orphelin trouvé');
    }
  }
}

  /// Supprimer les messages d'un utilisateur
 /// Supprimer tous les messages d'une conversation ET leurs fichiers
/// Supprimer tous les messages d'une conversation ET leurs fichiers
/// Supprimer tous les messages d'une conversation ET leurs fichiers
Future<void> deleteMessages(String userId) async {  // ✅ userId au lieu de chatId
  final db = await database;
  
  print('🗑️ Suppression des messages pour userId: $userId');
  
  // Récupérer tous les messages avec fichiers multimédias
  final messages = await db.query(
    'messages',
    where: 'userId = ? AND audioPath IS NOT NULL',  // ✅ userId et audioPath (pas audio_path)
    whereArgs: [userId],
  );
  
  print('🔍 ${messages.length} messages avec fichiers trouvés');
  
  // Supprimer tous les fichiers multimédias
  for (var message in messages) {
    final String? mediaPath = message['audioPath'] as String?;  // ✅ audioPath (pas audio_path)
    if (mediaPath != null && mediaPath.isNotEmpty) {
      try {
        final file = File(mediaPath);
        if (await file.exists()) {
          await file.delete();
          print('🗑️ Fichier média supprimé: $mediaPath');
        } else {
          print('⚠️ Fichier déjà supprimé: $mediaPath');
        }
      } catch (e) {
        print('❌ Erreur suppression fichier: $e');
      }
    }
  }
  
  // Maintenant supprimer tous les messages
  final deletedCount = await db.delete(
    'messages',
    where: 'userId = ?',  // ✅ userId (pas chat_id)
    whereArgs: [userId],
  );
  
  print('✅ $deletedCount messages supprimés pour userId: $userId');
  
  // Mettre à jour le chat (optionnel - pour garder la conversation mais vide)
  try {
    await db.update(
      'chats',
      {
        'message': 'Aucun message',
        'time': 'Maintenant',
      },
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print('✅ Chat mis à jour pour userId: $userId');
  } catch (e) {
    print('⚠️ Chat non trouvé ou erreur mise à jour: $e');
  }
}

  /// Supprimer tous les messages
  Future<void> clearAllMessages() async {
    final db = await database;
    final count = await db.delete('messages');
    print('🗑️ $count messages supprimés de la base de données');
  }

  /// Compter les messages non lus pour un utilisateur
  Future<int> getUnreadCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM messages 
      WHERE userId = ? AND isMe = 0 AND (isRead = 0 OR isRead IS NULL)
    ''', [userId]);
    
    final count = Sqflite.firstIntValue(result) ?? 0;
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

  /// Marquer tous les messages comme lus pour un utilisateur
  Future<void> markMessagesAsRead(String userId) async {
    final db = await database;
    
    final result = await db.update(
      'messages',
      {'isRead': 1},
      where: 'userId = ? AND isMe = 0 AND (isRead = 0 OR isRead IS NULL)',
      whereArgs: [userId],
    );
    
    print('✅ $result messages marqués comme lus pour $userId');
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
    
    final usersWithUnread = await getUsersWithUnreadMessages();
    
    List<Map<String, dynamic>> notificationData = [];
    
    for (String userId in usersWithUnread) {
      final chat = await getChat(userId);
      
      if (chat != null) {
        final unreadCount = await getUnreadCount(userId);
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
        print('  GIF URL: ${msg['gifUrl'] ?? 'null'}');
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

  /// 🔥 NOUVELLE MÉTHODE: Réinitialiser pour les tests
  Future<void> resetDatabaseForTesting() async {
    final db = await database;
    
    // Supprimer toutes les tables
    await db.execute('DROP TABLE IF EXISTS messages');
    await db.execute('DROP TABLE IF EXISTS chats');
    
    // Recréer les tables avec la nouvelle structure
    await _createDatabase(db, 4);
    
    print('✅ Database reset avec la nouvelle structure');
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

  /// Vérifier la structure de la base de données
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

  /// 🔥 NOUVELLE MÉTHODE: Vérifier si un message est un média
  bool isMediaMessage(Map<String, dynamic> message) {
    final text = message['text'] as String? ?? '';
    final audioPath = message['audioPath'] as String?;
    final gifUrl = message['gifUrl'] as String?;
    
    return text.contains("📷") || 
           text.contains("🎵") || 
           text.contains("🎆") ||
           audioPath != null ||
           gifUrl != null;
  }

  /// 🔥 NOUVELLE MÉTHODE: Obtenir le type de média d'un message
  String getMessageType(Map<String, dynamic> message) {
    final text = message['text'] as String? ?? '';
    final audioPath = message['audioPath'] as String?;
    final gifUrl = message['gifUrl'] as String?;
    
    if (text.contains("🎆") || gifUrl != null) return 'gif';
    if (text.contains("📷") || (audioPath != null && text.contains("📷"))) return 'image';
    if (text.contains("🎵") || audioPath != null) return 'voice';
    return 'text';
  }
}
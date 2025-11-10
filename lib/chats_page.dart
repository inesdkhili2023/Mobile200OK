import 'package:flutter/material.dart';
import 'message_page.dart';
import 'database_helper.dart';
import 'notification_service.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  
  // User contacts with their info
  final List<Map<String, dynamic>> _userContacts = const [
    {
      "id": "1",
      "name": "James",
      "avatar": "https://i.pravatar.cc/150?img=1"
    },
    {
      "id": "2",
      "name": "Will Kenny",
      "avatar": "https://i.pravatar.cc/150?img=2"
    },
    {
      "id": "3",
      "name": "Beth Williams",
      "avatar": "https://i.pravatar.cc/150?img=3"
    },
    {
      "id": "4",
      "name": "Rev Shawn",
      "avatar": "https://i.pravatar.cc/150?img=4"
    },
  ];

  List<Map<String, dynamic>> chatsWithLastMessages = [];
  List<Map<String, dynamic>> filteredChats = [];
  bool isSearching = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChatsWithLastMessages();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
      _filterChats();
    });
  }

  void _filterChats() {
    if (searchQuery.isEmpty) {
      filteredChats = chatsWithLastMessages;
    } else {
      filteredChats = chatsWithLastMessages.where((chat) {
        final name = chat['name']!.toLowerCase();
        final message = chat['message']!.toLowerCase();
        return name.contains(searchQuery) || message.contains(searchQuery);
      }).toList();
    }
  }

  Future<void> _loadChatsWithLastMessages() async {
    await _initializeChatsInDatabase();
    
    List<Map<String, dynamic>> chats = [];

    for (var contact in _userContacts) {
      // Get messages for this user
      final messages = await _dbHelper.getMessages(contact["id"]);
      
      // Get the last message
      String lastMessage = "Pas de messages";
      String time = "";
      
      // 🔥 COMPTER SEULEMENT LES MESSAGES NON LUS (isRead = 0)
      int unreadCount = messages.where((m) => m['isMe'] == 0 && (m['isRead'] == 0 || m['isRead'] == null)).length;

      if (messages.isNotEmpty) {
        final lastMsg = messages.last;
        lastMessage = lastMsg['text'];
        
        // Format timestamp
        final timestamp = DateTime.parse(lastMsg['timestamp']);
        time = _formatTime(timestamp);
        
        // ⚡ Notification si messages non lus
        if (unreadCount > 0) {
          NotificationService().showNotification(
            id: int.parse(contact["id"]),
            title: "Nouveau message de ${contact["name"]}",
            body: lastMessage,
          );
        }
      }

      chats.add({
        "id": contact["id"],
        "name": contact["name"],
        "avatar": contact["avatar"],
        "message": lastMessage,
        "time": time,
        "unreadCount": unreadCount, // 🔥 Maintenant seulement les non lus
        "hasMessages": messages.isNotEmpty,
      });
    }

    // Sort by most recent first (contacts with messages first)
    chats.sort((a, b) {
      if (a['hasMessages'] && !b['hasMessages']) return -1;
      if (!a['hasMessages'] && b['hasMessages']) return 1;
      return 0;
    });

    setState(() {
      chatsWithLastMessages = chats;
      _filterChats();
    });
  }

  // 🔥 NOUVELLE MÉTHODE POUR MARQUER COMME LU VISUELLEMENT
  void _markChatAsRead(String userId) async {
    // Marquer comme lu dans la base
    await _dbHelper.markMessagesAsRead(userId);
    
    // Mettre à jour l'état local immédiatement
    if (mounted) {
      setState(() {
        // Mettre à jour dans chatsWithLastMessages
        final index = chatsWithLastMessages.indexWhere((c) => c["id"] == userId);
        if (index != -1) {
          chatsWithLastMessages[index]["unreadCount"] = 0;
        }
        
        // Mettre à jour dans filteredChats
        final filteredIndex = filteredChats.indexWhere((c) => c["id"] == userId);
        if (filteredIndex != -1) {
          filteredChats[filteredIndex]["unreadCount"] = 0;
        }
      });
    }
  }

  Future<void> _initializeChatsInDatabase() async {
    final existingChats = await _dbHelper.getAllChats();
    
    // Si la table chats est vide, initialiser avec les contacts
    if (existingChats.isEmpty) {
      for (var contact in _userContacts) {
        await _dbHelper.insertOrUpdateChat({
          'userId': contact["id"],
          'name': contact["name"],
          'message': 'Pas de messages',
          'time': '',
          'avatar': contact["avatar"],
        });
      }
      print('✅ Chats initialisés dans la base de données');
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Hier';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[dateTime.weekday - 1];
    } else {
      // Older - show date
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year.toString().substring(2);
      return '$day/$month/$year';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const ChatBottomBar(),
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.deepPurple),
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              )
            : const Text("Chats", style: TextStyle(color: Colors.deepPurple)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
                onPressed: () {
                  setState(() {
                    isSearching = false;
                    _searchController.clear();
                    searchQuery = '';
                    _filterChats();
                  });
                },
              )
            : null,
        actions: [
          if (!isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.deepPurple),
              tooltip: 'Rechercher',
              onPressed: () {
                setState(() {
                  isSearching = true;
                });
              },
            ),
          if (isSearching && searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.deepPurple),
              tooltip: 'Effacer',
              onPressed: () {
                _searchController.clear();
              },
            ),
          if (!isSearching)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.deepPurple),
              tooltip: 'Debug',
              onPressed: () async {
                print('\n🔍 CHATS PAGE DEBUG');
                await _dbHelper.printAllMessages();
                await _dbHelper.printDatabaseStats();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database info printed to console'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar (always visible alternative)
          if (!isSearching)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher des conversations...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          
          // Results count
          if (searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${filteredChats.length} résultat${filteredChats.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (filteredChats.isEmpty)
                    const Text(
                      'Aucun résultat trouvé',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          
          // Chat list
          Expanded(
            child: filteredChats.isEmpty && searchQuery.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun résultat pour "$searchQuery"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Essayez un autre terme de recherche',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : chatsWithLastMessages.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.deepPurple,
                        ),
                      )
                    : RefreshIndicator(
                        color: Colors.deepPurple,
                        onRefresh: _loadChatsWithLastMessages,
                        child: ListView.builder(
                          itemCount: filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = filteredChats[index];
                            final hasUnread = chat["unreadCount"] > 0;
                            
                            // Highlight search term
                            final nameWidget = _buildHighlightedText(
                              chat["name"]!,
                              searchQuery,
                              TextStyle(
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                              ),
                            );
                            
                            final messageWidget = _buildHighlightedText(
                              chat["message"]!,
                              searchQuery,
                              TextStyle(
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                color: chat["hasMessages"] ? Colors.black87 : Colors.grey,
                              ),
                            );
                            
                            return InkWell(
                              onTap: () async {
                                // 🔥 MARQUER COMME LU IMMÉDIATEMENT AU CLIC
                                _markChatAsRead(chat["id"]!);
                                
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MessagePage(
                                      userName: chat["name"]!,
                                      userId: chat["id"]!,
                                    ),
                                  ),
                                );
                                
                                // 🔥 RAFRAÎCHIR AU RETOUR POUR SYNCHRONISER
                                if (mounted) {
                                  await _loadChatsWithLastMessages();
                                }
                              },
                              child: Dismissible(
                                key: Key(chat["id"]!),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Supprimer la conversation?'),
                                        content: Text(
                                          'Voulez-vous vraiment supprimer tous les messages avec ${chat["name"]}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Annuler'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text(
                                              'Supprimer',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onDismissed: (direction) async {
                                  await _dbHelper.deleteMessages(chat["id"]!);
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Messages avec ${chat["name"]} supprimés'),
                                      ),
                                    );
                                  }
                                  
                                  await _loadChatsWithLastMessages();
                                },
                                child: Container(
                                  color: hasUnread ? Colors.deepPurple.shade50 : Colors.white,
                                  child: ListTile(
                                    leading: Stack(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(chat["avatar"]!),
                                          backgroundColor: Colors.grey[300],
                                        ),
                                        if (hasUnread)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: nameWidget,
                                    subtitle: messageWidget,
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          chat["time"]!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                            color: hasUnread ? Colors.deepPurple : Colors.grey[600],
                                          ),
                                        ),
                                        if (hasUnread) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${chat["unreadCount"]}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(
              backgroundColor: Colors.yellow,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}

class ChatBottomBar extends StatelessWidget {
  const ChatBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 60,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Icon(Icons.home_outlined, color: Colors.deepPurple),
          Icon(Icons.search_outlined, color: Colors.grey),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.add, color: Colors.white),
          ),
          Icon(Icons.notifications_none, color: Colors.grey),
          Icon(Icons.person_outline, color: Colors.grey),
        ],
      ),
    );
  }
}
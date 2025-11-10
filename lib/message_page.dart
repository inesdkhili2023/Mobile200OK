import 'package:flutter/material.dart';
import 'dart:async';
import 'database_helper.dart';
import 'notification_service.dart';

class MessagePage extends StatefulWidget {
  final String userName;
  final String userId;

  const MessagePage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool sendAsMe = true; // 🔥 Mode d'envoi (qui envoie actuellement)
  
  // Editing state
  int? _editingMessageId;
  final TextEditingController _editController = TextEditingController();
  
  // Typing indicator state
  bool isTyping = false;
  bool otherUserIsTyping = false;
  Timer? _typingTimer;
  Timer? _simulateTypingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    
    // Écouter les changements dans le TextField
    _controller.addListener(_onTextChanged);
    
    // Annuler les notifications pour ce contact
    _notificationService.cancelNotification(widget.userId);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _editController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _simulateTypingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_controller.text.isNotEmpty && !isTyping) {
      setState(() {
        isTyping = true;
      });
      
      _simulateOtherUserTyping();
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isTyping = false;
        });
      }
    });
  }

  void _simulateOtherUserTyping() {
    _simulateTypingTimer?.cancel();
    
    if (sendAsMe) {
      _simulateTypingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _controller.text.isEmpty) {
          setState(() {
            otherUserIsTyping = true;
          });
          
          Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                otherUserIsTyping = false;
              });
            }
          });
        }
      });
    }
  }

 Future<void> _loadMessages() async {
  final data = await _dbHelper.getMessages(widget.userId);
  setState(() {
    messages = List<Map<String, dynamic>>.from(data);
  });
  
  // Marquer les messages non lus comme lus si on regarde la conversation
  await _dbHelper.markMessagesAsRead(widget.userId);
  
  _scrollToBottom();
}

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final messageText = _controller.text.trim();
    
    // Arrêter le typing indicator
    setState(() {
      isTyping = false;
      otherUserIsTyping = false;
    });
    _typingTimer?.cancel();
    _simulateTypingTimer?.cancel();
    
    // 🔥 IMPORTANT: Utiliser sendAsMe pour déterminer qui envoie
    await _dbHelper.insertMessage(widget.userId, messageText, sendAsMe);

    // Mettre à jour le dernier message dans la table chats
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await _dbHelper.updateLastMessage(widget.userId, messageText, time);

    _controller.clear();
    await _loadMessages();
  }

  /// 🆕 Edit message
  Future<void> _editMessage(int messageId, String currentText) async {
    _editController.text = currentText;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le message'),
        content: TextField(
          controller: _editController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Modifier votre message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (_editController.text.trim().isNotEmpty) {
                Navigator.pop(context, _editController.text.trim());
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _dbHelper.updateMessage(messageId, result);
      await _loadMessages();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Message modifié'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
    
    _editController.clear();
  }

  /// 🆕 Delete message
  Future<void> _deleteMessage(int messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le message?'),
        content: const Text('Cette action ne peut pas être annulée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteMessage(messageId);
      await _loadMessages();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Message supprimé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🆕 Simuler la réception d'un message
  Future<void> _simulateReceivedMessage() async {
    const receivedMessages = [
      "Salut! Comment ça va?",
      "Tu es disponible pour discuter?",
      "J'ai une question pour toi",
      "Merci pour ton aide!",
      "À bientôt! 👋",
      "C'est noté!",
      "Super, merci!",
      "D'accord, je comprends",
      "Pas de problème 😊",
      "On se voit demain?",
    ];

    final randomMessage = (receivedMessages..shuffle()).first;
    
    // 🔥 IMPORTANT: isMe = false pour les messages de l'autre personne
    await _dbHelper.insertMessage(widget.userId, randomMessage, false);

    // Mettre à jour le dernier message
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await _dbHelper.updateLastMessage(widget.userId, randomMessage, time);

    // Recharger les messages
    await _loadMessages();

    // Afficher un snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.userName}: "$randomMessage"'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// 🆕 NOUVEAU: Réinitialiser la conversation avec des exemples
  Future<void> _resetConversationWithExamples() async {
    // Supprimer tous les messages existants
    await _dbHelper.deleteMessages(widget.userId);
    
    // Créer une conversation exemple
    await _dbHelper.insertMessage(widget.userId, 'Salut! Comment ça va?', false); // Autre
    await Future.delayed(const Duration(milliseconds: 100));
    
    await _dbHelper.insertMessage(widget.userId, 'Ça va bien, merci! Et toi?', true); // Moi
    await Future.delayed(const Duration(milliseconds: 100));
    
    await _dbHelper.insertMessage(widget.userId, 'Super! Tu es libre ce soir?', false); // Autre
    await Future.delayed(const Duration(milliseconds: 100));
    
    await _dbHelper.insertMessage(widget.userId, 'Oui, on peut se voir!', true); // Moi
    await Future.delayed(const Duration(milliseconds: 100));
    
    await _dbHelper.insertMessage(widget.userId, 'Parfait! À quelle heure?', false); // Autre
    await Future.delayed(const Duration(milliseconds: 100));
    
    await _dbHelper.insertMessage(widget.userId, '19h ça te va?', true); // Moi
    await Future.delayed(const Duration(milliseconds: 100));
    
    await _dbHelper.insertMessage(widget.userId, 'Parfait! À ce soir 👋', false); // Autre
    
    // Recharger
    await _loadMessages();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Conversation réinitialisée avec exemples!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: const TextStyle(color: Colors.deepPurple, fontSize: 18),
            ),
            // Typing indicator dans l'AppBar
            if (otherUserIsTyping && !sendAsMe)
              const Text(
                'est en train d\'écrire...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (isTyping && sendAsMe)
              Text(
                '${widget.userName} voit que vous écrivez...',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Indicateur du mode actuel
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: sendAsMe ? Colors.deepPurple.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                sendAsMe ? 'MOI' : widget.userName.split(' ')[0].toUpperCase(),
                style: TextStyle(
                  color: sendAsMe ? Colors.deepPurple : Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Switch user button
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.deepPurple),
            tooltip: 'Changer d\'expéditeur',
            onPressed: () {
              setState(() {
                sendAsMe = !sendAsMe;
                isTyping = false;
                otherUserIsTyping = false;
              });
              _typingTimer?.cancel();
              _simulateTypingTimer?.cancel();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        sendAsMe ? Icons.person : Icons.person_outline,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sendAsMe 
                            ? '💬 Vous envoyez maintenant' 
                            : '💬 ${widget.userName} envoie maintenant',
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: sendAsMe ? Colors.deepPurple : Colors.orange,
                ),
              );
            },
          ),
        
          // Menu avec options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.deepPurple),
            onSelected: (value) async {
              if (value == 'debug') {
                print('\n🔍 === MESSAGE PAGE DEBUG ===');
                print('User: ${widget.userName} (${widget.userId})');
                print('Messages count: ${messages.length}');
                print('Send mode: ${sendAsMe ? "MOI" : widget.userName}');
                
                await _dbHelper.printAllMessages();
                await _dbHelper.printDatabaseStats();
                
                final path = await _dbHelper.getDatabasePath();
                print('📍 Database: $path');
                print('=========================\n');
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voir la console')),
                  );
                }
              } else if (value == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer les messages?'),
                    content: const Text('Tous les messages seront supprimés.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await _dbHelper.deleteMessages(widget.userId);
                  await _loadMessages();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Messages supprimés')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Debug'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Supprimer tout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Aucun message",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Commencez la conversation avec ${widget.userName}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _simulateReceivedMessage,
                              icon: const Icon(Icons.mail),
                              label: const Text('Simuler message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length + (otherUserIsTyping && !sendAsMe ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Typing indicator bubble
                      if (index == messages.length && otherUserIsTyping && !sendAsMe) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _TypingIndicator(),
                          ),
                        );
                      }

                      final msg = messages[index];
                      final messageIsMe = msg['isMe'] == 1; // 🔥 Utiliser la valeur de la DB
                      final timestamp = DateTime.parse(msg['timestamp']);
                      final messageId = msg['id'];

                      return Align(
                        alignment: messageIsMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!messageIsMe) 
                                const SizedBox(width: 8),
                              
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: messageIsMe
                                        ? Colors.deepPurple.shade100
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['text'],
                                        style: TextStyle(
                                          color: messageIsMe
                                              ? Colors.deepPurple[900]
                                              : Colors.black87,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTimestamp(timestamp),
                                            style: TextStyle(
                                              color: messageIsMe
                                                  ? Colors.deepPurple[700]
                                                  : Colors.grey[600],
                                              fontSize: 10,
                                            ),
                                          ),
                                          if (messageIsMe) // Only show menu for my messages
                                            PopupMenuButton<String>(
                                              padding: EdgeInsets.zero,
                                              icon: Icon(
                                                Icons.more_vert,
                                                size: 16,
                                                color: messageIsMe
                                                    ? Colors.deepPurple[700]
                                                    : Colors.grey[600],
                                              ),
                                              onSelected: (value) async {
                                                if (value == 'edit') {
                                                  await _editMessage(messageId, msg['text']);
                                                } else if (value == 'delete') {
                                                  await _deleteMessage(messageId);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit, size: 18, color: Colors.blue),
                                                      SizedBox(width: 8),
                                                      Text('Modifier'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Supprimer'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              if (messageIsMe) 
                                const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Typing indicator bar
          if (otherUserIsTyping && !sendAsMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.orange,
                    child: Text(
                      widget.userName[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.userName} est en train d\'écrire',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TypingIndicator(),
                ],
              ),
            ),
          
          const Divider(height: 1),
          
          // Input area
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: sendAsMe 
                          ? "Tapez votre message..."
                          : "Message de ${widget.userName}...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: sendAsMe ? Colors.deepPurple : Colors.orange,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: sendAsMe ? Colors.deepPurple : Colors.orange,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: sendAsMe ? Colors.deepPurple : Colors.orange,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else {
      final day = timestamp.day.toString().padLeft(2, '0');
      final month = timestamp.month.toString().padLeft(2, '0');
      return '$day/$month';
    }
  }
}

/// Widget pour l'animation des points "..."
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (value * 2).clamp(0.0, 1.0);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity > 0.5 ? 1.0 - (opacity - 0.5) * 2 : opacity * 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

}
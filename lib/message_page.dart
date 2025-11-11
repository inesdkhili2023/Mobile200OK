import 'package:flutter/material.dart';
import 'dart:async';
import 'database_helper.dart';
import 'notification_service.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  bool sendAsMe = true;
  
  // Editing state
  int? _editingMessageId;
  final TextEditingController _editController = TextEditingController();
  
  // Typing indicator state
  bool isTyping = false;
  bool otherUserIsTyping = false;
  Timer? _typingTimer;
  Timer? _simulateTypingTimer;

  // États pour médias
  bool isRecording = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  late FlutterSoundRecorder _audioRecorder;
  String? _audioPath;

  // États pour la lecture audio
  late FlutterSoundPlayer _audioPlayer;
  bool _isPlaying = false;
  int? _currentlyPlayingMessageId;
  double _playbackPosition = 0.0;
  double _playbackDuration = 0.0;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    
    _controller.addListener(_onTextChanged);
    _notificationService.cancelNotification(widget.userId);

    // Initialiser l'enregistreur ET le lecteur audio
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = FlutterSoundPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioRecorder.openRecorder();
      await _audioPlayer.openPlayer();
      
      _audioPlayer.onProgress!.listen((e) {
        if (mounted && _isPlaying) {
          setState(() {
            _playbackPosition = e.position.inSeconds.toDouble();
          });
          
          // Arrêter automatiquement quand la lecture est terminée
          if (e.position.inSeconds >= _playbackDuration) {
            _stopPlayback();
          }
        }
      });
      
    } catch (e) {
      print('Erreur initialisation audio: $e');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _editController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _simulateTypingTimer?.cancel();
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    
    // Fermer les ressources audio
    _audioRecorder.closeRecorder();
    _audioPlayer.closePlayer();
    
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
    
    await _dbHelper.insertMessage(widget.userId, messageText, sendAsMe);

    // Mettre à jour le dernier message dans la table chats
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await _dbHelper.updateLastMessage(widget.userId, messageText, time);

    _controller.clear();
    await _loadMessages();
  }

  /// 🎤 Méthode pour démarrer l'enregistrement vocal
  Future<void> _startRecording() async {
    // Demander la permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission microphone requise'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    try {
      // Créer le fichier audio
      final directory = await getTemporaryDirectory();
      _audioPath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      await _audioRecorder.startRecorder(
        toFile: _audioPath,
        codec: Codec.aacADTS,
      );
      
      setState(() {
        isRecording = true;
        _recordingDuration = 0;
      });
      
      // Timer pour afficher la durée
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
      
    } catch (e) {
      print('Erreur enregistrement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'enregistrement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ⏹️ Méthode pour arrêter l'enregistrement
  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    
    try {
      await _audioRecorder.stopRecorder();
      
      if (_recordingDuration >= 1 && _audioPath != null) {
        // Sauvegarder le fichier audio
        await _sendVoiceMessage(_recordingDuration, _audioPath!);
      }
      
    } catch (e) {
      print('Erreur arrêt enregistrement: $e');
    }
    
    setState(() {
      isRecording = false;
      _recordingDuration = 0;
    });
  }

  /// 📸 MÉTHODE CORRIGÉE POUR SÉLECTIONNER UNE IMAGE
  Future<void> _pickImage() async {
    print('🚀 Ouverture de la galerie...');
    
    try {
      // Vérifier les permissions
      final PermissionStatus status = await Permission.photos.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission galerie requise'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        print('ℹ️ Aucune image sélectionnée');
        return;
      }

      String imagePath = image.path;
      print('✅ IMAGE SÉLECTIONNÉE: $imagePath');
      
      // Vérifier que le fichier existe
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Fichier image introuvable après sélection');
      }
      
      // Envoyer le message
      await _sendImageMessage(imagePath);
      
      // Confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📷 Image envoyée !'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      print('💥 ERREUR Galerie: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur galerie: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📨 Envoyer un message image
  Future<void> _sendImageMessage(String imagePath) async {
    try {
      final String messageText = "📷 Image";
      
      // Sauvegarder aussi le chemin de l'image pour l'affichage futur
      await _dbHelper.insertMessage(widget.userId, messageText, sendAsMe, audioPath: imagePath);
      
      // Mettre à jour le dernier message
      final now = DateTime.now();
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await _dbHelper.updateLastMessage(widget.userId, messageText, time);
      
      await _loadMessages();
      
    } catch (e) {
      print('Erreur envoi image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🎵 Envoyer un message vocal
  Future<void> _sendVoiceMessage(int duration, String audioPath) async {
    final String messageText = "🎵 Message vocal (${duration}s)";
    
    // Sauvegarder le chemin du fichier audio dans la base de données
    await _dbHelper.insertMessage(widget.userId, messageText, sendAsMe, audioPath: audioPath);
    
    // Mettre à jour le dernier message
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await _dbHelper.updateLastMessage(widget.userId, messageText, time);
    
    await _loadMessages();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎵 Message vocal envoyé (${duration}s)'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// Méthode pour lire un message vocal
  Future<void> _playVoiceMessage(int messageId, String messageText, String? audioPath) async {
    try {
      print('🎵 Tentative lecture - ID: $messageId, Path: $audioPath');
      
      // Si un message est déjà en cours de lecture, l'arrêter
      if (_isPlaying) {
        await _stopPlayback();
        if (_currentlyPlayingMessageId == messageId) {
          return; // C'était le même message, on veut juste l'arrêter
        }
      }

      // Vérifier que le fichier existe
      if (audioPath == null || !await File(audioPath).exists()) {
        print('❌ Fichier audio introuvable: $audioPath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fichier audio introuvable'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Extraire la durée du message
      final durationMatch = RegExp(r'\((\d+)s\)').firstMatch(messageText);
      final duration = int.tryParse(durationMatch?.group(1) ?? '0') ?? 0;
      
      setState(() {
        _isPlaying = true;
        _currentlyPlayingMessageId = messageId;
        _playbackDuration = duration.toDouble();
        _playbackPosition = 0.0;
      });

      print('🎵 Lancement lecture: $audioPath');
      await _audioPlayer.startPlayer(
        fromURI: audioPath,
        codec: Codec.aacADTS,
      );
      
      _startPlaybackTimer(duration);

    } catch (e) {
      print('❌ Erreur lecture audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la lecture'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _stopPlayback();
    }
  }

  /// Timer de progression pour la lecture
  void _startPlaybackTimer(int duration) {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_playbackPosition >= _playbackDuration) {
        timer.cancel();
        _stopPlayback();
      } else {
        setState(() {
          _playbackPosition += 0.1;
        });
      }
    });
  }

  /// MÉTHODE POUR ARRÊTER LA LECTURE
  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer.stopPlayer();
      _playbackTimer?.cancel();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingMessageId = null;
        _playbackPosition = 0.0;
      });
    } catch (e) {
      print('Erreur arrêt lecture: $e');
    }
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

  /// 🆕 Méthode pour vérifier l'état des médias
  void _debugMedia() {
    print('\n🔍 === DEBUG MÉDIAS ===');
    for (var msg in messages) {
      final text = msg['text'];
      final mediaPath = msg['audioPath'];
      final isImage = text.contains("📷");
      final isVoice = text.contains("🎵");
      
      print('Message: $text');
      print('Type: ${isImage ? "IMAGE" : isVoice ? "VOICE" : "TEXT"}');
      print('Chemin: $mediaPath');
      
      if (mediaPath != null) {
        final file = File(mediaPath);
        final exists = file.existsSync();
        print('Fichier existe: $exists');
        
        if (!exists) {
          print('❌ FICHIER MANQUANT: $mediaPath');
        }
      }
      print('---');
    }
    print('====================\n');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug médias - voir la console'),
          backgroundColor: Colors.blue,
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

  /// MÉTHODE AMÉLIORÉE : Construire le contenu des messages multimédias
  Widget _buildMessageContent(Map<String, dynamic> msg) {
    final String text = msg['text'];
    final bool isImage = text.contains("📷");
    final bool isVoice = text.contains("🎵");
    final int messageId = msg['id'];
    final bool isMe = msg['isMe'] == 1;
    final String? mediaPath = msg['audioPath']; // Renommer pour plus de clarté
    
    if (isImage) {
      return _buildImageMessage(mediaPath, isMe);
    }
    
    if (isVoice) {
      return _buildVoiceMessage(messageId, text, mediaPath, isMe);
    }
    
    // Message texte normal
    return Text(
      text,
      style: TextStyle(
        color: isMe ? Colors.deepPurple[900] : Colors.black87,
        fontSize: 15,
      ),
    );
  }

  /// 🆕 Méthode dédiée pour l'affichage des images
  Widget _buildImageMessage(String? imagePath, bool isMe) {
    return GestureDetector(
      onTap: () {
        if (imagePath != null && File(imagePath).existsSync()) {
          _showFullImage(imagePath);
        } else {
          print('❌ Image non trouvée: $imagePath');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImageContent(imagePath),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 🆕 Méthode pour construire le contenu de l'image
  Widget _buildImageContent(String? imagePath) {
    if (imagePath == null) {
      return _buildImagePlaceholder();
    }
    
    final file = File(imagePath);
    if (!file.existsSync()) {
      print('⚠️ Fichier image introuvable: $imagePath');
      return _buildImagePlaceholder();
    }
    
    try {
      return Image.file(
        file,
        width: 200,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Erreur chargement image: $error');
          return _buildImagePlaceholder();
        },
      );
    } catch (e) {
      print('❌ Exception image: $e');
      return _buildImagePlaceholder();
    }
  }

  /// 🆕 Méthode dédiée pour l'affichage des messages vocaux
  Widget _buildVoiceMessage(int messageId, String text, String? audioPath, bool isMe) {
    final durationMatch = RegExp(r'\((\d+)s\)').firstMatch(text);
    final duration = durationMatch?.group(1) ?? '0';
    final bool isCurrentlyPlaying = _currentlyPlayingMessageId == messageId;
    
    return GestureDetector(
      onTap: () {
        print('🎵 Clic message vocal - ID: $messageId, Path: $audioPath');
        _playVoiceMessage(messageId, text, audioPath);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe 
              ? Colors.deepPurple.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrentlyPlaying ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton play/pause
            Icon(
              isCurrentlyPlaying && _isPlaying ? Icons.pause : Icons.play_arrow,
              color: isMe ? Colors.deepPurple : Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 8),
            
            // Contenu vocal
            if (isCurrentlyPlaying && _isPlaying) 
              _buildPlayingVoiceMessage(isMe)
            else 
              _buildStoppedVoiceMessage(duration, isMe),
          ],
        ),
      ),
    );
  }

  /// 🆕 Message vocal en cours de lecture
  Widget _buildPlayingVoiceMessage(bool isMe) {
    return Expanded(
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _playbackPosition / _playbackDuration,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isMe ? Colors.deepPurple : Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_playbackPosition.toStringAsFixed(1)}s',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${_playbackDuration.toStringAsFixed(0)}s',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🆕 Message vocal arrêté
  Widget _buildStoppedVoiceMessage(String duration, bool isMe) {
    return Row(
      children: [
        Icon(Icons.audiotrack, size: 20, color: isMe ? Colors.deepPurple : Colors.blue),
        const SizedBox(width: 8),
        Text(
          '$duration"s"',
          style: TextStyle(
            color: isMe ? Colors.deepPurple : Colors.blue,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Méthode helper pour le placeholder d'image
  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo, color: Colors.grey[600], size: 40),
          const SizedBox(height: 8),
          Text(
            'Image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Méthode pour afficher l'image en plein écran
  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  /// 🆕 Afficher les informations d'un fichier média
void _showMediaInfo(int messageId, String text, String? mediaPath) {
  final bool isVoice = text.contains("🎵");
  final bool isImage = text.contains("📷");
  
  String fileType = isVoice ? 'Audio' : 'Image';
  String fileSize = 'Inconnu';
  String fileExists = 'Non';
  
  if (mediaPath != null) {
    final file = File(mediaPath);
    if (file.existsSync()) {
      fileExists = 'Oui';
      final sizeInBytes = file.lengthSync();
      final sizeInKB = (sizeInBytes / 1024).toStringAsFixed(1);
      fileSize = '$sizeInKB KB';
    }
  }
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Infos $fileType'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type: $fileType'),
          Text('Chemin: ${mediaPath ?? 'Aucun'}'),
          Text('Taille: $fileSize'),
          Text('Fichier existe: $fileExists'),
          if (isVoice) 
            Text('Durée: ${RegExp(r'\((\d+)s\)').firstMatch(text)?.group(1) ?? '0'}s'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        if (mediaPath != null && File(mediaPath).existsSync())
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
      ],
    ),
  );
}

  /// Méthode: Construire la bulle de message complète
 /// Méthode: Construire la bulle de message complète
Widget _buildMessageBubble(Map<String, dynamic> msg) {
  final bool isMe = msg['isMe'] == 1;
  final timestamp = DateTime.parse(msg['timestamp']);
  final messageId = msg['id'];
  final String text = msg['text'];
  final bool isVoice = text.contains("🎵");
  final bool isImage = text.contains("📷");

  return Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe) const SizedBox(width: 8),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.deepPurple.shade100
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(msg),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          color: isMe
                              ? Colors.deepPurple[700]
                              : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) // ✅ PERMET LA SUPPRESSION POUR TOUS LES MESSAGES
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: isMe
                                ? Colors.deepPurple[700]
                                : Colors.grey[600],
                          ),
                          onSelected: (value) async {
                            if (value == 'edit' && !isVoice && !isImage) {
                              await _editMessage(messageId, msg['text']);
                            } else if (value == 'delete') {
                              await _deleteMessage(messageId);
                            } else if (value == 'info') {
                              _showMediaInfo(messageId, text, msg['audioPath']);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!isVoice && !isImage) // Édition seulement pour texte
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
                            if (isVoice || isImage) // Info pour les médias
                              const PopupMenuItem(
                                value: 'info',
                                child: Row(
                                  children: [
                                    Icon(Icons.info, size: 18, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Infos fichier'),
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
          
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    ),
  );
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
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.red),
            onPressed: _debugMedia,
            tooltip: 'Debug médias',
          ),
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
                        
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length + (otherUserIsTyping && !sendAsMe ? 1 : 0),
                    itemBuilder: (context, index) {
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
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),
          
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
          
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mic, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Enregistrement... $_recordingDuration"s"',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _stopRecording,
                          child: const Icon(Icons.stop, color: Colors.red, size: 24),
                        ),
                      ],
                    ),
                  ),
                
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.deepPurple),
                      tooltip: 'Envoyer une image',
                      onPressed: _pickImage,
                    ),
                    
                    IconButton(
                      icon: Icon(
                        isRecording ? Icons.stop : Icons.mic,
                        color: isRecording ? Colors.red : Colors.deepPurple,
                      ),
                      tooltip: isRecording ? 'Arrêter l\'enregistrement' : 'Message vocal',
                      onPressed: isRecording ? _stopRecording : _startRecording,
                    ),
                    
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
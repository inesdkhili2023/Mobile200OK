import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'Messages importants';

  // Initialisation des notifications
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Créer le canal de notification
    await _createNotificationChannel();
    
    print('✅ Notifications locales initialisées avec succès');
  }

  // Créer le canal de notification (CORRIGÉ)
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifications pour les nouveaux messages',
      importance: Importance.high,
      playSound: true,
    );
    
    await _notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  // Afficher une notification (SIMPLIFIÉ)
  static Future<void> showMessageNotification({
    required String title,
    required String body,
    required String chatId,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Nouveaux messages',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // ID unique
      final int messageId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      await _notifications.show(
        messageId,
        title,
        body,
        details,
        payload: json.encode({
          'chat_id': chatId,
          'type': 'new_message',
        }),
      );
      
      print('📱 Notification VISUELLE affichée: $title');
    } catch (e) {
      print('❌ Erreur affichage notification: $e');
    }
  }

 static void _onNotificationTap(NotificationResponse response) {
  print('🔔 Notification tapée: ${response.payload}');
  
  // Logique simple sans navigation globale
  if (response.payload != null) {
    try {
      final payload = json.decode(response.payload!);
      final String chatId = payload['chat_id'];
      print('🎯 Ouvrir le chat: $chatId');
      // Vous gérerez la navigation ailleurs dans votre app
    } catch (e) {
      print('❌ Erreur décodage payload: $e');
    }
  }
}

  // TEST: Méthode pour vérifier que les notifications fonctionnent
  static Future<void> testNotification() async {
    await showMessageNotification(
      title: 'Test Notification',
      body: 'Si vous voyez ceci, les notifications fonctionnent! ✅',
      chatId: 'test_chat',
    );
  }

  // Vérifier si les notifications sont activées (OPTIONNEL)
  static Future<bool> areNotificationsEnabled() async {
    try {
      final bool? result = await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled();
      
      return result ?? false;
    } catch (e) {
      print('❌ Erreur vérification permissions: $e');
      return false;
    }
  }
}
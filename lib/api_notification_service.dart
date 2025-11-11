import 'dart:convert';
import 'package:handicraft/local_notification_service.dart';
import 'package:http/http.dart' as http;

class ApiNotificationService {
  static const String _apiBaseUrl = 'https://votre-api.com';
  static const String _apiKey = 'VOTRE_CLE_API';

  // Envoyer une notification via votre API externe
  static Future<void> sendPushNotification({
    required String targetUserId,
    required String title,
    required String message,
    required String chatId,
    required String senderName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/notifications/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'target_user_id': targetUserId,
          'title': title,
          'message': message,
          'data': {
            'chat_id': chatId,
            'sender_name': senderName,
            'type': 'new_message',
            'timestamp': DateTime.now().toIso8601String(),
          },
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notification API envoyée avec succès');
        
        // Afficher aussi une notification locale (CORRIGÉ)
        await LocalNotificationService.showMessageNotification(
          title: title,
          body: message,
          chatId: chatId, // ⬅️ paramètre chatId au lieu de messageId
        );
        
      } else {
        print('❌ Erreur API notification: ${response.statusCode}');
        await _showFallbackNotification(title, message, chatId);
      }
    } catch (e) {
      print('💥 Erreur envoi notification API: $e');
      await _showFallbackNotification(title, message, chatId);
    }
  }

  static Future<void> _showFallbackNotification(
    String title, String message, String chatId
  ) async {
    // CORRIGÉ: Utilisation correcte de showMessageNotification
    await LocalNotificationService.showMessageNotification(
      title: title,
      body: message,
      chatId: chatId, // ⬅️ paramètre chatId au lieu de messageId
    );
  }

  // 🔔 NOUVELLE MÉTHODE: Test simple de l'API
  static Future<void> testApiNotification() async {
    await sendPushNotification(
      targetUserId: 'test-user-123',
      title: 'Test API Notification',
      message: 'Ceci est un test de notification API',
      chatId: 'test-chat-123',
      senderName: 'Test User',
    );
  }
}
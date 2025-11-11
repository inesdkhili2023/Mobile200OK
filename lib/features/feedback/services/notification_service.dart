import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service de notifications locales - Simule une API
/// Envoie "Merci pour votre avis" après soumission d'un feedback
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialise le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configuration Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuration globale
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialiser
    await _notifications.initialize(initSettings);

    // Demander la permission sur Android 13+
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    _isInitialized = true;
    print('✅ NotificationService initialized with permissions');
  }

  /// Envoie une notification système "Thank you for your feedback"
  /// 
  /// ⚠️ DISTINCTION IMPORTANTE pour la présentation :
  /// - ALERTE (Dialog) : Écran de confirmation affiché dans l'application
  ///   → L'utilisateur voit "Feedback Submitted" avec un bouton "Back to Home"
  /// - NOTIFICATION (System) : Message Android dans la barre de statut (ce service)
  ///   → Reste visible même si l'utilisateur quitte l'app
  ///   → Permet de rappeler à l'utilisateur que son feedback est en cours de traitement
  ///   → Simule une API backend qui enverrait une confirmation asynchrone
  Future<void> sendFeedbackThankYou() async {
    if (!_isInitialized) {
      print('⚠️ NotificationService not initialized');
      return;
    }

    // Détails Android
    const androidDetails = AndroidNotificationDetails(
      'feedback_channel',
      'Feedback Notifications',
      channelDescription: 'Notifications pour les retours utilisateurs',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    // Détails iOS
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Détails globaux
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Envoyer la notification (API simulée - notification système Android)
    // ⚠️ IMPORTANT: Cette notification apparaît dans la barre de statut Android
    // contrairement à l'écran de confirmation qui est une interface de l'app
    await _notifications.show(
      0, // ID
      '✅ Feedback Registered', // Titre
      'Thank you for your feedback! We will review it shortly.', // Message
      notificationDetails,
    );
  }
}

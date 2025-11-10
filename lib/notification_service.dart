import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ═══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 Notification clicked: ${response.payload}');
      },
    );

    _initialized = true;
    print('✅ NotificationService initialized');
  }

  // ═══════════════════════════════════════════════════════════
  // PERMISSIONS
  // ═══════════════════════════════════════════════════════════

  /// Demander les permissions (Android 13+)
  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted =
          await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    return true; // iOS gère les permissions différemment
  }

  /// Vérifier si les notifications sont activées
  Future<bool> areNotificationsEnabled() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }

    return true; // Par défaut pour iOS
  }

  // ═══════════════════════════════════════════════════════════
  // SHOW NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════

  /// Afficher une notification simple
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'chat_channel',
      'Messages',
      channelDescription: 'Notifications pour les nouveaux messages',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );

    print('📬 Notification sent: $title - $body');
  }

  /// Notification pour un nouveau message
  Future<void> showNewMessageNotification({
    required String userId,
    required String userName,
    required String message,
  }) async {
    final int notificationId = userId.hashCode;

    await showNotification(
      id: notificationId,
      title: '💬 $userName',
      body: message,
      payload: userId,
    );
  }

  /// Notification groupée (plusieurs messages)
  Future<void> showGroupedNotification({
    required String userId,
    required String userName,
    required List<String> messages,
  }) async {
    if (messages.isEmpty) return;

    final int notificationId = userId.hashCode;
    final List<String> displayMessages = messages.take(5).toList();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'chat_channel',
      'Messages',
      channelDescription: 'Notifications pour les nouveaux messages',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: InboxStyleInformation(
        displayMessages,
        contentTitle: '💬 $userName',
        summaryText:
            '${messages.length} nouveau${messages.length > 1 ? 'x' : ''} message${messages.length > 1 ? 's' : ''}',
      ),
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      '💬 $userName',
      '${messages.length} nouveau${messages.length > 1 ? 'x' : ''} message${messages.length > 1 ? 's' : ''}',
      platformDetails,
      payload: userId,
    );

    print('📬 Grouped notification sent for $userName (${messages.length} messages)');
  }

  // ═══════════════════════════════════════════════════════════
  // CANCEL NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════

  /// Annuler une notification spécifique par userId
  Future<void> cancelNotification(String userId) async {
    final int notificationId = userId.hashCode;
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    print('🔕 Notification cancelled for userId: $userId');
  }

  /// Annuler une notification par ID
  Future<void> cancelNotificationById(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    print('🔕 Notification #$id cancelled');
  }

  /// Annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('🔕 All notifications cancelled');
  }

  // ═══════════════════════════════════════════════════════════
  // QUERIES
  // ═══════════════════════════════════════════════════════════

  /// Obtenir les notifications actives
  Future<List<ActiveNotification>> getActiveNotifications() async {
    final List<ActiveNotification> activeNotifications =
        await _flutterLocalNotificationsPlugin.getActiveNotifications();
    return activeNotifications;
  }

  /// Obtenir les notifications en attente
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pendingNotifications;
  }

  /// Vérifier si une notification existe pour un userId
  Future<bool> hasActiveNotification(String userId) async {
    final activeNotifications = await getActiveNotifications();
    final notificationId = userId.hashCode;
    return activeNotifications.any((n) => n.id == notificationId);
  }

  // ═══════════════════════════════════════════════════════════
  // DEBUG & UTILITIES
  // ═══════════════════════════════════════════════════════════

  /// Afficher les statistiques des notifications
  Future<void> printNotificationStats() async {
    final active = await getActiveNotifications();
    final pending = await getPendingNotifications();
    final enabled = await areNotificationsEnabled();

    print('\n═══════════════════════════════════════');
    print('📊 NOTIFICATION STATISTICS');
    print('═══════════════════════════════════════');
    print('Initialized: $_initialized');
    print('Permissions enabled: $enabled');
    print('Active notifications: ${active.length}');
    print('Pending notifications: ${pending.length}');

    if (active.isNotEmpty) {
      print('\nActive notifications:');
      for (var notification in active) {
        print('  - ID: ${notification.id}');
        print('    Title: ${notification.title}');
        print('    Body: ${notification.body}');
      }
    }

    print('═══════════════════════════════════════\n');
  }

  /// Test de notification
  Future<void> testNotification() async {
    await showNotification(
      id: 999999,
      title: '🧪 Test Notification',
      body: 'Si vous voyez ceci, les notifications fonctionnent!',
    );
  }
}
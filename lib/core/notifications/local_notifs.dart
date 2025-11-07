import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifs {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
  }

  static Future<void> scheduleReminder(DateTime event,
      {required String title, required String body}) async {
    final when = event.subtract(const Duration(hours: 1));

    await _plugin.show(
      event.millisecondsSinceEpoch ~/ 1000, // ID unique
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'booking', 'Bookings',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

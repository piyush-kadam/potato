import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Request notification permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Initialize local notification for foreground messages
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _local.initialize(settings);

    // Get FCM token
    String? token = await _messaging.getToken();

    if (token != null) {
      await FirebaseFirestore.instance.collection('fcmTokens').doc(token).set({
        "token": token,
      });
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      _local.show(
        0,
        message.notification?.title,
        message.notification?.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });
  }
}

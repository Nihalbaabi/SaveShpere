import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../providers/notification_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  NotificationProvider? _provider;

  void setProvider(NotificationProvider provider) {
    _provider = provider;
  }

  Future<void> initializeNotifications() async {
    // Background handler
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    if (!kIsWeb) {
      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle notification tap
        },
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'energy_alerts',
        'Energy Alerts',
        description: 'Notifications for energy usage thresholds and billing updates.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      
      if (notification != null) {
        showNotification(
          notification.title ?? "Energy Alert",
          notification.body ?? "",
          type: message.data['type'] ?? 'general',
        );
      }
    });
    
    await requestPermission();
    if (!kIsWeb) {
      String? token = await getFCMToken();
      print("FCM Token: $token");
    }
  }

  Future<void> requestPermission() async {
    if (kIsWeb) return;
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<String?> getFCMToken() async {
    if (kIsWeb) return null;
    return await _fcm.getToken();
  }

  Future<void> showNotification(String title, String body, {String type = 'general'}) async {
    // Add to in-app history
    _provider?.addNotification(title, body, type);

    // Smart Energy Tip (Optional feature)
    String finalBody = body;
    if (type == 'peak' || type == 'budget') {
      finalBody += "\n💡 Tip: Run heavy appliances during off-peak hours.";
    }

    if (!kIsWeb) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'energy_alerts',
        'Energy Alerts',
        channelDescription: 'Notifications for energy usage thresholds and billing updates.',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: '@mipmap/ic_launcher',
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
            android: androidPlatformChannelSpecifics, 
            iOS: DarwinNotificationDetails()
          );

      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: finalBody,
        notificationDetails: platformChannelSpecifics,
      );
    }
  }
}

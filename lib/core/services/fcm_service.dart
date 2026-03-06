import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM: get token, store it, and listen for messages
  Future<void> initialize() async {
    // Get FCM token and store in Firestore
    await _getAndStoreToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _storeTokenInFirestore(newToken);
    });

    // Create high importance notification channel for Android
    await _createNotificationChannel();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('FCMService: Initialized successfully');
  }

  /// Get FCM token and store in Firestore
  Future<String?> _getAndStoreToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      if (token != null) {
        await _storeTokenInFirestore(token);
      }
      return token;
    } catch (e) {
      debugPrint('FCMService: Error getting token: $e');
      return null;
    }
  }

  /// Store FCM token in Firestore under the user's document
  Future<void> _storeTokenInFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        }, SetOptions(merge: true));
        debugPrint('FCMService: Token stored for user ${user.uid}');
      } else {
        debugPrint('FCMService: No user logged in, skipping token storage');
      }
    } catch (e) {
      debugPrint('FCMService: Error storing token: $e');
    }
  }

  /// Create Android notification channel for high importance notifications
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for plant care notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle foreground messages — show as local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCMService: Foreground message received');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');

    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for plant care notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['plantId'],
      );
    }
  }

  /// Handle notification tap (when app is in background)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCMService: Notification tapped');
    debugPrint('  Data: ${message.data}');
    // Navigation can be handled here if needed
  }

  /// Update token when user logs in
  Future<void> updateTokenForCurrentUser() async {
    await _getAndStoreToken();
  }

  /// Remove token when user logs out
  Future<void> removeTokenForUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': FieldValue.delete(),
        });
        debugPrint('FCMService: Token removed for user ${user.uid}');
      }
    } catch (e) {
      debugPrint('FCMService: Error removing token: $e');
    }
  }
}

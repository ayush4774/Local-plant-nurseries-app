import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const String _remindersKey = 'plant_reminders';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to specific plant
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    }
    return false;
  }

  /// Schedule a daily reminder at a specific time
  Future<int> scheduleReminder({
    required String plantId,
    required String plantName,
    required String reminderType,
    required TimeOfDay time,
    required int frequencyDays,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final reminderTypeText = _getReminderTypeText(reminderType);

    await _notifications.zonedSchedule(
      id,
      '🌱 Plant Care Reminder',
      'Time to $reminderTypeText your $plantName!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'plant_reminders',
          'Plant Care Reminders',
          channelDescription: 'Notifications for plant care reminders',
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: frequencyDays == 1
          ? DateTimeComponents.time // Daily
          : frequencyDays == 7
              ? DateTimeComponents.dayOfWeekAndTime // Weekly
              : null, // Biweekly / monthly / custom — one-shot, reschedule on open
      payload: jsonEncode({
        'plantId': plantId,
        'plantName': plantName,
        'reminderType': reminderType,
      }),
    );

    // Save reminder to local storage
    await _saveReminder(
      id: id,
      plantId: plantId,
      plantName: plantName,
      reminderType: reminderType,
      time: time,
      frequencyDays: frequencyDays,
    );

    // Sync to Firestore
    await _saveReminderToFirestore(
      id: id,
      plantId: plantId,
      plantName: plantName,
      reminderType: reminderType,
      time: time,
      frequencyDays: frequencyDays,
    );

    debugPrint(
        'Scheduled reminder $id for $plantName at ${time.hour}:${time.minute}');
    return id;
  }

  String _getReminderTypeText(String type) {
    switch (type) {
      case 'watering':
        return 'water';
      case 'fertilizing':
        return 'fertilize';
      case 'repotting':
        return 'check on';
      case 'pruning':
        return 'prune';
      default:
        return 'care for';
    }
  }

  Future<void> _saveReminder({
    required int id,
    required String plantId,
    required String plantName,
    required String reminderType,
    required TimeOfDay time,
    required int frequencyDays,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString(_remindersKey);
    List<Map<String, dynamic>> reminders = [];

    if (remindersJson != null) {
      reminders = List<Map<String, dynamic>>.from(jsonDecode(remindersJson));
    }

    reminders.add({
      'id': id,
      'plantId': plantId,
      'plantName': plantName,
      'reminderType': reminderType,
      'hour': time.hour,
      'minute': time.minute,
      'frequencyDays': frequencyDays,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_remindersKey, jsonEncode(reminders));
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString(_remindersKey);

    if (remindersJson == null) return [];

    return List<Map<String, dynamic>>.from(jsonDecode(remindersJson));
  }

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);

    // Remove from local storage
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString(_remindersKey);

    if (remindersJson != null) {
      List<Map<String, dynamic>> reminders =
          List<Map<String, dynamic>>.from(jsonDecode(remindersJson));
      reminders.removeWhere((r) => r['id'] == id);
      await prefs.setString(_remindersKey, jsonEncode(reminders));
    }

    debugPrint('Cancelled reminder $id');
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_remindersKey);

    debugPrint('Cancelled all reminders');
  }

  /// Save reminder to Firestore for server-side FCM notifications
  Future<void> _saveReminderToFirestore({
    required int id,
    required String plantId,
    required String plantName,
    required String reminderType,
    required TimeOfDay time,
    required int frequencyDays,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reminders')
          .add({
        'notificationId': id,
        'plantId': plantId,
        'plantName': plantName,
        'reminderType': reminderType,
        'hour': time.hour,
        'minute': time.minute,
        'frequencyDays': frequencyDays,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Saved reminder to Firestore for $plantName');
    } catch (e) {
      debugPrint('Error saving reminder to Firestore: $e');
    }
  }

  /// Get reminders for a specific plant
  Future<List<Map<String, dynamic>>> getRemindersForPlant(
      String plantId) async {
    final reminders = await getReminders();
    return reminders.where((r) => r['plantId'] == plantId).toList();
  }

  /// Check if a plant already has a specific reminder type
  Future<bool> hasReminder(String plantId, String reminderType) async {
    final reminders = await getRemindersForPlant(plantId);
    return reminders.any((r) => r['reminderType'] == reminderType);
  }

  /// Show an immediate notification (for testing)
  Future<void> showTestNotification() async {
    await _notifications.show(
      0,
      '🌱 Plant Care Reminder',
      'This is a test notification!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'plant_reminders',
          'Plant Care Reminders',
          channelDescription: 'Notifications for plant care reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}

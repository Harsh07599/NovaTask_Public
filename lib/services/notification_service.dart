import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../main.dart'; // For navigatorKey
import '../database/database_helper.dart';
import '../screens/task_detail_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tz_data.initializeTimeZones();

    // Get the device's timezone and set tz.local to it
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String currentTimeZone = timezoneInfo.identifier;
      debugPrint('[TimeZone] Device timezone: $currentTimeZone');
      
      try {
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
      } catch (e) {
        debugPrint('[TimeZone] Location $currentTimeZone not found in database. Trying fallbacks...');
        if (currentTimeZone == 'Asia/Calcutta') {
          tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
          debugPrint('[TimeZone] mapped Asia/Calcutta -> Asia/Kolkata');
        } else {
          tz.setLocalLocation(tz.getLocation('UTC'));
          debugPrint('[TimeZone] fallback to UTC');
        }
      }
    } catch (e) {
      debugPrint('[TimeZone] Error getting local timezone: $e. Defaulting to UTC.');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();

    // Check if app was launched from a notification
    final notificationAppLaunchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final response = notificationAppLaunchDetails!.notificationResponse;
      if (response != null) {
        _onNotificationTapped(response);
      }
    }

    _isInitialized = true;
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Alarm channel - max priority with looping (v5)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'task_alarm_channel_v5',
          'NovaTask Alarms (High Priority)',
          description: 'Alarm notifications for tasks',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
          showBadge: true,
        ),
      );

      // Reminder channel - upgraded to max priority for sound (v5)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'task_reminder_channel_v5',
          'Task Reminders',
          description: 'Reminder notifications for tasks',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('reminder_sound'),
          audioAttributesUsage: AudioAttributesUsage.alarm, // Using alarm stream for better sound reliability
          enableVibration: true,
          showBadge: true,
        ),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      final int? taskId = int.tryParse(payload);
      if (taskId != null) {
        // Find task from DB
        final db = DatabaseHelper();
        final taskValue = await db.getTask(taskId);
        if (taskValue != null) {
          // Navigate to detail screen
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: taskValue),
            ),
          );
        }
      }
    }
  }

  /// Show an immediate notification (used by background alarm callbacks)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    bool isAlarm = true,
    String? soundPath,
  }) async {
    if (!_isInitialized) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _notifications.initialize(settings: initSettings);
    }

    final db = DatabaseHelper();
    final globalSoundPath = await db.getSetting(isAlarm ? 'alarm_sound_path' : 'reminder_sound_path');
    final actualSoundPath = soundPath ?? globalSoundPath;

    final androidDetails = AndroidNotificationDetails(
      isAlarm ? 'task_alarm_channel_v5' : 'task_reminder_channel_v5',
      isAlarm ? 'NovaTask Alarms' : 'NovaTask Reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: actualSoundPath != null
          ? UriAndroidNotificationSound(actualSoundPath)
          : RawResourceAndroidNotificationSound(isAlarm ? 'alarm_sound' : 'reminder_sound'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      additionalFlags: isAlarm ? Int32List.fromList([4]) : null, // FLAG_INSISTENT = 4
      enableVibration: true,
      fullScreenIntent: isAlarm,
      category: isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      ongoing: isAlarm,
    );

    final details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: id.toString(),
    );
  }
  /// Schedule a notification at a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool isAlarm = true,
    String? soundPath,
  }) async {
    final db = DatabaseHelper();
    final globalSoundPath = await db.getSetting(isAlarm ? 'alarm_sound_path' : 'reminder_sound_path');
    final actualSoundPath = soundPath ?? globalSoundPath;

    final androidDetails = AndroidNotificationDetails(
      isAlarm ? 'task_alarm_channel_v5' : 'task_reminder_channel_v5',
      isAlarm ? 'NovaTask Alarms' : 'NovaTask Reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: actualSoundPath != null
          ? UriAndroidNotificationSound(actualSoundPath)
          : RawResourceAndroidNotificationSound(isAlarm ? 'alarm_sound' : 'reminder_sound'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      additionalFlags: isAlarm ? Int32List.fromList([4]) : null, // FLAG_INSISTENT = 4
      enableVibration: true,
      fullScreenIntent: isAlarm,
      category: isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      ongoing: isAlarm,
    );

    final details = NotificationDetails(android: androidDetails);
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    if (tzTime.isAfter(tz.TZDateTime.now(tz.local))) {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: id.toString(),
      );
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Request notification permissions for Android 13+
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }
}

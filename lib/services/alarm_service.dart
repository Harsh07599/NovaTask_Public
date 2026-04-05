import 'dart:typed_data';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task.dart' as model;
import '../database/database_helper.dart';

/// Top-level callback functions for android_alarm_manager_plus.
/// These MUST be top-level or static — they run in a background isolate.

/// Called when an ALARM fires (one-time alarm at exact due time)
@pragma('vm:entry-point')
Future<void> alarmCallback(int alarmId) async {
  // alarmId = task.id
  final db = DatabaseHelper();
  final task = await db.getTask(alarmId);

  if (task == null || task.isCompleted) return;

  final globalSoundPath = await db.getSetting('alarm_sound_path');
  final soundPath = (globalSoundPath != null && globalSoundPath.isNotEmpty)
      ? globalSoundPath
      : task.soundPath;

  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings: initSettings);

  final priorityEmoji = _getPriorityEmoji(task.priority);

  final androidDetails = AndroidNotificationDetails(
    'task_alarm_channel_v5',
    'NovaTask Alarms (Persistent)',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    sound: soundPath != null
        ? UriAndroidNotificationSound(soundPath)
        : const RawResourceAndroidNotificationSound('alarm_sound'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
    additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT = 4 (looping)
    enableVibration: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    autoCancel: true,
    ongoing: true,
  );

  await plugin.show(
    id: alarmId,
    title: '$priorityEmoji ALARM: ${task.title}',
    body: task.description.isNotEmpty
        ? task.description
        : 'Your alarm is ringing! Tap to view.',
    notificationDetails: NotificationDetails(android: androidDetails),
    payload: alarmId.toString(),
  );
}

/// Called when a REMINDER fires (repeating every N minutes)
@pragma('vm:entry-point')
Future<void> reminderCallback(int alarmId) async {
  // alarmId = task.id + 100000 (offset to avoid conflicts)
  final taskId = alarmId - 100000;
  final db = DatabaseHelper();
  final task = await db.getTask(taskId);

  if (task == null || task.isCompleted) {
    // Task done or deleted — cancel this repeating alarm
    await AndroidAlarmManager.cancel(alarmId);
    return;
  }

  final globalSoundPath = await db.getSetting('reminder_sound_path');
  final soundPath = (globalSoundPath != null && globalSoundPath.isNotEmpty)
      ? globalSoundPath
      : task.soundPath;

  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings: initSettings);

  final priorityEmoji = _getPriorityEmoji(task.priority);

  // Upgraded reminder to max importance and alarm usage for sound reliability
  final androidDetails = AndroidNotificationDetails(
    'task_reminder_channel_v5',
    'Task Reminders',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    sound: soundPath != null
        ? UriAndroidNotificationSound(soundPath)
        : const RawResourceAndroidNotificationSound('reminder_sound'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
    enableVibration: true,
    category: AndroidNotificationCategory.reminder,
    visibility: NotificationVisibility.public,
    autoCancel: true,
  );

  await plugin.show(
    id: taskId + 10000,
    title: '$priorityEmoji REMINDER: ${task.title}',
    body: task.description.isNotEmpty
        ? '${task.description}\n⏰ Every ${task.reminderIntervalMinutes} min until done'
        : '⏰ Repeating every ${task.reminderIntervalMinutes} min until done',
    notificationDetails: NotificationDetails(android: androidDetails),
    payload: taskId.toString(),
  );
}

String _getPriorityEmoji(model.Priority priority) {
  switch (priority) {
    case model.Priority.high:
      return '🔴';
    case model.Priority.medium:
      return '🟡';
    case model.Priority.low:
      return '🟢';
  }
}

/// Service that schedules alarms using android_alarm_manager_plus.
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  /// Initialize the alarm manager (call once at app startup)
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  /// Schedule a one-time alarm for a task at its exact due time
  Future<void> scheduleAlarm(model.Task task) async {
    if (task.id == null) return;
    if (task.taskType != model.TaskType.alarm) return;

    final now = DateTime.now();
    if (task.dueDateTime.isBefore(now)) return;

    // Cancel any existing alarm for this task first
    await cancelAlarm(task.id!);

    await AndroidAlarmManager.oneShotAt(
      task.dueDateTime,
      task.id!, // alarmId = task.id
      alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  /// Cancel an alarm for a specific task
  Future<void> cancelAlarm(int taskId) async {
    await AndroidAlarmManager.cancel(taskId);
  }

  /// Reschedule alarm (cancel old + schedule new)
  Future<void> rescheduleAlarm(model.Task task) async {
    await cancelAlarm(task.id!);
    await scheduleAlarm(task);
  }
}

/// Service that schedules repeating reminders using android_alarm_manager_plus.
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  /// Schedule a repeating reminder for a task
  Future<void> scheduleReminder(model.Task task) async {
    if (task.id == null) return;
    if (task.taskType != model.TaskType.reminder) return;

    final alarmId = task.id! + 100000; // offset to avoid alarm ID conflicts

    // Cancel any existing reminder
    await cancelReminder(task.id!);

    final now = DateTime.now();
    final dueTime = task.dueDateTime;

    if (dueTime.isAfter(now)) {
      // Schedule the periodic repeating alarm starting at due time
      await AndroidAlarmManager.periodic(
        Duration(minutes: task.reminderIntervalMinutes),
        alarmId,
        reminderCallback,
        startAt: dueTime,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    } else {
      // Due time already passed — start repeating immediately
      await AndroidAlarmManager.periodic(
        Duration(minutes: task.reminderIntervalMinutes),
        alarmId,
        reminderCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    }
  }

  /// Cancel a reminder
  Future<void> cancelReminder(int taskId) async {
    await AndroidAlarmManager.cancel(taskId + 100000);
    // Also cancel the notification
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(id: taskId + 10000);
  }
}

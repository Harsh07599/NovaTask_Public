import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import '../services/alarm_service.dart';
import '../services/recurring_service.dart';
import '../services/sync_service.dart';
import '../services/firebase_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AlarmService _alarmService = AlarmService();
  final ReminderService _reminderService = ReminderService();
  final RecurringService _recurringService = RecurringService();
  final SyncService _syncService = SyncService();
  final FirebaseService _firebaseService = FirebaseService();

  List<Task> _tasks = [];
  String _sortBy = 'date';
  bool _sortAscending = true;
  String? _filterCategory;
  Priority? _filterPriority;
  TaskType? _filterTaskType;
  bool _isLoading = false;

  // Getters
  List<Task> get tasks => _tasks;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  String? get filterCategory => _filterCategory;
  Priority? get filterPriority => _filterPriority;
  TaskType? get filterTaskType => _filterTaskType;
  bool get isLoading => _isLoading;

  int get totalTasks => _tasks.length;
  int get highPriorityCount => _tasks.where((t) => t.priority == Priority.high).length;
  int get alarmCount => _tasks.where((t) => t.taskType == TaskType.alarm).length;
  int get reminderCount => _tasks.where((t) => t.taskType == TaskType.reminder).length;

  bool get hasActiveFilters =>
      _filterCategory != null ||
      _filterPriority != null ||
      _filterTaskType != null;

  /// Load all tasks from DB with current filters/sort
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    _tasks = await _dbHelper.getAllTasks(
      sortBy: _sortBy,
      ascending: _sortAscending,
      filterCategory: _filterCategory,
      filterPriority: _filterPriority,
      filterTaskType: _filterTaskType,
    );

    debugPrint('[TaskProvider] Loaded ${_tasks.length} tasks (Filters: cat=$_filterCategory, prio=$_filterPriority, type=$_filterTaskType)');
    _isLoading = false;
    notifyListeners();
  }

  /// Add a new task, schedule alarm/reminder, return the task ID
  Future<int> addTask(Task task) async {
    final now = DateTime.now();
    final taskWithSync = task.copyWith(isSynced: false, lastModified: now);
    final id = await _dbHelper.insertTask(taskWithSync);
    final savedTask = taskWithSync.copyWith(id: id);

    // Schedule alarm or reminder
    if (savedTask.taskType == TaskType.alarm) {
      await _alarmService.scheduleAlarm(savedTask);
    } else {
      await _reminderService.scheduleReminder(savedTask);
    }

    await loadTasks();
    debugPrint('[TaskProvider] Task added with ID: $id. Total tasks now: ${_tasks.length}');
    _triggerSync();
    return id;
  }

  /// Update an existing task, reschedule notifications
  Future<void> updateTask(Task task) async {
    final now = DateTime.now();
    final taskWithSync = task.copyWith(isSynced: false, lastModified: now);
    await _dbHelper.updateTask(taskWithSync);

    // Cancel old and reschedule
    if (task.taskType == TaskType.alarm) {
      await _alarmService.rescheduleAlarm(task);
    } else {
      await _reminderService.cancelReminder(task.id!);
      await _reminderService.scheduleReminder(task);
    }

    await loadTasks();
    _triggerSync();
  }

  /// Delete a task and cancel its notifications
  Future<void> deleteTask(int id) async {
    final task = await _dbHelper.getTask(id);
    if (task != null) {
      await _alarmService.cancelAlarm(id);
      await _reminderService.cancelReminder(id);
      // Delete from Firebase if synced
      if (task.firebaseId != null && task.firebaseId!.isNotEmpty) {
        try {
          if (await _syncService.isOnline()) {
            await _firebaseService.deleteTask(task.firebaseId!);
          }
        } catch (_) {}
      }
    }
    await _dbHelper.deleteTask(id);
    await loadTasks();
  }

  /// Mark a task as complete
  Future<void> completeTask(Task task) async {
    // Cancel notifications
    await _alarmService.cancelAlarm(task.id!);
    await _reminderService.cancelReminder(task.id!);

    // If recurring, create next occurrence
    if (task.recurringType != RecurringType.none) {
      final newTaskId = await _recurringService.createNextOccurrence(task);
      if (newTaskId != null) {
        final newTask = await _dbHelper.getTask(newTaskId);
        if (newTask != null) {
          if (newTask.taskType == TaskType.alarm) {
            await _alarmService.scheduleAlarm(newTask);
          } else {
            await _reminderService.scheduleReminder(newTask);
          }
        }
      }
    }

    // Delete from Firebase if synced
    if (task.firebaseId != null && task.firebaseId!.isNotEmpty) {
      try {
        if (await _syncService.isOnline()) {
          await _firebaseService.deleteTask(task.firebaseId!);
        }
      } catch (_) {}
    }

    // Permanently delete the completed task
    await _dbHelper.deleteTask(task.id!);
    await loadTasks();
  }

  /// Set sort method
  void setSort(String sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) _sortAscending = ascending;
    loadTasks();
  }

  /// Toggle sort direction
  void toggleSortDirection() {
    _sortAscending = !_sortAscending;
    loadTasks();
  }

  /// Set filter
  void setFilter({
    String? category,
    Priority? priority,
    TaskType? taskType,
  }) {
    _filterCategory = category;
    _filterPriority = priority;
    _filterTaskType = taskType;
    loadTasks();
  }

  /// Clear all filters
  void clearFilters() {
    _filterCategory = null;
    _filterPriority = null;
    _filterTaskType = null;
    loadTasks();
  }

  /// Reschedule all active alarms (used after boot)
  Future<void> rescheduleAllAlarms() async {
    final activeTasks = await _dbHelper.getActiveTasks();
    for (final task in activeTasks) {
      if (task.taskType == TaskType.alarm) {
        await _alarmService.scheduleAlarm(task);
      } else {
        await _reminderService.scheduleReminder(task);
      }
    }
  }

  /// Trigger a background sync (fire and forget)
  void _triggerSync() {
    _syncService.syncAll().then((_) => loadTasks());
  }
}

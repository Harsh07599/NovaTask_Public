import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/routine.dart';
import '../models/task.dart'; // For RecurringType
import '../services/sync_service.dart';
import '../services/firebase_service.dart';

class RoutineProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();

  List<RoutineGroup> _groups = [];
  Map<int, List<RoutineItem>> _itemsMap = {}; // groupId -> items
  Map<int, Map<String, int>> _counts = {}; // groupId -> {total, completed}
  Map<int, bool> _itemsLoadingMap = {}; // groupId -> isLoading

  List<RoutineGroup> get groups => _groups;
  List<RoutineItem> getItemsCached(int groupId) => _itemsMap[groupId] ?? [];
  bool isItemsLoading(int groupId) => _itemsLoadingMap[groupId] ?? false;
  
  Map<String, int> getCounts(int groupId) {
    return _counts[groupId] ?? {'total': 0, 'completed': 0};
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<List<RoutineItem>> getItems(int groupId) async {
    if (_itemsMap.containsKey(groupId)) return _itemsMap[groupId]!;
    
    _itemsLoadingMap[groupId] = true;
    notifyListeners();

    try {
      final items = await _dbHelper.getRoutineItems(groupId);
      _itemsMap[groupId] = items;
      return items;
    } finally {
      _itemsLoadingMap[groupId] = false;
      notifyListeners();
    }
  }

  Future<void> loadRoutines() async {
    _isLoading = true;
    notifyListeners();

    _groups = await _dbHelper.getRoutineGroups();
    
    // Check and reset based on midnight
    await _checkAndResetAll();

    // Reload groups and counts
    _groups = await _dbHelper.getRoutineGroups();
    _counts = await _dbHelper.getRoutineItemCounts();
    
    // Clear itemsMap to force a fresh fetch from DB with new firebaseIds
    _itemsMap.clear();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _checkAndResetAll() async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    for (var i = 0; i < _groups.length; i++) {
      final group = _groups[i];
      if (group.frequency == RecurringType.none) continue;

      bool shouldReset = false;
      final lastReset = group.lastResetDate;

      if (lastReset.isBefore(todayMidnight)) {
        switch (group.frequency) {
          case RecurringType.daily:
            shouldReset = true;
            break;
          case RecurringType.weekly:
            if (now.difference(lastReset).inDays >= 7) {
              shouldReset = true;
            }
            break;
          case RecurringType.monthly:
            if (now.year > lastReset.year || now.month > lastReset.month) {
              shouldReset = true;
            }
            break;
          case RecurringType.yearly:
            if (now.year > lastReset.year) {
              shouldReset = true;
            }
            break;
          default:
            break;
        }
      }

      if (shouldReset) {
        await _dbHelper.resetRoutineItems(group.id!);
        final updatedGroup = group.copyWith(
          lastResetDate: todayMidnight,
          isSynced: false,
          lastModified: DateTime.now(),
        );
        await _dbHelper.updateRoutineGroup(updatedGroup);
      }
    }
  }

  Future<void> addGroup(String title, RecurringType freq) async {
    final now = DateTime.now();
    final group = RoutineGroup(
      title: title,
      frequency: freq,
      lastResetDate: now,
      isSynced: false,
      lastModified: now,
    );
    final id = await _dbHelper.insertRoutineGroup(group);
    _groups.add(group.copyWith(id: id));
    notifyListeners();
    _triggerSync();
  }

  Future<void> updateGroup(RoutineGroup group) async {
    final updatedGroup = group.copyWith(
      isSynced: false,
      lastModified: DateTime.now(),
    );
    await _dbHelper.updateRoutineGroup(updatedGroup);
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = updatedGroup;
      notifyListeners();
    }
    _triggerSync();
  }

  Future<void> deleteGroup(int id) async {
    final group = _groups.firstWhere((g) => g.id == id, orElse: () => _groups.first);
    if (group.id == id && group.firebaseId != null && group.firebaseId!.isNotEmpty) {
      try {
        if (await _syncService.isOnline()) {
          final FirebaseService firebaseService = FirebaseService();
          await firebaseService.deleteRoutineGroup(group.firebaseId!);
        }
      } catch (_) {}
    }
    
    await _dbHelper.deleteRoutineGroup(id);
    _groups.removeWhere((g) => g.id == id);
    _itemsMap.remove(id);
    notifyListeners();
  }

  Future<void> addItem(int groupId, String title) async {
    final now = DateTime.now();
    final item = RoutineItem(
      groupId: groupId,
      title: title,
      isSynced: false,
      lastModified: now,
    );
    final id = await _dbHelper.insertRoutineItem(item);
    if (_itemsMap.containsKey(groupId)) {
      _itemsMap[groupId]!.add(item.copyWith(id: id));
    } else {
      await getItems(groupId);
    }
    
    // Update local counts
    _counts = await _dbHelper.getRoutineItemCounts();
    notifyListeners();
    _triggerSync();
  }

  Future<void> toggleItem(RoutineItem item) async {
    final now = DateTime.now();
    final dateStr = _formatDate(now);
    
    final updatedItem = item.copyWith(
      isCompleted: !item.isCompleted,
      isSynced: false,
      lastModified: now,
    );
    await _dbHelper.updateRoutineItem(updatedItem);
    
    // Upsert into routine_logs for historical tracking
    final log = RoutineLog(
      itemId: item.id!,
      date: dateStr,
      isCompleted: updatedItem.isCompleted,
      isSynced: false,
      lastModified: now,
    );
    await _dbHelper.upsertRoutineLog(log);
    
    if (_itemsMap.containsKey(item.groupId)) {
      final list = _itemsMap[item.groupId]!;
      final index = list.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        list[index] = updatedItem;
      }
    }
    
    // Update local counts
    _counts = await _dbHelper.getRoutineItemCounts();
    notifyListeners();
    _triggerSync();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<Map<String, dynamic>> getCompletionStats(DateTime start, DateTime end) async {
    final startDate = _formatDate(start);
    final endDate = _formatDate(end);
    
    final logs = await _dbHelper.getRoutineLogsForDateRange(startDate, endDate);
    
    int totalCompleted = 0;
    Map<String, int> byGroup = {};
    
    // Efficiently map items to groups
    final items = await _dbHelper.getAllRoutineItems();
    final itemToGroup = {for (var i in items) i.id: i.groupId};
    final groupMap = {for (var g in _groups) g.id: g.title};

    for (var log in logs) {
      if (log.isCompleted) {
        totalCompleted++;
        final groupId = itemToGroup[log.itemId];
        if (groupId != null) {
          final groupTitle = groupMap[groupId] ?? 'Unknown';
          byGroup[groupTitle] = (byGroup[groupTitle] ?? 0) + 1;
        }
      }
    }
    
    return {
      'totalCompleted': totalCompleted,
      'byGroup': byGroup,
      'logCount': logs.length,
    };
  }

  Future<void> deleteItem(RoutineItem item) async {
    if (item.firebaseId != null && item.firebaseId!.isNotEmpty) {
      try {
        if (await _syncService.isOnline()) {
          final FirebaseService firebaseService = FirebaseService();
          await firebaseService.deleteRoutineItem(item.firebaseId!);
        }
      } catch (_) {}
    }

    await _dbHelper.deleteRoutineItem(item.id!);
    if (_itemsMap.containsKey(item.groupId)) {
      _itemsMap[item.groupId]!.removeWhere((i) => i.id == item.id);
    }
    
    // Update local counts
    _counts = await _dbHelper.getRoutineItemCounts();
    notifyListeners();
  }

  void _triggerSync() {
    _syncService.syncAll().then((_) => loadRoutines());
  }
}

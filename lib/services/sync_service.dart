import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/task.dart';
import '../models/routine.dart';
import 'firebase_service.dart';

/// Service that handles bi-directional sync between SQLite and Firestore.
/// Strategy: Last Writer Wins based on lastModified timestamps.
class SyncService with ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Check if the device is online.
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Run a full sync: push local changes, then pull remote changes.
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      if (!await isOnline()) {
        debugPrint('[SyncService] Offline — skipping sync.');
        return;
      }

      debugPrint('[SyncService] Starting full sync...');

      // Push local unsynced changes to Firestore
      await _pushTasks();
      await _pushCategories();
      await _pushNotes();
      await _pushRoutineGroups();
      await _pushRoutineItems();
      await _pushRoutineLogs();

      // Pull remote changes into SQLite
      await _pullTasks();
      await _pullCategories();
      await _pullNotes();
      await _pullRoutineGroups();
      await _pullRoutineItems();
      await _pullRoutineLogs();

      debugPrint('[SyncService] Full sync complete.');
    } catch (e) {
      debugPrint('[SyncService] Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PUSH — Local → Firestore
  // ═══════════════════════════════════════════════════════════

  Future<void> _pushTasks() async {
    final unsynced = await _dbHelper.getUnsyncedTasks();
    for (final task in unsynced) {
      try {
        final firebaseId = await _firebaseService.pushTask(task);
        await _dbHelper.markTaskSynced(task.id!, firebaseId);
        debugPrint('[SyncService] Pushed task "${task.title}" → $firebaseId');
      } catch (e) {
        debugPrint('[SyncService] Failed to push task "${task.title}": $e');
      }
    }
  }

  Future<void> _pushCategories() async {
    final unsynced = await _dbHelper.getUnsyncedCategories();
    for (final cat in unsynced) {
      try {
        final firebaseId = await _firebaseService.pushCategory(cat);
        await _dbHelper.markCategorySynced(cat.id!, firebaseId);
        debugPrint('[SyncService] Pushed category "${cat.name}" → $firebaseId');
      } catch (e) {
        debugPrint('[SyncService] Failed to push category "${cat.name}": $e');
      }
    }
  }

  Future<void> _pushNotes() async {
    final unsynced = await _dbHelper.getUnsyncedNotes();
    for (final note in unsynced) {
      try {
        final firebaseId = await _firebaseService.pushNote(note);
        await _dbHelper.markNoteSynced(note.id!, firebaseId);
        debugPrint('[SyncService] Pushed note "${note.title}" → $firebaseId');
      } catch (e) {
        debugPrint('[SyncService] Failed to push note "${note.title}": $e');
      }
    }
  }

  Future<void> _pushRoutineGroups() async {
    final unsynced = await _dbHelper.getUnsyncedRoutineGroups();
    for (final group in unsynced) {
      try {
        final firebaseId = await _firebaseService.pushRoutineGroup(group);
        await _dbHelper.markRoutineGroupSynced(group.id!, firebaseId);
        debugPrint('[SyncService] Pushed routine group "${group.title}" → $firebaseId');
      } catch (e) {
        debugPrint('[SyncService] Failed to push routine group "${group.title}": $e');
      }
    }
  }

  Future<void> _pushRoutineItems() async {
    final unsynced = await _dbHelper.getUnsyncedRoutineItems();
    for (final item in unsynced) {
      try {
        // Find the parent group's firebaseId
        final groups = await _dbHelper.getRoutineGroups();
        final parentGroup = groups.firstWhere(
          (g) => g.id == item.groupId,
          orElse: () => RoutineGroup(
            title: '',
            frequency: RecurringType.none,
            lastResetDate: DateTime.now(),
          ),
        );
        final groupFirebaseId = parentGroup.firebaseId ?? '';

        final firebaseId = await _firebaseService.pushRoutineItem(item, groupFirebaseId);
        await _dbHelper.markRoutineItemSynced(item.id!, firebaseId);
        debugPrint('[SyncService] Pushed routine item "${item.title}" → $firebaseId');
      } catch (e) {
        debugPrint('[SyncService] Failed to push routine item "${item.title}": $e');
      }
    }
  }

  Future<void> _pushRoutineLogs() async {
    final unsynced = await _dbHelper.getUnsyncedRoutineLogs();
    for (final log in unsynced) {
      try {
        final items = await _dbHelper.getAllRoutineItems();
        final parentItem = items.firstWhere((i) => i.id == log.itemId, orElse: () => RoutineItem(groupId: 0, title: ''));
        final itemFirebaseId = parentItem.firebaseId ?? '';
        
        if (itemFirebaseId.isEmpty) {
          debugPrint('[SyncService] Skipping log push (parent item not synced yet)');
          continue;
        }

        final firebaseId = await _firebaseService.pushRoutineLog(log, itemFirebaseId);
        await _dbHelper.markRoutineLogSynced(log.id!, firebaseId);
        debugPrint('[SyncService] Pushed routine log for item "${parentItem.title}" → $firebaseId');
      } catch (e) {
        debugPrint('[SyncService] Failed to push routine log: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PULL — Firestore → Local
  // ═══════════════════════════════════════════════════════════

  Future<void> _pullTasks() async {
    try {
      final remoteTasks = await _firebaseService.fetchAllTasks();
      for (final remoteTask in remoteTasks) {
        final localTask = await _dbHelper.getTaskByFirebaseId(remoteTask.firebaseId!);
        if (localTask == null) {
          // New from cloud — insert locally
          final id = await _dbHelper.insertTask(remoteTask);
          await _dbHelper.markTaskSynced(id, remoteTask.firebaseId!);
          debugPrint('[SyncService] Pulled new task "${remoteTask.title}"');
        } else {
          // Exists locally — compare timestamps (last writer wins)
          if (remoteTask.lastModified.isAfter(localTask.lastModified)) {
            final updated = remoteTask.copyWith(id: localTask.id, isSynced: true);
            await _dbHelper.updateTask(updated);
            debugPrint('[SyncService] Updated local task "${updated.title}" from cloud');
          }
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to pull tasks: $e');
    }
  }

  Future<void> _pullCategories() async {
    try {
      final remoteCategories = await _firebaseService.fetchAllCategories();
      for (final remoteCat in remoteCategories) {
        final localCat = await _dbHelper.getCategoryByFirebaseId(remoteCat.firebaseId!);
        
        if (localCat == null) {
          // Check if local version already has same name but NO firebaseId
          final allLocal = await _dbHelper.getAllCategories(); // Changed to existing method
          final localByName = allLocal.where((c) => c.name == remoteCat.name).firstOrNull;
          
          if (localByName == null) {
            final id = await _dbHelper.insertCategory(remoteCat);
            await _dbHelper.markCategorySynced(id, remoteCat.firebaseId!);
            debugPrint('[SyncService] Pulled new category "${remoteCat.name}"');
          } else {
            // Update local category with remote firebaseId to link them
            final updated = localByName.copyWith(firebaseId: remoteCat.firebaseId, isSynced: true);
            await _dbHelper.updateCategory(updated);
            debugPrint('[SyncService] Linked local category "${remoteCat.name}" to cloud ID');
          }
        } else {
          // Exists locally by firebaseId — compare timestamps
          if (remoteCat.lastModified.isAfter(localCat.lastModified)) {
            final updated = remoteCat.copyWith(id: localCat.id, isSynced: true);
            await _dbHelper.updateCategory(updated);
            debugPrint('[SyncService] Updated local category "${updated.name}" from cloud');
          }
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to pull categories: $e');
    }
  }

  Future<void> _pullNotes() async {
    try {
      final remoteNotes = await _firebaseService.fetchAllNotes();
      for (final remoteNote in remoteNotes) {
        final localNote = await _dbHelper.getNoteByFirebaseId(remoteNote.firebaseId!);
        if (localNote == null) {
          final id = await _dbHelper.insertNote(remoteNote);
          await _dbHelper.markNoteSynced(id, remoteNote.firebaseId!);
          debugPrint('[SyncService] Pulled new note "${remoteNote.title}"');
        } else {
          if (remoteNote.lastModified.isAfter(localNote.lastModified)) {
            final updated = remoteNote.copyWith(id: localNote.id, isSynced: true);
            await _dbHelper.updateNote(updated);
            debugPrint('[SyncService] Updated local note "${updated.title}" from cloud');
          }
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to pull notes: $e');
    }
  }

  Future<void> _pullRoutineGroups() async {
    try {
      final remoteGroups = await _firebaseService.fetchAllRoutineGroups();
      for (final remoteGroup in remoteGroups) {
        final localGroup = await _dbHelper.getRoutineGroupByFirebaseId(remoteGroup.firebaseId!);
        if (localGroup == null) {
          final id = await _dbHelper.insertRoutineGroup(remoteGroup);
          await _dbHelper.markRoutineGroupSynced(id, remoteGroup.firebaseId!);
          debugPrint('[SyncService] Pulled new routine group "${remoteGroup.title}"');
        } else {
          if (remoteGroup.lastModified.isAfter(localGroup.lastModified)) {
            final updated = remoteGroup.copyWith(id: localGroup.id, isSynced: true);
            await _dbHelper.updateRoutineGroup(updated);
            debugPrint('[SyncService] Updated local routine group "${updated.title}" from cloud');
          }
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to pull routine groups: $e');
    }
  }

  Future<void> _pullRoutineItems() async {
    try {
      final remoteItemsRaw = await _firebaseService.fetchAllRoutineItems();
      for (final rawData in remoteItemsRaw) {
        final docId = rawData['docId'] as String;
        final groupFirebaseId = rawData['groupFirebaseId'] as String? ?? '';

        // Find the local group by its firebaseId
        final localGroup = groupFirebaseId.isNotEmpty
            ? await _dbHelper.getRoutineGroupByFirebaseId(groupFirebaseId)
            : null;
        if (localGroup == null) {
          debugPrint('[SyncService] Skipping routine item (parent group not found locally)');
          continue;
        }

        final remoteItem = RoutineItem.fromFirestore(rawData, docId, localGroup.id!);
        final localItem = await _dbHelper.getRoutineItemByFirebaseId(docId);

        if (localItem == null) {
          final id = await _dbHelper.insertRoutineItem(remoteItem);
          await _dbHelper.markRoutineItemSynced(id, docId);
          debugPrint('[SyncService] Pulled new routine item "${remoteItem.title}"');
        } else {
          if (remoteItem.lastModified.isAfter(localItem.lastModified)) {
            final updated = remoteItem.copyWith(id: localItem.id, isSynced: true);
            await _dbHelper.updateRoutineItem(updated);
            debugPrint('[SyncService] Updated local routine item "${updated.title}" from cloud');
          }
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to pull routine items: $e');
    }
  }

  Future<void> _pullRoutineLogs() async {
    try {
      final remoteLogsRaw = await _firebaseService.fetchAllRoutineLogs();
      for (final rawData in remoteLogsRaw) {
        final docId = rawData['docId'] as String;
        final itemFirebaseId = rawData['itemId'] as String? ?? '';

        final localItem = itemFirebaseId.isNotEmpty
            ? await _dbHelper.getRoutineItemByFirebaseId(itemFirebaseId)
            : null;
        
        if (localItem == null) {
          debugPrint('[SyncService] Skipping routine log (parent item not found locally)');
          continue;
        }

        final remoteLog = RoutineLog.fromFirestore(rawData, docId, localItem.id!);
        final localLog = await _dbHelper.getRoutineLogByFirebaseId(docId);

        if (localLog == null) {
          // Check if log exists for same item and date but without firebaseId
          final existingLog = await _dbHelper.getRoutineLog(localItem.id!, remoteLog.date);
          if (existingLog == null) {
            await _dbHelper.upsertRoutineLog(remoteLog);
            debugPrint('[SyncService] Pulled new routine log for "${localItem.title}" on ${remoteLog.date}');
          } else {
             // Already exists locally but not linked to firebaseId
             final updated = remoteLog.copyWith(id: existingLog.id);
             await _dbHelper.upsertRoutineLog(updated);
             await _dbHelper.markRoutineLogSynced(updated.id!, docId);
          }
        } else {
          if (remoteLog.lastModified.isAfter(localLog.lastModified)) {
            final updated = remoteLog.copyWith(id: localLog.id, isSynced: true);
            await _dbHelper.upsertRoutineLog(updated);
            debugPrint('[SyncService] Updated local routine log from cloud');
          }
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to pull routine logs: $e');
    }
  }
}

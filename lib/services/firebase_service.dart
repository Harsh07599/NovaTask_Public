import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/note.dart';
import '../models/routine.dart';

/// Service to handle all Firestore CRUD operations.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _tasksCollection => _firestore.collection('tasks');
  CollectionReference get _categoriesCollection => _firestore.collection('categories');
  CollectionReference get _notesCollection => _firestore.collection('notes');
  CollectionReference get _routineGroupsCollection => _firestore.collection('routine_groups');
  CollectionReference get _routineItemsCollection => _firestore.collection('routine_items');
  CollectionReference get _routineLogsCollection => _firestore.collection('routine_logs');

  // ─── Tasks ──────────────────────────────────────────────

  /// Push a task to Firestore. Returns the document ID.
  Future<String> pushTask(Task task) async {
    if (task.firebaseId != null && task.firebaseId!.isNotEmpty) {
      // Update existing document
      await _tasksCollection.doc(task.firebaseId).set(task.toFirestoreMap());
      return task.firebaseId!;
    } else {
      // Create new document
      final doc = await _tasksCollection.add(task.toFirestoreMap());
      return doc.id;
    }
  }

  /// Delete a task from Firestore by its document ID.
  Future<void> deleteTask(String firebaseId) async {
    await _tasksCollection.doc(firebaseId).delete();
  }

  /// Fetch all tasks from Firestore.
  Future<List<Task>> fetchAllTasks() async {
    final snapshot = await _tasksCollection.get();
    return snapshot.docs.map((doc) {
      return Task.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // ─── Categories ─────────────────────────────────────────

  Future<String> pushCategory(TaskCategory category) async {
    if (category.firebaseId != null && category.firebaseId!.isNotEmpty) {
      await _categoriesCollection.doc(category.firebaseId).set(category.toFirestoreMap());
      return category.firebaseId!;
    } else {
      final doc = await _categoriesCollection.add(category.toFirestoreMap());
      return doc.id;
    }
  }

  Future<void> deleteCategory(String firebaseId) async {
    await _categoriesCollection.doc(firebaseId).delete();
  }

  Future<List<TaskCategory>> fetchAllCategories() async {
    final snapshot = await _categoriesCollection.get();
    return snapshot.docs.map((doc) {
      return TaskCategory.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // ─── Notes ──────────────────────────────────────────────

  Future<String> pushNote(Note note) async {
    if (note.firebaseId != null && note.firebaseId!.isNotEmpty) {
      await _notesCollection.doc(note.firebaseId).set(note.toFirestoreMap());
      return note.firebaseId!;
    } else {
      final doc = await _notesCollection.add(note.toFirestoreMap());
      return doc.id;
    }
  }

  Future<void> deleteNote(String firebaseId) async {
    await _notesCollection.doc(firebaseId).delete();
  }

  Future<List<Note>> fetchAllNotes() async {
    final snapshot = await _notesCollection.get();
    return snapshot.docs.map((doc) {
      return Note.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // ─── Routine Groups ────────────────────────────────────

  Future<String> pushRoutineGroup(RoutineGroup group) async {
    if (group.firebaseId != null && group.firebaseId!.isNotEmpty) {
      await _routineGroupsCollection.doc(group.firebaseId).set(group.toFirestoreMap());
      return group.firebaseId!;
    } else {
      final doc = await _routineGroupsCollection.add(group.toFirestoreMap());
      return doc.id;
    }
  }

  Future<void> deleteRoutineGroup(String firebaseId) async {
    await _routineGroupsCollection.doc(firebaseId).delete();
  }

  Future<List<RoutineGroup>> fetchAllRoutineGroups() async {
    final snapshot = await _routineGroupsCollection.get();
    return snapshot.docs.map((doc) {
      return RoutineGroup.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // ─── Routine Items ─────────────────────────────────────

  Future<String> pushRoutineItem(RoutineItem item, String groupFirebaseId) async {
    final data = item.toFirestoreMap();
    data['groupFirebaseId'] = groupFirebaseId;

    if (item.firebaseId != null && item.firebaseId!.isNotEmpty) {
      await _routineItemsCollection.doc(item.firebaseId).set(data);
      return item.firebaseId!;
    } else if (groupFirebaseId.isNotEmpty) {
      // Fallback: Check if an item with same title and groupId already exists to prevent duplicates
      final existing = await _routineItemsCollection
          .where('groupFirebaseId', isEqualTo: groupFirebaseId)
          .where('title', isEqualTo: item.title)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final docId = existing.docs.first.id;
        await _routineItemsCollection.doc(docId).set(data);
        return docId;
      }
    }

    final doc = await _routineItemsCollection.add(data);
    return doc.id;
  }

  Future<void> deleteRoutineItem(String firebaseId) async {
    await _routineItemsCollection.doc(firebaseId).delete();
  }

  Future<List<Map<String, dynamic>>> fetchAllRoutineItems() async {
    final snapshot = await _routineItemsCollection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['docId'] = doc.id;
      return data;
    }).toList();
  }

  // ─── Routine Logs ──────────────────────────────────────

  Future<String> pushRoutineLog(RoutineLog log, String itemFirebaseId) async {
    final data = log.toFirestoreMap();
    data['itemId'] = itemFirebaseId;

    if (log.firebaseId != null && log.firebaseId!.isNotEmpty) {
      await _routineLogsCollection.doc(log.firebaseId).set(data);
      return log.firebaseId!;
    } else {
      // Upsert by itemId and date to prevent duplicates
      final existing = await _routineLogsCollection
          .where('itemId', isEqualTo: itemFirebaseId)
          .where('date', isEqualTo: log.date)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final docId = existing.docs.first.id;
        await _routineLogsCollection.doc(docId).set(data);
        return docId;
      }

      final doc = await _routineLogsCollection.add(data);
      return doc.id;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllRoutineLogs() async {
    final snapshot = await _routineLogsCollection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['docId'] = doc.id;
      return data;
    }).toList();
  }
}

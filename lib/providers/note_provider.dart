import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/note.dart';
import '../services/sync_service.dart';
import '../services/firebase_service.dart';

class NoteProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();
  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();
    _notes = await _dbHelper.getAllNotes();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(String title, String content, int color) async {
    final now = DateTime.now();
    final note = Note(
      title: title,
      content: content,
      colorValue: color,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      lastModified: now,
    );
    final id = await _dbHelper.insertNote(note);
    _notes.insert(0, note.copyWith(id: id));
    notifyListeners();
    _triggerSync();
  }

  Future<void> updateNote(Note note) async {
    final now = DateTime.now();
    final updatedNote = note.copyWith(
      updatedAt: now,
      isSynced: false,
      lastModified: now,
    );
    await _dbHelper.updateNote(updatedNote);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }
    _triggerSync();
  }

  Future<void> deleteNote(int id) async {
    final note = _notes.firstWhere((n) => n.id == id, orElse: () => _notes.first);
    if (note.id == id && note.firebaseId != null && note.firebaseId!.isNotEmpty) {
      try {
        if (await _syncService.isOnline()) {
          final FirebaseService firebaseService = FirebaseService();
          await firebaseService.deleteNote(note.firebaseId!);
        }
      } catch (_) {}
    }

    await _dbHelper.deleteNote(id);
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void _triggerSync() {
    _syncService.syncAll().then((_) => loadNotes());
  }
}

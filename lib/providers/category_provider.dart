import 'package:flutter/material.dart';
import '../models/category.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();

  List<TaskCategory> _categories = [];
  bool _isLoading = false;

  List<TaskCategory> get categories => _categories;
  bool get isLoading => _isLoading;

  List<String> get categoryNames => _categories.map((c) => c.name).toList();

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _dbHelper.getAllCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(TaskCategory category) async {
    final catWithSync = category.copyWith(
      isSynced: false,
      lastModified: DateTime.now(),
    );
    await _dbHelper.insertCategory(catWithSync);
    await loadCategories();
    _triggerSync();
  }

  Future<void> updateCategory(TaskCategory category) async {
    final catWithSync = category.copyWith(
      isSynced: false,
      lastModified: DateTime.now(),
    );
    await _dbHelper.updateCategory(catWithSync);
    await loadCategories();
    _triggerSync();
  }

  Future<void> deleteCategory(int id) async {
    await _dbHelper.deleteCategory(id);
    await loadCategories();
  }

  TaskCategory? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  void _triggerSync() {
    _syncService.syncAll().then((_) => loadCategories());
  }
}

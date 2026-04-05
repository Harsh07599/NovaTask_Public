import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/routine.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'task_alarm.db');
    return await openDatabase(
      path,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        priority INTEGER DEFAULT 1,
        dueDateTime INTEGER NOT NULL,
        category TEXT DEFAULT 'General',
        taskType INTEGER DEFAULT 0,
        reminderIntervalMinutes INTEGER DEFAULT 5,
        recurringType INTEGER DEFAULT 0,
        isCompleted INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        soundPath TEXT,
        soundName TEXT,
        firebaseId TEXT,
        isSynced INTEGER DEFAULT 0,
        lastModified INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        colorValue INTEGER NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        firebaseId TEXT,
        isSynced INTEGER DEFAULT 0,
        lastModified INTEGER
      )
    ''');

    // Insert default categories
    for (final cat in TaskCategory.defaultCategories) {
      await db.insert('categories', cat.toMap()..remove('id'));
    }

    await db.execute('''
      CREATE TABLE settings(
        id TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE routine_groups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        frequency INTEGER DEFAULT 0,
        lastResetDate TEXT,
        firebaseId TEXT,
        isSynced INTEGER DEFAULT 0,
        lastModified INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE routine_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        groupId INTEGER NOT NULL,
        title TEXT NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        firebaseId TEXT,
        isSynced INTEGER DEFAULT 0,
        lastModified INTEGER,
        FOREIGN KEY (groupId) REFERENCES routine_groups (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        colorValue INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        firebaseId TEXT,
        isSynced INTEGER DEFAULT 0,
        lastModified INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE routine_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemId INTEGER NOT NULL,
        date TEXT NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        firebaseId TEXT,
        isSynced INTEGER DEFAULT 0,
        lastModified INTEGER,
        FOREIGN KEY (itemId) REFERENCES routine_items (id) ON DELETE CASCADE,
        UNIQUE(itemId, date)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN soundPath TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN soundName TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('CREATE TABLE IF NOT EXISTS settings(id TEXT PRIMARY KEY, value TEXT)');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE routine_groups(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          frequency INTEGER,
          lastResetDate TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE routine_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          groupId INTEGER,
          title TEXT,
          isCompleted INTEGER,
          FOREIGN KEY (groupId) REFERENCES routine_groups (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 7) {
      // Ensure routine tables exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS routine_groups(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          frequency INTEGER DEFAULT 0,
          lastResetDate TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS routine_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          groupId INTEGER NOT NULL,
          title TEXT NOT NULL,
          isCompleted INTEGER DEFAULT 0,
          FOREIGN KEY (groupId) REFERENCES routine_groups (id) ON DELETE CASCADE
        )
      ''');
      
      // Ensure notes table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          content TEXT,
          colorValue INTEGER,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
    }

    // Version 8: Add sync columns to all tables
    if (oldVersion < 8) {
      // Tasks
      await _addColumnIfNotExists(db, 'tasks', 'firebaseId', 'TEXT');
      await _addColumnIfNotExists(db, 'tasks', 'isSynced', 'INTEGER DEFAULT 0');
      await _addColumnIfNotExists(db, 'tasks', 'lastModified', 'INTEGER');

      // Categories
      await _addColumnIfNotExists(db, 'categories', 'firebaseId', 'TEXT');
      await _addColumnIfNotExists(db, 'categories', 'isSynced', 'INTEGER DEFAULT 0');
      await _addColumnIfNotExists(db, 'categories', 'lastModified', 'INTEGER');

      // Routine Groups
      await _addColumnIfNotExists(db, 'routine_groups', 'firebaseId', 'TEXT');
      await _addColumnIfNotExists(db, 'routine_groups', 'isSynced', 'INTEGER DEFAULT 0');
      await _addColumnIfNotExists(db, 'routine_groups', 'lastModified', 'INTEGER');

      // Routine Items
      await _addColumnIfNotExists(db, 'routine_items', 'firebaseId', 'TEXT');
      await _addColumnIfNotExists(db, 'routine_items', 'isSynced', 'INTEGER DEFAULT 0');
      await _addColumnIfNotExists(db, 'routine_items', 'lastModified', 'INTEGER');

      // Notes
      await _addColumnIfNotExists(db, 'notes', 'firebaseId', 'TEXT');
      await _addColumnIfNotExists(db, 'notes', 'isSynced', 'INTEGER DEFAULT 0');
      await _addColumnIfNotExists(db, 'notes', 'lastModified', 'INTEGER');
    }

    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS routine_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          itemId INTEGER NOT NULL,
          date TEXT NOT NULL,
          isCompleted INTEGER DEFAULT 0,
          firebaseId TEXT,
          isSynced INTEGER DEFAULT 0,
          lastModified INTEGER,
          FOREIGN KEY (itemId) REFERENCES routine_items (id) ON DELETE CASCADE,
          UNIQUE(itemId, date)
        )
      ''');
    }
  }

  /// Safely add a column if it doesn't exist
  Future<void> _addColumnIfNotExists(
      Database db, String table, String column, String type) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    final columnExists = result.any((row) => row['name'] == column);
    if (!columnExists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  // ─── Settings ───────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'id = ?', whereArgs: [key]);
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> updateSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'id': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Task CRUD ──────────────────────────────────────────

  Future<int> insertTask(Task task) async {
    final db = await database;
    final map = task.toMap()..remove('id');
    return await db.insert('tasks', map);
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Task?> getTask(int id) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> getAllTasks({
    String? sortBy,
    bool ascending = true,
    String? filterCategory,
    Priority? filterPriority,
    TaskType? filterTaskType,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;
    String orderBy = 'dueDateTime ASC';

    // Build WHERE clause
    List<String> conditions = [];
    List<dynamic> args = [];

    conditions.add('isCompleted = 0');

    if (filterCategory != null) {
      conditions.add('category = ?');
      args.add(filterCategory);
    }
    if (filterPriority != null) {
      conditions.add('priority = ?');
      args.add(filterPriority.index);
    }
    if (filterTaskType != null) {
      conditions.add('taskType = ?');
      args.add(filterTaskType.index);
    }

    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
      whereArgs = args.isNotEmpty ? args : null;
    }

    // Build ORDER BY
    if (sortBy != null) {
      final direction = ascending ? 'ASC' : 'DESC';
      switch (sortBy) {
        case 'date':
          orderBy = 'dueDateTime $direction';
          break;
        case 'priority':
          orderBy = 'priority $direction';
          break;
        case 'category':
          orderBy = 'category $direction';
          break;
        case 'title':
          orderBy = 'title $direction';
          break;
        default:
          orderBy = 'dueDateTime $direction';
      }
    }

    final maps = await db.query(
      'tasks',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getActiveTasks() async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'isCompleted = 0',
      orderBy: 'dueDateTime ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // ─── Category CRUD ──────────────────────────────────────

  Future<List<TaskCategory>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    return maps.map((m) => TaskCategory.fromMap(m)).toList();
  }

  Future<int> insertCategory(TaskCategory category) async {
    final db = await database;
    final map = category.toMap()..remove('id');
    return await db.insert('categories', map);
  }

  Future<int> updateCategory(TaskCategory category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Routine CRUD ────────────────────────────────────────

  Future<int> insertRoutineGroup(RoutineGroup group) async {
    final db = await database;
    return await db.insert('routine_groups', group.toMap()..remove('id'));
  }

  Future<List<RoutineGroup>> getRoutineGroups() async {
    final db = await database;
    final maps = await db.query('routine_groups', orderBy: 'id ASC');
    return maps.map((m) => RoutineGroup.fromMap(m)).toList();
  }

  Future<void> updateRoutineGroup(RoutineGroup group) async {
    final db = await database;
    await db.update('routine_groups', group.toMap(),
        where: 'id = ?', whereArgs: [group.id]);
  }

  Future<void> deleteRoutineGroup(int id) async {
    final db = await database;
    await db.delete('routine_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertRoutineItem(RoutineItem item) async {
    final db = await database;
    return await db.insert('routine_items', item.toMap()..remove('id'));
  }

  Future<List<RoutineItem>> getRoutineItems(int groupId) async {
    final db = await database;
    final maps = await db.query('routine_items',
        where: 'groupId = ?', whereArgs: [groupId], orderBy: 'id ASC');
    return maps.map((m) => RoutineItem.fromMap(m)).toList();
  }

  Future<void> updateRoutineItem(RoutineItem item) async {
    final db = await database;
    await db.update('routine_items', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteRoutineItem(int id) async {
    final db = await database;
    await db.delete('routine_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetRoutineItems(int groupId) async {
    final db = await database;
    await db.update('routine_items', {'isCompleted': 0, 'isSynced': 0, 'lastModified': DateTime.now().millisecondsSinceEpoch},
        where: 'groupId = ?', whereArgs: [groupId]);
  }

  Future<Map<int, Map<String, int>>> getRoutineItemCounts() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT groupId, COUNT(*) as total, SUM(isCompleted) as completed 
      FROM routine_items 
      GROUP BY groupId
    ''');
    
    Map<int, Map<String, int>> counts = {};
    for (var m in maps) {
      counts[m['groupId'] as int] = {
        'total': m['total'] as int,
        'completed': (m['completed'] as int?) ?? 0,
      };
    }
    return counts;
  }

  // ─── Note CRUD ──────────────────────────────────────────

  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap()..remove('id'));
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final maps = await db.query('notes', orderBy: 'updatedAt DESC');
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update('notes', note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }


  // ─── Sync Helpers ──────────────────────────────────────

  /// Get all unsynced tasks
  Future<List<Task>> getUnsyncedTasks() async {
    final db = await database;
    final maps = await db.query('tasks', where: 'isSynced = 0');
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  /// Get all unsynced categories
  Future<List<TaskCategory>> getUnsyncedCategories() async {
    final db = await database;
    final maps = await db.query('categories', where: 'isSynced = 0');
    return maps.map((m) => TaskCategory.fromMap(m)).toList();
  }

  /// Get all unsynced notes
  Future<List<Note>> getUnsyncedNotes() async {
    final db = await database;
    final maps = await db.query('notes', where: 'isSynced = 0');
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  /// Get all unsynced routine groups
  Future<List<RoutineGroup>> getUnsyncedRoutineGroups() async {
    final db = await database;
    final maps = await db.query('routine_groups', where: 'isSynced = 0');
    return maps.map((m) => RoutineGroup.fromMap(m)).toList();
  }

  /// Get all unsynced routine items
  Future<List<RoutineItem>> getUnsyncedRoutineItems() async {
    final db = await database;
    final maps = await db.query('routine_items', where: 'isSynced = 0');
    return maps.map((m) => RoutineItem.fromMap(m)).toList();
  }

  /// Mark a task as synced with its firebaseId
  Future<void> markTaskSynced(int localId, String firebaseId) async {
    final db = await database;
    await db.update(
      'tasks',
      {'isSynced': 1, 'firebaseId': firebaseId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Mark a category as synced
  Future<void> markCategorySynced(int localId, String firebaseId) async {
    final db = await database;
    await db.update(
      'categories',
      {'isSynced': 1, 'firebaseId': firebaseId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Mark a note as synced
  Future<void> markNoteSynced(int localId, String firebaseId) async {
    final db = await database;
    await db.update(
      'notes',
      {'isSynced': 1, 'firebaseId': firebaseId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Mark a routine group as synced
  Future<void> markRoutineGroupSynced(int localId, String firebaseId) async {
    final db = await database;
    await db.update(
      'routine_groups',
      {'isSynced': 1, 'firebaseId': firebaseId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Mark a routine item as synced
  Future<void> markRoutineItemSynced(int localId, String firebaseId) async {
    final db = await database;
    await db.update(
      'routine_items',
      {'isSynced': 1, 'firebaseId': firebaseId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Find a task by its firebaseId
  Future<Task?> getTaskByFirebaseId(String firebaseId) async {
    final db = await database;
    final maps = await db.query('tasks',
        where: 'firebaseId = ?', whereArgs: [firebaseId]);
    if (maps.isNotEmpty) return Task.fromMap(maps.first);
    return null;
  }

  /// Find a category by its firebaseId
  Future<TaskCategory?> getCategoryByFirebaseId(String firebaseId) async {
    final db = await database;
    final maps = await db.query('categories',
        where: 'firebaseId = ?', whereArgs: [firebaseId]);
    if (maps.isNotEmpty) return TaskCategory.fromMap(maps.first);
    return null;
  }

  /// Find a note by its firebaseId
  Future<Note?> getNoteByFirebaseId(String firebaseId) async {
    final db = await database;
    final maps = await db.query('notes',
        where: 'firebaseId = ?', whereArgs: [firebaseId]);
    if (maps.isNotEmpty) return Note.fromMap(maps.first);
    return null;
  }

  /// Find a routine group by its firebaseId
  Future<RoutineGroup?> getRoutineGroupByFirebaseId(String firebaseId) async {
    final db = await database;
    final maps = await db.query('routine_groups',
        where: 'firebaseId = ?', whereArgs: [firebaseId]);
    if (maps.isNotEmpty) return RoutineGroup.fromMap(maps.first);
    return null;
  }

  /// Find a routine item by its firebaseId
  Future<RoutineItem?> getRoutineItemByFirebaseId(String firebaseId) async {
    final db = await database;
    final maps = await db.query('routine_items',
        where: 'firebaseId = ?', whereArgs: [firebaseId]);
    if (maps.isNotEmpty) return RoutineItem.fromMap(maps.first);
    return null;
  }

  /// Get all tasks (including completed) for sync purposes
  Future<List<Task>> getAllTasksForSync() async {
    final db = await database;
    final maps = await db.query('tasks');
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  /// Get all routine items for sync
  Future<List<RoutineItem>> getAllRoutineItems() async {
    final db = await database;
    final maps = await db.query('routine_items');
    return maps.map((m) => RoutineItem.fromMap(m)).toList();
  }

  // ─── Routine Log CRUD ─────────────────────────────────────

  Future<void> upsertRoutineLog(RoutineLog log) async {
    final db = await database;
    await db.insert(
      'routine_logs',
      log.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<RoutineLog?> getRoutineLog(int itemId, String date) async {
    final db = await database;
    final maps = await db.query(
      'routine_logs',
      where: 'itemId = ? AND date = ?',
      whereArgs: [itemId, date],
    );
    if (maps.isNotEmpty) return RoutineLog.fromMap(maps.first);
    return null;
  }

  Future<List<RoutineLog>> getRoutineLogsForDateRange(String startDate, String endDate) async {
    final db = await database;
    final maps = await db.query(
      'routine_logs',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => RoutineLog.fromMap(m)).toList();
  }

  Future<List<RoutineLog>> getUnsyncedRoutineLogs() async {
    final db = await database;
    final maps = await db.query('routine_logs', where: 'isSynced = 0');
    return maps.map((m) => RoutineLog.fromMap(m)).toList();
  }

  Future<void> markRoutineLogSynced(int localId, String firebaseId) async {
    final db = await database;
    await db.update(
      'routine_logs',
      {'isSynced': 1, 'firebaseId': firebaseId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<RoutineLog?> getRoutineLogByFirebaseId(String firebaseId) async {
    final db = await database;
    final maps = await db.query('routine_logs', where: 'firebaseId = ?', whereArgs: [firebaseId]);
    if (maps.isNotEmpty) return RoutineLog.fromMap(maps.first);
    return null;
  }
}

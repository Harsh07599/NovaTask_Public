enum Priority { high, medium, low }

enum TaskType { alarm, reminder }

enum RecurringType { none, daily, weekly, monthly, yearly }

class Task {
  final int? id;
  final String title;
  final String description;
  final Priority priority;
  final DateTime dueDateTime;
  final String category;
  final TaskType taskType;
  final int reminderIntervalMinutes; // only used for reminder type
  final RecurringType recurringType;
  final bool isCompleted;
  final DateTime createdAt;
  final String? soundPath;
  final String? soundName;
  // Sync fields
  final String? firebaseId;
  final bool isSynced;
  final DateTime lastModified;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.priority = Priority.medium,
    required this.dueDateTime,
    this.category = 'General',
    this.taskType = TaskType.alarm,
    this.reminderIntervalMinutes = 5,
    this.recurringType = RecurringType.none,
    this.isCompleted = false,
    DateTime? createdAt,
    this.soundPath,
    this.soundName,
    this.firebaseId,
    this.isSynced = false,
    DateTime? lastModified,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  Task copyWith({
    int? id,
    String? title,
    String? description,
    Priority? priority,
    DateTime? dueDateTime,
    String? category,
    TaskType? taskType,
    int? reminderIntervalMinutes,
    RecurringType? recurringType,
    bool? isCompleted,
    DateTime? createdAt,
    String? soundPath,
    String? soundName,
    String? firebaseId,
    bool? isSynced,
    DateTime? lastModified,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDateTime: dueDateTime ?? this.dueDateTime,
      category: category ?? this.category,
      taskType: taskType ?? this.taskType,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      recurringType: recurringType ?? this.recurringType,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      soundPath: soundPath ?? this.soundPath,
      soundName: soundName ?? this.soundName,
      firebaseId: firebaseId ?? this.firebaseId,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'dueDateTime': dueDateTime.millisecondsSinceEpoch,
      'category': category,
      'taskType': taskType.index,
      'reminderIntervalMinutes': reminderIntervalMinutes,
      'recurringType': recurringType.index,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'soundPath': soundPath,
      'soundName': soundName,
      'firebaseId': firebaseId,
      'isSynced': isSynced ? 1 : 0,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  /// Convert to Firestore-friendly map (no local id, uses string enums).
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority.index,
      'dueDateTime': dueDateTime.millisecondsSinceEpoch,
      'category': category,
      'taskType': taskType.index,
      'reminderIntervalMinutes': reminderIntervalMinutes,
      'recurringType': recurringType.index,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'soundPath': soundPath,
      'soundName': soundName,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      priority: Priority.values[map['priority'] as int],
      dueDateTime: DateTime.fromMillisecondsSinceEpoch(map['dueDateTime'] as int),
      category: map['category'] as String? ?? 'General',
      taskType: TaskType.values[map['taskType'] as int],
      reminderIntervalMinutes: map['reminderIntervalMinutes'] as int? ?? 5,
      recurringType: RecurringType.values[map['recurringType'] as int],
      isCompleted: (map['isCompleted'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      soundPath: map['soundPath'] as String?,
      soundName: map['soundName'] as String?,
      firebaseId: map['firebaseId'] as String?,
      isSynced: (map['isSynced'] as int?) == 1,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }

  /// Create a Task from a Firestore document snapshot.
  factory Task.fromFirestore(Map<String, dynamic> map, String docId) {
    return Task(
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      priority: Priority.values[map['priority'] as int],
      dueDateTime: DateTime.fromMillisecondsSinceEpoch(map['dueDateTime'] as int),
      category: map['category'] as String? ?? 'General',
      taskType: TaskType.values[map['taskType'] as int],
      reminderIntervalMinutes: map['reminderIntervalMinutes'] as int? ?? 5,
      recurringType: RecurringType.values[map['recurringType'] as int],
      isCompleted: (map['isCompleted'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      soundPath: map['soundPath'] as String?,
      soundName: map['soundName'] as String?,
      firebaseId: docId,
      isSynced: true,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }

  String get priorityLabel {
    switch (priority) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  String get taskTypeLabel {
    switch (taskType) {
      case TaskType.alarm:
        return 'Alarm';
      case TaskType.reminder:
        return 'Reminder';
    }
  }

  String get recurringLabel {
    switch (recurringType) {
      case RecurringType.none:
        return 'One-time';
      case RecurringType.daily:
        return 'Daily';
      case RecurringType.weekly:
        return 'Weekly';
      case RecurringType.monthly:
        return 'Monthly';
      case RecurringType.yearly:
        return 'Yearly';
    }
  }
}

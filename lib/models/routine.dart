import 'task.dart'; // Reuse RecurringType

class RoutineGroup {
  final int? id;
  final String title;
  final RecurringType frequency;
  final DateTime lastResetDate;
  // Sync fields
  final String? firebaseId;
  final bool isSynced;
  final DateTime lastModified;

  RoutineGroup({
    this.id,
    required this.title,
    required this.frequency,
    required this.lastResetDate,
    this.firebaseId,
    this.isSynced = false,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  RoutineGroup copyWith({
    int? id,
    String? title,
    RecurringType? frequency,
    DateTime? lastResetDate,
    String? firebaseId,
    bool? isSynced,
    DateTime? lastModified,
  }) {
    return RoutineGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      firebaseId: firebaseId ?? this.firebaseId,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'frequency': frequency.index,
      'lastResetDate': lastResetDate.toIso8601String(),
      'firebaseId': firebaseId,
      'isSynced': isSynced ? 1 : 0,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'frequency': frequency.name,
      'lastResetDate': lastResetDate.toIso8601String(),
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  factory RoutineGroup.fromMap(Map<String, dynamic> map) {
    return RoutineGroup(
      id: map['id'],
      title: map['title'],
      frequency: RecurringType.values[map['frequency']],
      lastResetDate: DateTime.parse(map['lastResetDate']),
      firebaseId: map['firebaseId'] as String?,
      isSynced: (map['isSynced'] as int?) == 1,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }

  factory RoutineGroup.fromFirestore(Map<String, dynamic> map, String docId) {
    final freqStr = map['frequency'] as String?;
    final freq = RecurringType.values.firstWhere(
      (e) => e.name == freqStr,
      orElse: () => RecurringType.none,
    );

    return RoutineGroup(
      title: map['title'] ?? '',
      frequency: freq,
      lastResetDate: map['lastResetDate'] != null
          ? DateTime.parse(map['lastResetDate'])
          : DateTime.now(),
      firebaseId: docId,
      isSynced: true,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }
}

class RoutineItem {
  final int? id;
  final int groupId;
  final String title;
  final bool isCompleted;
  // Sync fields
  final String? firebaseId;
  final bool isSynced;
  final DateTime lastModified;

  RoutineItem({
    this.id,
    required this.groupId,
    required this.title,
    this.isCompleted = false,
    this.firebaseId,
    this.isSynced = false,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  RoutineItem copyWith({
    int? id,
    int? groupId,
    String? title,
    bool? isCompleted,
    String? firebaseId,
    bool? isSynced,
    DateTime? lastModified,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      firebaseId: firebaseId ?? this.firebaseId,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'firebaseId': firebaseId,
      'isSynced': isSynced ? 1 : 0,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'groupFirebaseId': '', // Will be set by sync service
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  factory RoutineItem.fromMap(Map<String, dynamic> map) {
    return RoutineItem(
      id: map['id'],
      groupId: map['groupId'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      firebaseId: map['firebaseId'] as String?,
      isSynced: (map['isSynced'] as int?) == 1,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }

  factory RoutineItem.fromFirestore(Map<String, dynamic> map, String docId, int localGroupId) {
    return RoutineItem(
      groupId: localGroupId,
      title: map['title'] ?? '',
      isCompleted: (map['isCompleted'] ?? 0) == 1,
      firebaseId: docId,
      isSynced: true,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }
}

class RoutineLog {
  final int? id;
  final int itemId;
  final String date;
  final bool isCompleted;
  final String? firebaseId;
  final bool isSynced;
  final DateTime lastModified;

  RoutineLog({
    this.id,
    required this.itemId,
    required this.date,
    this.isCompleted = false,
    this.firebaseId,
    this.isSynced = false,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  RoutineLog copyWith({
    int? id,
    int? itemId,
    String? date,
    bool? isCompleted,
    String? firebaseId,
    bool? isSynced,
    DateTime? lastModified,
  }) {
    return RoutineLog(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      firebaseId: firebaseId ?? this.firebaseId,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'date': date,
      'isCompleted': isCompleted ? 1 : 0,
      'firebaseId': firebaseId,
      'isSynced': isSynced ? 1 : 0,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'itemId': '', // To be filled by sync service
      'date': date,
      'isCompleted': isCompleted,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  factory RoutineLog.fromMap(Map<String, dynamic> map) {
    return RoutineLog(
      id: map['id'],
      itemId: map['itemId'],
      date: map['date'],
      isCompleted: map['isCompleted'] == 1,
      firebaseId: map['firebaseId'] as String?,
      isSynced: (map['isSynced'] as int?) == 1,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }

  factory RoutineLog.fromFirestore(Map<String, dynamic> map, String docId, int localItemId) {
    return RoutineLog(
      itemId: localItemId,
      date: map['date'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      firebaseId: docId,
      isSynced: true,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }
}

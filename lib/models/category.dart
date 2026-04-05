import 'package:flutter/material.dart';

class TaskCategory {
  final int? id;
  final String name;
  final int colorValue;
  final int iconCodePoint;
  // Sync fields
  final String? firebaseId;
  final bool isSynced;
  final DateTime lastModified;

  TaskCategory({
    this.id,
    required this.name,
    this.colorValue = 0xFF6C63FF,
    this.iconCodePoint = 0xe0b0, // Icons.label
    this.firebaseId,
    this.isSynced = false,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  TaskCategory copyWith({
    int? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
    String? firebaseId,
    bool? isSynced,
    DateTime? lastModified,
  }) {
    return TaskCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      firebaseId: firebaseId ?? this.firebaseId,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'firebaseId': firebaseId,
      'isSynced': isSynced ? 1 : 0,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  factory TaskCategory.fromMap(Map<String, dynamic> map) {
    return TaskCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorValue: map['colorValue'] as int? ?? 0xFF6C63FF,
      iconCodePoint: map['iconCodePoint'] as int? ?? 0xe0b0,
      firebaseId: map['firebaseId'] as String?,
      isSynced: (map['isSynced'] as int?) == 1,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }

  factory TaskCategory.fromFirestore(Map<String, dynamic> map, String docId) {
    return TaskCategory(
      name: map['name'] as String,
      colorValue: map['colorValue'] as int? ?? 0xFF6C63FF,
      iconCodePoint: map['iconCodePoint'] as int? ?? 0xe0b0,
      firebaseId: docId,
      isSynced: true,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }

  static List<TaskCategory> defaultCategories = [
    TaskCategory(name: 'General', colorValue: 0xFF6C63FF, iconCodePoint: Icons.label.codePoint),
    TaskCategory(name: 'Work', colorValue: 0xFF00BCD4, iconCodePoint: Icons.work.codePoint),
    TaskCategory(name: 'Personal', colorValue: 0xFFFF6B6B, iconCodePoint: Icons.person.codePoint),
    TaskCategory(name: 'Health', colorValue: 0xFF4CAF50, iconCodePoint: Icons.favorite.codePoint),
    TaskCategory(name: 'Shopping', colorValue: 0xFFFF9800, iconCodePoint: Icons.shopping_cart.codePoint),
  ];
}

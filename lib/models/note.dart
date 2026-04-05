import 'package:flutter/material.dart';

class Note {
  final int? id;
  final String title;
  final String content;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Sync fields
  final String? firebaseId;
  final bool isSynced;
  final DateTime lastModified;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.firebaseId,
    this.isSynced = false,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firebaseId,
    bool? isSynced,
    DateTime? lastModified,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firebaseId: firebaseId ?? this.firebaseId,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'firebaseId': firebaseId,
      'isSynced': isSynced ? 1 : 0,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'content': content,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      colorValue: map['colorValue'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      firebaseId: map['firebaseId'] as String?,
      isSynced: (map['isSynced'] as int?) == 1,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }

  factory Note.fromFirestore(Map<String, dynamic> map, String docId) {
    return Note(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF0A0A0A,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      firebaseId: docId,
      isSynced: true,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : DateTime.now(),
    );
  }

  static const List<int> noteColors = [
    0xFF0A0A0A, // Neutral Dark (Amoled Default)
    0xFF4B1D1D, // Deep Red
    0xFF1D3B1D, // Deep Green
    0xFF1D2D4B, // Deep Blue
    0xFF3B1D3B, // Deep Purple
    0xFF3B3B1D, // Deep Yellow/Olive
  ];
}

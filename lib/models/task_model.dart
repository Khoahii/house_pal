import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String title;
  String description;

  String difficulty; // "easy", "medium", "hard"
  int point;         // 5, 10, 15
  String frequency;  // "daily", "weekly", "monthly"

  String assignMode; // "auto" | "manual"
  List<DocumentReference>? rotationOrder; // nếu auto
  int? rotationIndex;                     // nếu auto
  DocumentReference? manualAssignedTo;   // nếu manual

  DocumentReference createdBy;
  Timestamp createdAt;
  Timestamp updatedAt;

  Task({
    this.id = '',
    required this.title,
    required this.description,
    required this.difficulty,
    required this.point,
    required this.frequency,
    required this.assignMode,
    this.rotationOrder,
    this.rotationIndex,
    this.manualAssignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // ===== Chuyển từ Firestore document sang Task object =====
  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      difficulty: data['difficulty'] ?? 'easy',
      point: data['point'] ?? 5,
      frequency: data['frequency'] ?? 'daily',
      assignMode: data['assignMode'] ?? 'auto',
      rotationOrder: data['rotationOrder'] != null
          ? List<DocumentReference>.from(data['rotationOrder'])
          : null,
      rotationIndex: data['rotationIndex'],
      manualAssignedTo: data['manualAssignedTo'],
      createdBy: data['createdBy'],
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  // ===== Chuyển Task object sang map để lưu Firestore =====
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'point': point,
      'frequency': frequency,
      'assignMode': assignMode,
      'rotationOrder': rotationOrder,
      'rotationIndex': rotationIndex,
      'manualAssignedTo': manualAssignedTo,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

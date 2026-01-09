import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;

  final String difficulty; // "easy", "medium", "hard"
  final int point; // 5, 10, 15
  final String frequency; // "daily", "weekly", "monthly"

  final String assignMode; // "auto" | "manual"
  final List<DocumentReference>? rotationOrder; // nếu auto
  final int? rotationIndex; // nếu auto
  final DocumentReference? manualAssignedTo; // nếu manual

  final DocumentReference createdBy;
  final Timestamp createdAt;
  final Timestamp updatedAt;

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

  factory Task.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Task.fromMap(doc.id, doc.data() ?? const {});

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    final createdBy = _asDocRef(data['createdBy']);
    if (createdBy == null) {
      throw StateError('Task.createdBy is required');
    }

    return Task(
      id: id,
      title: _asString(data['title'], ''),
      description: _asString(data['description'], ''),
      difficulty: _asString(data['difficulty'], 'easy'),
      point: _asInt(data['point'], 5),
      frequency: _asString(data['frequency'], 'daily'),
      assignMode: _asString(data['assignMode'], 'auto'),
      rotationOrder: _asDocRefList(data['rotationOrder']),
      rotationIndex: _asNullableInt(data['rotationIndex']),
      manualAssignedTo: _asDocRef(data['manualAssignedTo']),
      createdBy: createdBy,
      createdAt: _asTimestamp(data['createdAt']),
      updatedAt: _asTimestamp(data['updatedAt']),
    );
  }

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

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? difficulty,
    int? point,
    String? frequency,
    String? assignMode,
    List<DocumentReference>? rotationOrder,
    int? rotationIndex,
    DocumentReference? manualAssignedTo,
    DocumentReference? createdBy,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      point: point ?? this.point,
      frequency: frequency ?? this.frequency,
      assignMode: assignMode ?? this.assignMode,
      rotationOrder: rotationOrder ?? this.rotationOrder,
      rotationIndex: rotationIndex ?? this.rotationIndex,
      manualAssignedTo: manualAssignedTo ?? this.manualAssignedTo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAuto => assignMode == 'auto';
  bool get isManual => assignMode == 'manual';

  static String _asString(dynamic value, String fallback) =>
      value is String ? value : fallback;

  static int _asInt(dynamic value, int fallback) =>
      value is int ? value : value is num ? value.toInt() : fallback;

  static int? _asNullableInt(dynamic value) =>
      value == null ? null : _asInt(value, 0);

  static DocumentReference? _asDocRef(dynamic value) =>
      value is DocumentReference ? value : null;

  static List<DocumentReference>? _asDocRefList(dynamic value) {
    if (value is Iterable) {
      final refs = value.whereType<DocumentReference>().toList(growable: false);
      return refs.isEmpty ? null : refs;
    }
    return null;
  }

  static Timestamp _asTimestamp(dynamic value) =>
      value is Timestamp ? value : Timestamp.now();
}

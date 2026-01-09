import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String name;
  final String code;
  final List<DocumentReference> members;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    required this.code,
    required this.members,
    required this.createdAt,
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      members: List<DocumentReference>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

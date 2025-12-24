import 'package:cloud_firestore/cloud_firestore.dart';

class Bulletin {
  final String id;
  final String title;
  final String content;
  final String type; // note | announcement
  final bool isPinned;

  final DocumentReference createdBy;
  final String creatorName;
  final String? creatorAvatar;

  final DateTime createdAt;
  final DateTime updatedAt;

  Bulletin({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.isPinned,
    required this.createdBy,
    required this.creatorName,
    required this.creatorAvatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bulletin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Bulletin(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'note',
      isPinned: (data['isPinned'] ?? false) as bool,
      createdBy: data['createdBy'],
      creatorName: data['creatorName'] ?? '',
      creatorAvatar: data['creatorAvatar'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}

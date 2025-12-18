import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final bool pinned;
  final DocumentReference roomId;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.pinned,
    required this.roomId,
  });

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title'],
      content: data['content'],
      pinned: data['pinned'] ?? false,
      roomId: data['roomId'],
    );
  }
}

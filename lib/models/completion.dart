import 'package:cloud_firestore/cloud_firestore.dart';

class Completion {
  final String id;
  final DocumentReference taskRef;
  final DocumentReference userRef;
  final int pointEarned;
  final Timestamp completedAt;

  Completion({
    required this.id,
    required this.taskRef,
    required this.userRef,
    required this.pointEarned,
    required this.completedAt,
  });

  // Tạo từ DocumentSnapshot
  factory Completion.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Completion(
      id: doc.id,
      taskRef: data['taskRef'] as DocumentReference,
      userRef: data['userRef'] as DocumentReference,
      pointEarned: data['pointEarned'] ?? 0,
      completedAt: data['completedAt'] ?? Timestamp.now(),
    );
  }

  // Chuyển thành Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'taskRef': taskRef,
      'userRef': userRef,
      'pointEarned': pointEarned,
      'completedAt': completedAt,
    };
  }
}

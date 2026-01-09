import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho document điểm của user trong tháng
/// Path: rooms/{roomId}/leaderboards/{yyyyMM}/scores/{userId}
class LeaderboardScore {
  final String userId;
  final DocumentReference userRef; // reference đến users/{userId}
  final int score; // Đảm bảo kiểu int (convert từ num)
  final DateTime? updatedAt;

  // Thông tin user (không lưu DB, load từ userRef)
  String? userName;
  String? userAvatar;

  LeaderboardScore({
    required this.userId,
    required this.userRef,
    required this.score,
    this.updatedAt,
    this.userName,
    this.userAvatar,
  });

  /// Tạo từ Firestore document
  factory LeaderboardScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardScore(
      userId: doc.id,
      userRef: data['userRef'] as DocumentReference,
      // An toàn chuyển num → int
      score: (data['score'] as num?)?.toInt() ?? 0,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Chuyển sang Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userRef': userRef,
      'score': score,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Copy với thông tin user đã load
  LeaderboardScore copyWithUserInfo({
    required String name,
    required String? avatar,
  }) {
    return LeaderboardScore(
      userId: userId,
      userRef: userRef,
      score: score,
      updatedAt: updatedAt,
      userName: name,
      userAvatar: avatar,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho document leaderboard tháng
/// Path: rooms/{roomId}/leaderboards/{yyyyMM}
class LeaderboardMonth {
  final String monthId; // yyyy-MM format
  final String month; // yyyy-MM string
  final DateTime? updatedAt;

  LeaderboardMonth({
    required this.monthId,
    required this.month,
    this.updatedAt,
  });

  /// Tạo từ Firestore document
  factory LeaderboardMonth.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardMonth(
      monthId: doc.id,
      month: data['month'] ?? '',
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Chuyển sang Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'month': month,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Tạo month ID từ DateTime (yyyy-MM)
  static String getMonthId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Lấy month ID của tháng hiện tại
  static String getCurrentMonthId() {
    return getMonthId(DateTime.now());
  }
}

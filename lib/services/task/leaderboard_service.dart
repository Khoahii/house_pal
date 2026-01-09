import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task/leaderboard_month.dart';
import '../../models/task/leaderboard_score.dart';

class LeaderboardService {
  // Singleton pattern
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Debug flag
  static const bool _debugMode = false;

  void _log(String message) {
    if (_debugMode) print(message);
  }

  /// Lấy tháng hiện tại (yyyy-MM)
  String _getCurrentMonthId() {
    return LeaderboardMonth.getCurrentMonthId();
  }

  /// Stream danh sách điểm của tháng hiện tại
  /// Tự động sắp xếp theo score DESC
  /// Load kèm thông tin user từ userRef (parallel)
  Stream<List<LeaderboardScore>> getMonthlyScores(String roomId) {
    final monthId = _getCurrentMonthId();

    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('leaderboards')
        .doc(monthId)
        .collection('scores')
        .orderBy('score', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      // ✅ Load parallel thay vì tuần tự
      final futures = snapshot.docs.map((doc) async {
        final score = LeaderboardScore.fromFirestore(doc);
        
        try {
          final userDoc = await score.userRef.get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            return score.copyWithUserInfo(
              name: userData['name'] ?? 'Unknown',
              avatar: userData['avatarUrl'],
            );
          }
        } catch (e) {
          _log('⚠️ Lỗi load user ${score.userId}: $e');
        }
        return score;
      });
      
      return await Future.wait(futures);
    });
  }

  /// Lấy Top 3 điểm cao nhất tháng hiện tại
  Stream<List<LeaderboardScore>> getTop3(String roomId) {
    final monthId = _getCurrentMonthId();

    // ✅ Query trực tiếp với limit 3 thay vì filter sau
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('leaderboards')
        .doc(monthId)
        .collection('scores')
        .orderBy('score', descending: true)
        .limit(3) // ← Tối ưu: chỉ lấy 3
        .snapshots()
        .asyncMap((snapshot) async {
      final futures = snapshot.docs.map((doc) async {
        final score = LeaderboardScore.fromFirestore(doc);
        try {
          final userDoc = await score.userRef.get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            return score.copyWithUserInfo(
              name: userData['name'] ?? 'Unknown',
              avatar: userData['avatarUrl'],
            );
          }
        } catch (e) {
          _log('⚠️ Lỗi load user ${score.userId}: $e');
        }
        return score;
      });
      
      return await Future.wait(futures);
    });
  }

  /// Lấy điểm và rank của user hiện tại
  Stream<({LeaderboardScore? score, int? rank})?> getCurrentUserScore(
    String roomId,
    String userId,
  ) {
    return getMonthlyScores(roomId).map((scores) {
      final index = scores.indexWhere((s) => s.userId == userId);
      if (index == -1) return null;
      
      return (score: scores[index], rank: index + 1);
    });
  }

  /// Cập nhật/tạo điểm cho user với WriteBatch (atomic + hiệu quả)
  Future<void> updateScore({
    required String roomId,
    required String userId,
    required int scoreToAdd,
  }) async {
    final monthId = _getCurrentMonthId();
    
    final leaderboardRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('leaderboards')
        .doc(monthId);
    
    final scoreRef = leaderboardRef
        .collection('scores')
        .doc(userId);

    final userRef = _firestore.collection('users').doc(userId);

    try {
      _log('🏆 Cộng điểm: +$scoreToAdd cho user $userId');
      
      // Lấy điểm hiện tại
      final scoreDoc = await scoreRef.get();
      final currentScore = scoreDoc.exists 
          ? ((scoreDoc.data()?['score'] as num?)?.toInt() ?? 0)
          : 0;
      
      final newScore = currentScore + scoreToAdd;
      _log('   $currentScore → $newScore');

      // ✅ Dùng WriteBatch cho atomic operations
      final batch = _firestore.batch();
      
      // Tạo/update leaderboard document
      batch.set(leaderboardRef, {
        'month': monthId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Set điểm mới
      batch.set(scoreRef, {
        'userRef': userRef,
        'score': newScore,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      _log('✅ Cộng điểm thành công!');
      
    } catch (e) {
      _log('❌ Lỗi cộng điểm: $e');
      rethrow;
    }
  }

  /// Đặt điểm cụ thể cho user
  Future<void> setScore({
    required String roomId,
    required String userId,
    required int score,
  }) async {
    final monthId = _getCurrentMonthId();
    
    final leaderboardRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('leaderboards')
        .doc(monthId);
    
    final scoreRef = leaderboardRef.collection('scores').doc(userId);
    final userRef = _firestore.collection('users').doc(userId);

    try {
      final batch = _firestore.batch();
      
      batch.set(leaderboardRef, {
        'month': monthId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      batch.set(scoreRef, {
        'userRef': userRef,
        'score': score,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      _log('✅ Set điểm: $score');
      
    } catch (e) {
      _log('❌ Lỗi set điểm: $e');
      rethrow;
    }
  }
}

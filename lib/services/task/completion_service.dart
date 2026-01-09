import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/models/task/task_model.dart';
import 'package:house_pal/models/user/app_user.dart';
import 'package:house_pal/models/task/completion.dart';
import 'package:house_pal/services/task/leaderboard_service.dart';

class CompletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaderboardService _leaderboardService = LeaderboardService();

  /// Hoàn thành task với logic phân biệt manual/auto
  Future<void> completeTask({
    required String roomId,
    required Task task,
    required AppUser currentUser,
  }) async {
    final batch = _firestore.batch();

    try {
      // 1️⃣ Tạo completion record
      final completionsRef =
          _firestore.collection('rooms').doc(roomId).collection('completions');
      final newCompletion = completionsRef.doc();

      final completion = Completion(
        id: newCompletion.id,
        taskRef: _firestore
            .collection('rooms')
            .doc(roomId)
            .collection('tasks')
            .doc(task.id),
        userRef: _firestore.collection('users').doc(currentUser.uid),
        pointEarned: task.point,
        completedAt: Timestamp.now(),
      );

      batch.set(newCompletion, completion.toMap());

      // 2️⃣ Xử lý task dựa vào assignMode
      final taskRef = _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('tasks')
          .doc(task.id);

      if (task.assignMode == 'manual') {
        // ✅ MANUAL → XÓA task (việc 1 lần)
        print('🗑️ Xóa task manual: ${task.id}');
        batch.delete(taskRef);
        
      } else if (task.assignMode == 'auto') {
        // ✅ AUTO → XOAY VÒNG sang người tiếp theo
        if (task.rotationOrder != null && task.rotationOrder!.isNotEmpty) {
          int currentIndex = task.rotationIndex ?? 0;
          int nextIndex = (currentIndex + 1) % task.rotationOrder!.length;
          
          print('🔄 Xoay vòng task auto: ${task.id}');
          print('   Từ index $currentIndex → $nextIndex');
          
          batch.update(taskRef, {
            'rotationIndex': nextIndex,
            'updatedAt': Timestamp.now(),
          });
        } else {
          // Trường hợp auto nhưng không có rotationOrder (lỗi data)
          throw Exception('Task auto nhưng không có rotationOrder');
        }
      } else {
        // Trường hợp assignMode không hợp lệ
        print('⚠️ AssignMode không xác định: ${task.assignMode}');
      }

      // 3️⃣ Commit tất cả thay đổi cùng lúc
      print('💾 Commit batch...');
      await batch.commit();
      print('✅ Hoàn thành batch commit');

      // 4️⃣ Cộng điểm vào leaderboard (sau khi batch commit thành công)
      print('🏆 Cộng ${task.point} điểm cho user ${currentUser.uid}');
      await _leaderboardService.updateScore(
        roomId: roomId,
        userId: currentUser.uid,
        scoreToAdd: task.point,
      );
      print('✅ Đã cộng điểm vào leaderboard');
      
    } catch (e) {
      print('❌ Lỗi trong completeTask: $e');
      throw Exception('Lỗi khi hoàn thành task: $e');
    }
  }
}

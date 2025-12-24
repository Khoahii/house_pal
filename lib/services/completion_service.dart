import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/models/task_model.dart';
import 'package:house_pal/models/app_user.dart';  // ✅ Sửa từ user_model thành app_user
import 'package:house_pal/models/completion.dart';

class CompletionService {  // ✅ Đổi từ TaskService thành CompletionService
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Hoàn thành task
  Future<void> completeTask({
    required String roomId,
    required Task task,
    required AppUser currentUser,  // ✅ Sửa từ User thành AppUser
  }) async {
    try {
      final completionsRef =
          _firestore.collection('rooms').doc(roomId).collection('completions');

      // Tạo document mới
      final newCompletion = completionsRef.doc();

      final completion = Completion(
        id: newCompletion.id,
        taskRef: _firestore
            .collection('rooms')
            .doc(roomId)
            .collection('tasks')
            .doc(task.id),
        userRef: _firestore.collection('users').doc(currentUser.uid,), // ✅ Sửa từ user.id thành currentUser.uid
        pointEarned: task.point,
        completedAt: Timestamp.now(),
      );

      await newCompletion.set(completion.toMap());
    } catch (e) {
      throw Exception('Lỗi khi hoàn thành task: $e');
    }
  }
}

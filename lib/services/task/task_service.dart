import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/models/task/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy danh sách task của một room
  Stream<List<Task>> getTasks(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => Task.fromMap(d.id, d.data()))
            .toList());
  }

  // Tạo task mới (auto-assign theo task gần nhất)
  Future<void> createTask(String roomId, Task task) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final tasksRef = roomRef.collection('tasks');

    if (task.assignMode == 'auto') {
      // ✅ Lấy cả member + room_leader, chỉ loại admin
      final usersQs = await _firestore
          .collection('users')
          .where('roomId', isEqualTo: roomRef)
          .where('role', whereIn: ['member', 'room_leader'])  // ✅ sửa tại đây
          .get();

      // Sort client theo thời điểm tham gia phòng
      final usersDocs = usersQs.docs.toList()
        ..sort((a, b) {
          final ta = a.data()['createdAt'] as Timestamp?;
          final tb = b.data()['createdAt'] as Timestamp?;
          return (ta?.millisecondsSinceEpoch ?? 0)
              .compareTo(tb?.millisecondsSinceEpoch ?? 0);
        });

      final rotationOrder = usersDocs.map((d) => d.reference).toList();
      if (rotationOrder.isEmpty) {
        throw Exception('Không có thành viên hợp lệ để xoay vòng.');
      }

      // Lấy task auto gần nhất rồi tính nextIndex
      final recentQs = await tasksRef
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      QueryDocumentSnapshot<Map<String, dynamic>>? lastAutoDoc;
      for (final d in recentQs.docs) {
        if ((d.data()['assignMode'] ?? '') == 'auto') {
          lastAutoDoc = d;
          break;
        }
      }

      int lastRotationIndex = -1;
      if (lastAutoDoc != null) {
        final raw = lastAutoDoc.data()['rotationIndex'];
        if (raw is int) lastRotationIndex = raw;
      }

      final nextIndex = (lastRotationIndex + 1) % rotationOrder.length;
      final assignedUserRef = rotationOrder[nextIndex];

      final newDoc = tasksRef.doc();
      final data = task.toMap()
        ..['assignMode'] = 'auto'
        ..['rotationOrder'] = rotationOrder
        ..['rotationIndex'] = nextIndex
        ..['manualAssignedTo'] = assignedUserRef
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();

      await newDoc.set(data);
      return;
    }

    // Manual: lưu thẳng
    if (task.assignMode == 'manual') {
      final newDoc = tasksRef.doc();
      final data = task.toMap()
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await newDoc.set(data);
      return;
    }

    throw Exception('assignMode không hợp lệ: ${task.assignMode}');
  }

  // Cập nhật task
  Future<void> updateTask(String roomId, Task task) async {
    final taskRef =
        _firestore.collection('rooms').doc(roomId).collection('tasks').doc(task.id);
    final data = task.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await taskRef.update(data);
  }

  // Xóa task
  Future<void> deleteTask(String roomId, String taskId) async {
    await _firestore.collection('rooms').doc(roomId).collection('tasks').doc(taskId).delete();
  }

  // Lấy một task theo id
  Future<Task?> getTask(String roomId, String taskId) async {
    final doc = await _firestore.collection('rooms').doc(roomId).collection('tasks').doc(taskId).get();
    if (!doc.exists) return null;
    return Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/models/task_model.dart';

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
        .map((snap) => snap.docs
            .map((doc) => Task.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Thêm task mới
  Future<void> createTask(String roomId, Task task) async {
    final taskRef =
        _firestore.collection('rooms').doc(roomId).collection('tasks').doc();
    task.id = taskRef.id;
    await taskRef.set(task.toMap());
  }

  // Cập nhật task
  Future<void> updateTask(String roomId, Task task) async {
    final taskRef =
        _firestore.collection('rooms').doc(roomId).collection('tasks').doc(task.id);
    task.updatedAt = Timestamp.now();
    await taskRef.update(task.toMap());
  }

  // Xóa task
  Future<void> deleteTask(String roomId, String taskId) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // Lấy một task theo id
  Future<Task?> getTaskById(String roomId, String taskId) async {
    final doc =
        await _firestore.collection('rooms').doc(roomId).collection('tasks').doc(taskId).get();
    if (doc.exists) {
      return Task.fromMap(doc.id, doc.data()!);
    }
    return null;
  }
}

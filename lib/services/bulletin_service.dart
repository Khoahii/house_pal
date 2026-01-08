import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bulletin.dart';

class BulletinService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Bulletin>> stream(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('bulletins')
        // Bỏ các dòng .orderBy ở đây để tránh lỗi Index
        .snapshots()
        .map((snapshot) {
          // Chuyển đổi sang danh sách Model Bulletin
          List<Bulletin> list = snapshot.docs.map((d) => Bulletin.fromDoc(d)).toList();

          // Thực hiện sắp xếp bằng Dart
          list.sort((a, b) {
            // 1. Ưu tiên Ghim (isPinned = true lên đầu)
            if (a.isPinned != b.isPinned) {
              return a.isPinned ? -1 : 1;
            }
            
            // 2. Sau đó sắp xếp theo thời gian (createdAt giảm dần - mới nhất lên đầu)
            // Lưu ý: Kiểm tra null nếu trường createdAt chưa kịp nhận từ server
            if (a.createdAt != null && b.createdAt != null) {
              return b.createdAt!.compareTo(a.createdAt!);
            }
            
            return 0;
          });

          return list;
        });
  }

  Future<void> add(String roomId, String title, String content) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('bulletins')
        .add({
      'title': title,
      'content': content,
      'isPinned': false,
      'createdBy': _db.doc('users/$uid'),
      'creatorName': 'User',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> togglePin(String roomId, Bulletin b) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('bulletins')
        .doc(b.id)
        .update({
      'isPinned': !b.isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String roomId, String id) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('bulletins')
        .doc(id)
        .delete();
  }
  Future<void> update(
  String roomId,
  String bulletinId,
  String title,
  String content,
) {
  return _db
      .collection('rooms')
      .doc(roomId)
      .collection('bulletins')
      .doc(bulletinId)
      .update({
    'title': title,
    'content': content,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

}
import 'package:cloud_firestore/cloud_firestore.dart';

class Bulletin {
  final String id;
  final String title;
  final String content;
  final bool isPinned;
  final DateTime? createdAt; // Thêm trường này để sắp xếp

  Bulletin({
    required this.id,
    required this.title,
    required this.content,
    required this.isPinned,
    this.createdAt,
  });

  factory Bulletin.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Xử lý chuyển đổi từ Timestamp của Firestore sang DateTime của Dart
    DateTime? date;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        date = (data['createdAt'] as Timestamp).toDate();
      } else {
        // Đôi khi dữ liệu mẫu hoặc dữ liệu lỗi có thể là String hoặc int
        date = DateTime.tryParse(data['createdAt'].toString());
      }
    }

    return Bulletin(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      isPinned: data['isPinned'] ?? false,
      createdAt: date,
    );
  }
}
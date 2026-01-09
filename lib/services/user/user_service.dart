import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user/app_user.dart';
import 'upload_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  Future<void> updateUser({
    required String uid,
    String? name,
    String? phone,
    dynamic avatarFile, // Thay File? → dynamic (chấp nhận XFile hoặc File)
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (name != null && name.trim().isNotEmpty) {
        updates['name'] = name.trim();
      }

      if (phone != null && phone.trim().isNotEmpty) {
        updates['phone'] = phone.trim();
      }

      if (avatarFile != null) {
        final String newAvatarUrl = await UploadService.uploadImage(avatarFile);
        updates['avatarUrl'] = newAvatarUrl;
      }

      if (updates.isEmpty) {
        return;
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_usersCollection).doc(uid).update(updates);
    } catch (e) {
      throw Exception('Không thể cập nhật thông tin: $e');
    }
  }

  Future<AppUser> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      return AppUser.fromFirestore(doc);
    } catch (e) {
      throw Exception('Lỗi lấy dữ liệu người dùng: $e');
    }
  }

  //- get user by id
  Future<AppUser?> getUserById(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy dữ liệu người dùng: $e');
    }
  }
}

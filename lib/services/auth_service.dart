import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lắng nghe trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Đăng ký bằng email + password
  Future<AppUser?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Tạo document user trong Firestore
        await _createUserDocument(user, name, email);
      }
      return await getUserData(user!.uid);
    } on FirebaseAuthException catch (e) {
      String? mess = e.message;
      throw e.message ?? "Đăng ký thất bại";
    }
  }

  // Đăng nhập email/password
  Future<AppUser?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await getUserData(result.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Đăng nhập thất bại";
    }
  }

  // Tạo document user lần đầu
  Future<void> _createUserDocument(User user, String name, String email) async {
    final now = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'avatarUrl': null,
      'phone': null,
      'role': 'member',
      'roomId': null,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  // Lấy dữ liệu user từ Firestore
  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // Cập nhật profile
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    Map<String, dynamic> updateData = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) updateData['name'] = name;
    if (phone != null) updateData['phone'] = phone;
    if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;

    await _firestore.collection('users').doc(uid).update(updateData);
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  //- get user stream
  Stream<AppUser?> get currentUserStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await getUserData(user.uid);
    });
  }

  // Kiểm tra xem user đã tham gia phòng nào chưa
  Future<bool> userHasRoom(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final roomId = data['roomId'];

      return roomId != null && roomId.toString().isNotEmpty;
    } catch (e) {
      debugPrint("Error checking user roommmm: $e");
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user/app_user.dart';
import '../services/auth/auth_service.dart';

/*
 * Nhiệm vụ là lưu thông user toàn cục để dùng ở mọi screen 
 */

class MyAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  MyAuthProvider() {
    // Tự động lắng nghe khi app khởi động
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
      } else {
        _currentUser = await _authService.getUserData(firebaseUser.uid);
      }
      notifyListeners(); // cập nhật toàn app
    });
  }

  // Làm mới thủ công (nếu cần)
  Future<void> refreshUser() async {
    if (uid != null) {
      _currentUser = await _authService.getUserData(uid!);
      notifyListeners();
    }
  }
}

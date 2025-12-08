import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Commom/Auth/login_screen.dart';
import 'package:house_pal/Screens/Commom/MainPage/main_screen.dart';
import 'package:house_pal/services/auth_service.dart';


//- file có tác dụng là để check trang thai dang nhập cua nguoi dung, neu dang nhap roi thi vao man hinh chinh, chua thi vao man hinh dang nhap

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Đang kết nối
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Đã có user (đã login trc đó) → vào app
        if (snapshot.hasData && snapshot.data != null) {
          return MainScreen();
        }

        // Chưa đăng nhập → hiện Login
        return LoginScreen();
      },
    );
  }
}

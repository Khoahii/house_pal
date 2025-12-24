import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Commom/Auth/login_screen.dart';
import 'package:house_pal/Screens/Commom/MainPage/main_screen.dart';
import 'package:house_pal/Screens/Commom/Onboading/OnboadingParent.dart';
import 'package:house_pal/Screens/Commom/Rooms/join_room_screen.dart';
import 'package:house_pal/Screens/Commom/Splash/splash_screen.dart';
import 'package:house_pal/Screens/admin/AdminMainPage/admin_main_page_screen.dart';
import 'package:house_pal/models/app_user.dart';
import 'package:house_pal/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isOnboardingCompleted(),
      builder: (context, snapshot) {
        // 1. Chờ kiểm tra Onboarding
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final onboardingDone = snapshot.data ?? false;
        if (!onboardingDone) {
          return const OnboadingParentScreen();
        }

        // 2. Theo dõi trạng thái đăng nhập từ Firebase
        return StreamBuilder<User?>(
          stream: AuthService().authStateChanges,
          builder: (context, userSnap) {
            // Đang kết nối với Firebase Auth
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            // CHƯA ĐĂNG NHẬP
            if (!userSnap.hasData) {
              return const LoginScreen();
            }

            // ĐÃ ĐĂNG NHẬP -> Tiếp tục lấy dữ liệu Role và Room từ Firestore
            return FutureBuilder<AppUser?>(
              // Sử dụng key để tránh build lại không cần thiết nếu UID không đổi
              key: ValueKey(userSnap.data!.uid),
              future: AuthService().getAppUserData(userSnap.data!.uid),
              builder: (context, roleSnap) {
                if (roleSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child:
                          CircularProgressIndicator(), // Chỉ hiện vòng xoay nhẹ
                    ),
                  );
                }

                if (roleSnap.hasData && roleSnap.data != null) {
                  final appUser = roleSnap.data!;

                  // A. Nếu là ADMIN
                  if (appUser.role == 'admin') {
                    return const AdminMainScreen();
                  }

                  // B. Nếu là MEMBER hoặc ROOM_LEADER
                  // Kiểm tra xem đã có phòng hay chưa (DocumentReference chỉ cần check null)
                  if (appUser.roomId != null) {
                    // Nếu đã gắn vào một Reference (có phòng) -> Vào trang chính
                    return const MainScreen();
                  } else {
                    // Nếu roomId là null (chưa có phòng) -> Yêu cầu tham gia/tạo phòng
                    return JoinRoomScreen();
                  }
                }

                // Trường hợp có Auth nhưng Firestore không có data (lỗi dữ liệu)
                return const LoginScreen();
              },
            );
          },
        );
      },
    );
  }
}

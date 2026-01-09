import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Commom/Auth/login_screen.dart';
import 'package:house_pal/Screens/Commom/MainPage/main_screen.dart';
import 'package:house_pal/Screens/Commom/Onboading/OnboadingParent.dart';
import 'package:house_pal/Screens/Commom/Rooms/join_room_screen.dart';
import 'package:house_pal/Screens/Commom/Splash/splash_screen.dart';
import 'package:house_pal/Screens/admin/AdminMainPage/admin_main_page_screen.dart';
import 'package:house_pal/models/user/app_user.dart';
import 'package:house_pal/services/auth/auth_service.dart';
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
      builder: (context, onboardSnap) {
        if (onboardSnap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Nếu chưa hoàn thành onboarding
        if (!(onboardSnap.data ?? false)) {
          return const OnboadingParentScreen();
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnap) {
            // Đang kiểm tra trạng thái đăng nhập từ Firebase Auth
            if (authSnap.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            // TRƯỜNG HỢP 1: Chưa đăng nhập
            if (!authSnap.hasData || authSnap.data == null) {
              return const LoginScreen();
            }

            // TRƯỜNG HỢP 2: Đã có User (Auth thành công) -> Lấy Profile từ Firestore
            return FutureBuilder<AppUser?>(
              key: ValueKey(authSnap.data!.uid),
              future: AuthService().getUserData(authSnap.data!.uid),
              builder: (context, userSnap) {
                // 1. Trong lúc đợi dữ liệu từ Firestore SAU KHI bấm đăng nhập
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: Color(0xFF121212),
                    body: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                  );
                }

                // 2. Khi đã có dữ liệu (hasData)
                if (userSnap.hasData && userSnap.data != null) {
                  final appUser = userSnap.data!;

                  //- nếu là admin thì nhảy vào AdminMainScreen trước khi nó check tới JoinRoomScreen
                  if (appUser.role == 'admin') return const AdminMainScreen();

                  return (appUser.roomId != null)
                      ? const MainScreen()
                      : JoinRoomScreen();
                }

                // 3. Nếu lỗi hoặc không thấy data
                return const LoginScreen();
              },
            );
          },
        );
      },
    );
  }
}

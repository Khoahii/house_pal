import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Commom/Auth/login_screen.dart';
import 'package:house_pal/Screens/Commom/MainPage/main_screen.dart';
import 'package:house_pal/Screens/Commom/Onboading/OnboadingParent.dart';
import 'package:house_pal/Screens/Commom/Splash/splash_screen.dart';
import 'package:house_pal/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


//- file có tác dụng là để check trang thai dang nhập cua nguoi dung, neu dang nhap roi thi vao man hinh chinh, chua thi vao man hinh dang nhap

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
        if (!snapshot.hasData) {
          return const SplashScreen(); // loading đẹp
        }

        final onboardingDone = snapshot.data!;

        return StreamBuilder<User?>(
          stream: AuthService().authStateChanges,
          builder: (context, userSnap) {
            //- màn splash
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            //- chưa hoàn thành onboarding
            if (!onboardingDone) {
              return const OnboadingParentScreen();
            }

            //- đã login
            if (userSnap.hasData) {
              return const MainScreen();
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}


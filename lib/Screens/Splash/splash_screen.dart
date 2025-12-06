import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Onboading/OnboadingParent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  //- xu ly xem da hoan thanh Onboarding chua
  Future<void> handleSuccessOnbroading(BuildContext context) async {
    final isCompleted = await _isCheckCompletedOnboarding();

    if (isCompleted) {
      if (!context.mounted) return;
      //- navigation to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Container(child: Text("haha"))),
      );
    } else {
      //- o lai Onboading
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboadingParentScreen()),
      );
    }
  }

  //- func check
  Future<bool> _isCheckCompletedOnboarding() async {
    try {
      //- dung thu vien shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final result = prefs.getBool('onboarding_completed') ?? false;
      return result;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    handleSuccessOnbroading(context);
    return const Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              "🏠 HousePal",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Trợ lý Ngôi nhà Chung",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

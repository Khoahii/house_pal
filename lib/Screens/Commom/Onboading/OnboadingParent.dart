import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Commom/Auth/login_screen.dart';
import 'package:house_pal/Screens/Commom/Onboading/OnboadingChild.dart';
import 'package:house_pal/ultils/enum/OnboardingPosition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboadingParentScreen extends StatefulWidget {
  const OnboadingParentScreen({super.key});

  @override
  State<OnboadingParentScreen> createState() => _OnboadingParentScreenState();
}

class _OnboadingParentScreenState extends State<OnboadingParentScreen> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          //color background
          children: [
            OnboadingChildScreen(
              onboardingposition: Onboardingposition.page1,
              handleSkip: () {
                _gotoMainScreen();
              },
              handleNext: () => _pageController.jumpToPage(1),
              handleBack: () => {},
            ),
            OnboadingChildScreen(
              onboardingposition: Onboardingposition.page2,
              handleSkip: () {
                _gotoMainScreen();
              },
              handleNext: () => _pageController.jumpToPage(2),
              handleBack: () => _pageController.jumpToPage(0),
            ),
            OnboadingChildScreen(
              onboardingposition: Onboardingposition.page3,
              handleSkip: () {
                _gotoMainScreen();
              },
              handleNext: () => {_gotoMainScreen()},
              handleBack: () => _pageController.jumpToPage(1),
            ),
          ],
        ),
      ),
    );
  }

  void _gotoMainScreen() async {
    await _setOnboardingCompleted();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _setOnboardingCompleted() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Client/Funds/main_screen.dart';
import 'package:house_pal/Screens/Client/Home/client_home.dart';
import 'package:house_pal/Screens/Client/News/news.dart';
import 'package:house_pal/Screens/Client/Task/main_task_screen.dart';
import 'package:house_pal/Screens/Commom/Profile/profile.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ClientHome(onViewAllTasks: () => _changeTab(1)),
      MainTaskScreen(),
      MainFundScreen(),
      NewsScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      //- Hiển thị trang tương ứng với index hiện tại
      body: IndexedStack(index: _currentIndex, children: _pages),

      //- IndexedStack thay vì _pages[_currentIndex], giữ nguyên trạng thái của từng tab (không bị rebuild lại khi chuyển tab)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.white,
        selectedItemColor: const Color(0xFF8687E7),
        backgroundColor: const Color(0xFF363636),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/bottom_icon_home.png',
              width: 24,
              height: 24,
            ),
            activeIcon: Image.asset(
              'assets/images/bottom_icon_home.png',
              width: 24,
              height: 24,
              color: const Color(0xFF8687E7),
            ),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/bottom_icon_task.png',
              width: 24,
              height: 24,
            ),
            activeIcon: Image.asset(
              'assets/images/bottom_icon_task.png',
              width: 24,
              height: 24,
              color: const Color(0xFF8687E7),
            ),
            label: 'Việc nhà',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/bottom_icon_fund.png',
              width: 24,
              height: 24,
            ),
            activeIcon: Image.asset(
              'assets/images/bottom_icon_fund.png',
              width: 24,
              height: 24,
              color: const Color(0xFF8687E7),
            ),
            label: 'Quỹ chung',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/bottom_icon_news.png',
              width: 24,
              height: 24,
            ),
            activeIcon: Image.asset(
              'assets/images/bottom_icon_news.png',
              width: 24,
              height: 24,
              color: const Color(0xFF8687E7),
            ),
            label: 'Bảng tin',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/bottom_icon_user.png',
              width: 24,
              height: 24,
            ),
            activeIcon: Image.asset(
              'assets/images/bottom_icon_user.png',
              width: 24,
              height: 24,
              color: const Color(0xFF8687E7),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

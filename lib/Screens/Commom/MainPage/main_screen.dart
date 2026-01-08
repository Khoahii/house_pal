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
        selectedIconTheme: const IconThemeData(size: 26),
        unselectedIconTheme: const IconThemeData(size: 24),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_rounded),
            label: 'Việc nhà',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Quỹ chung',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_rounded),
            label: 'Bảng tin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

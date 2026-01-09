import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Commom/Profile/profile.dart';
import 'package:house_pal/Screens/admin/Dashboard/admin_dashboard_screen.dart';
import 'package:house_pal/Screens/admin/Room/admin_room_screen.dart';
import 'package:house_pal/Screens/admin/User/admin_user_screen.dart';


class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  // Danh sách các trang
  final List<Widget> _pages = [
    AdminDashboardScreen(),
    AdminRoomScreen(),
    // AdminUserScreen(),
    ProfileScreen(),
  ];

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
            icon: Icon(Icons.meeting_room_rounded),
            label: 'Phòng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Người dùng',
          ),
        ],
      ),
    );
  }
}

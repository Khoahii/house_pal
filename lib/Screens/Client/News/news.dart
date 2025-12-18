import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/models/shopping.dart';
import 'package:house_pal/services/shopping_service.dart';

import 'note.dart';
import 'shopping.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  int tabIndex = 0;

  late DocumentReference<Map<String, dynamic>> roomRef;


  /// 🔐 QUYỀN USER
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();

    // ⚠️ ví dụ: roomId bạn lấy từ AppUser / Provider
    roomRef = FirebaseFirestore.instance.collection('rooms').doc('ROOM_ID_CUA_BAN');
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final role = userDoc.data()?['role'] ?? 'member';

    setState(() {
      isAdmin = role == 'admin';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: const [
            Text(
              "🏠 HousePal",
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Trợ lý Ngôi nhà Chung",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bảng tin Chung",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            const Text(
              "Thông tin & Ghi chú",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            _buildTabSelector(),
            const SizedBox(height: 12),

            if (tabIndex == 0)
              NoteTab(isAdmin: isAdmin, roomRef: roomRef),

            if (tabIndex == 1)
              ShoppingTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _pillTab(
              label: "Ghi chú",
              selected: tabIndex == 0,
              onTap: () => setState(() => tabIndex = 0),
            ),
          ),
          Expanded(
            child: _pillTab(
              label: "Mua sắm",
              selected: tabIndex == 1,
              onTap: () => setState(() => tabIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
  

}

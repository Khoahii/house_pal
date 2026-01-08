import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'note_tab.dart';
import 'shopping_tab.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  int tabIndex = 0;

  DocumentReference? roomRef;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRoomAndRole();
  }

  Future<void> _loadRoomAndRole() async {
  try {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1️⃣ Lấy user
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists || userDoc['roomId'] == null) {
      throw Exception('User chưa có roomId');
    }

    final DocumentReference loadedRoomRef = userDoc['roomId'];

    // 2️⃣ Lấy member (AN TOÀN)
    final memberSnap = await loadedRoomRef
        .collection('members')
        .doc(uid)
        .get();

    String role = 'member'; // default an toàn

    if (memberSnap.exists && memberSnap.data() != null) {
      role = memberSnap['role'] ?? 'member';
    }

    if (mounted) {
      setState(() {
        roomRef = loadedRoomRef;
        isAdmin = role == 'admin' || role == 'leader';
      });
    }
  } catch (e) {
    debugPrint('❌ Load room/role error: $e');

    // fallback: vẫn cho vào app, KHÔNG treo
    setState(() {
      roomRef = null;
      isAdmin = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    if (roomRef == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              "🏠 HousePal",
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
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

      // ✅ FAB CHỈ CHO TAB NOTE
      floatingActionButton: tabIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // NOTE TAB chỉ cần roomId = roomRef.id
                NoteTab.showAddDialog(context, roomRef!.id);
              },
              child: const Icon(Icons.add),
            )
          : null,

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bảng tin Chung",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Thông tin & Ghi chú",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _tabSelector(),
            const SizedBox(height: 12),
            Expanded(
              child: tabIndex == 0
                  // ✅ NOTE dùng roomId
                  ? NoteTab(
                      roomId: roomRef!.id,
                      isAdmin: isAdmin,
                    )
                  // ✅ SHOPPING GIỮ NGUYÊN
                  : ShoppingTab(
                      roomRef: roomRef!,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB SELECTOR =================

  Widget _tabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _tab("Ghi chú", 0),
          _tab("Mua sắm", 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tabIndex = index),
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
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

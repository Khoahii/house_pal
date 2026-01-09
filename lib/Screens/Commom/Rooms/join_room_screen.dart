import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/Screens/Commom/MainPage/main_screen.dart';
import 'package:house_pal/models/user/app_user.dart';
import 'package:house_pal/models/room/room.dart';
import 'package:house_pal/providers/auth_provider.dart';
import 'package:house_pal/services/notify/snack_bar_service.dart';
import 'package:house_pal/services/room/room_service.dart';
import 'package:provider/provider.dart';

class JoinRoomScreen extends StatelessWidget {
  final RoomService _roomService = RoomService();

  JoinRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Tham gia phòng",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                Provider.of<MyAuthProvider>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: Consumer<MyAuthProvider>(
        builder: (context, authProvider, child) {
          final currentUser = authProvider.currentUser;

          // SỬA LỖI: Nếu null, chúng ta thử ép refresh lại một lần hoặc hiển thị nút thử lại
          if (currentUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text("Đang tải thông tin tài khoản..."),
                  TextButton(
                    onPressed: () => authProvider.refreshUser(),
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Lỗi: ${snapshot.error}"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.meeting_room_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text("Chưa có phòng nào", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                );
              }

              final rooms = snapshot.data!.docs
                  .map((doc) => Room.fromFirestore(doc))
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  return RoomCard(room: rooms[index], currentUser: currentUser);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final Room room;
  final AppUser currentUser;

  const RoomCard({super.key, required this.room, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final bool isPrivileged =
        currentUser.role == 'admin' || currentUser.role == 'room_leader';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    room.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPrivileged)
                  Chip(
                    label: Text(
                      room.code,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.orange.shade100,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAvatarStack(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showJoinDialog(context),
                icon: const Icon(Icons.vpn_key),
                label: const Text("Tham gia phòng"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF10B981,
                  ), // Dùng màu xanh lá thành công
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    return FutureBuilder<List<AppUser>>(
      future: _fetchMembers(room.members),
      builder: (context, snapshot) {
        final members = snapshot.data ?? [];
        return Row(
          children: [
            SizedBox(
              width: (members.take(6).length * 28.0) + 12,
              height: 40,
              child: Stack(
                children: members.take(6).toList().asMap().entries.map((e) {
                  int idx = e.key;
                  AppUser member = e.value;
                  return Positioned(
                    left: idx * 28.0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: member.avatarUrl != null
                            ? NetworkImage(member.avatarUrl!)
                            : null,
                        child: member.avatarUrl == null
                            ? Text(
                                member.name.isNotEmpty
                                    ? member.name[0].toUpperCase()
                                    : "?",
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (members.length > 6)
              Text(
                " +${members.length - 6}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const Spacer(),
            Text(
              "${room.members.length} thành viên",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

  void _showJoinDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận tham gia"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Phòng: ${room.name}"),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: "Mã phòng",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              final inputCode = codeController.text.trim().toUpperCase();
              if (inputCode == room.code) {
                Navigator.pop(ctx);
                _joinRoomConfirmed(context);
              } else {
                SnackBarService
                .showError(context, "Mã phòng không chính xác!");
              }
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  void _joinRoomConfirmed(BuildContext context) async {
    try {
      await RoomService().joinRoomByCode(room.code);

      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
      await authProvider.refreshUser();

      if (context.mounted) {
        SnackBarService.showSuccess(
          context,
          "Chào mừng bạn đến với ${room.name}!",
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) SnackBarService.showError(context, "Lỗi: $e");
    }
  }

  Future<List<AppUser>> _fetchMembers(List<DocumentReference> refs) async {
    if (refs.isEmpty) return [];
    try {
      final snapshots = await Future.wait(refs.map((ref) => ref.get()));
      return snapshots
          .where((snap) => snap.exists)
          .map((snap) => AppUser.fromFirestore(snap))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

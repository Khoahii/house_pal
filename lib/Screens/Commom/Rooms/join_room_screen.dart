import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/models/user/app_user.dart';
import 'package:house_pal/models/room/room.dart';
import 'package:house_pal/providers/auth_provider.dart';
import 'package:house_pal/services/room/room_service.dart';
import 'package:provider/provider.dart';

class JoinRoomScreen extends StatelessWidget {
  final RoomService _roomService = RoomService();

  JoinRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tham gia phòng")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!.docs
              .map((doc) => Room.fromFirestore(doc))
              .toList();

          if (rooms.isEmpty) {
            return Center(
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

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Consumer<MyAuthProvider>(
                builder: (context, authProvider, child) {
                  final currentUser = authProvider.currentUser;
                  if (currentUser == null) return SizedBox();

                  return RoomCard(room: room, currentUser: currentUser);
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
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên phòng + mã (chỉ admin/leader thấy mã)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    room.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isPrivileged)
                  Chip(
                    label: Text(
                      room.code,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.orange.shade100,
                  ),
              ],
            ),
            SizedBox(height: 12),

            // Avatar thành viên
            FutureBuilder<List<AppUser>>(
              future: _fetchMembers(room.members),
              builder: (context, snapshot) {
                final members = snapshot.data ?? [];
                return Row(
                  children: [
                    Stack(
                      children: members.take(6).toList().asMap().entries.map((
                        e,
                      ) {
                        int idx = e.key;
                        AppUser member = e.value;
                        return Transform.translate(
                          offset: Offset(idx * 28.0, 0),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: member.avatarUrl != null
                                ? null
                                : Colors.primaries[member.name.hashCode.abs() %
                                      Colors.primaries.length],
                            backgroundImage: member.avatarUrl != null
                                ? NetworkImage(member.avatarUrl!)
                                : null,
                            child: member.avatarUrl == null
                                ? Text(
                                    member.name.isNotEmpty
                                        ? member.name[0].toUpperCase()
                                        : "?",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    if (members.length > 6)
                      Transform.translate(
                        offset: Offset(6 * 28.0, 0),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade600,
                          child: Text(
                            "+${members.length - 6}",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    Spacer(),
                    Text(
                      "${room.members.length} thành viên",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 20),

            // Nút tham gia → hiện dialog nhập mã
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showJoinDialog(context),
                icon: Icon(Icons.vpn_key),
                label: Text("Tham gia phòng"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
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

  // Dialog nhập mã
  void _showJoinDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Nhập mã tham gia"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Phòng: ${room.name}"),
            SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: "Mã phòng",
                border: OutlineInputBorder(),
                counterText: "",
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 10,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              final inputCode = codeController.text.trim().toUpperCase();
              if (inputCode == room.code) {
                Navigator.pop(ctx); // đóng dialog
                _joinRoomConfirmed(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Mã phòng sai! Vui lòng thử lại."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  // Join phòng khi mã đúng
  void _joinRoomConfirmed(BuildContext context) async {
    try {
      await RoomService().joinRoomByCode(room.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã tham gia phòng: ${room.name}"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  // Lấy danh sách thành viên
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

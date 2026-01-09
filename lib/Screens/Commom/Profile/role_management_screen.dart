import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/models/user/app_user.dart';
import 'package:house_pal/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Map<String, String> roleLabel = {
    "admin": "Admin",
    "room_leader": "Room Leader",
    "member": "Member",
  };

  static const Map<String, Color> roleColor = {
    "admin": Colors.red,
    "room_leader": Colors.deepPurple,
    "member": Colors.grey,
  };

  Stream<QuerySnapshot<Map<String, dynamic>>> _membersStream(AppUser me) {
    final DocumentReference? myRoomRef = me.roomId;

    if (me.role == 'admin') {
      return _firestore
          .collection('users')
          .where('role', whereIn: ['member', 'room_leader'])
          .snapshots();
    }

    if (me.role == 'room_leader') {
      if (myRoomRef == null) return const Stream.empty();

      return _firestore
          .collection('users')
          .where('roomId', isEqualTo: myRoomRef)
          .where('role', whereIn: ['member', 'room_leader'])
          .snapshots();
    }

    return const Stream.empty();
  }

  Future<void> _updateRole({
    required String uid,
    required String newRole,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<MyAuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Phân quyền thành viên',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: me == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _membersStream(me),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Không có thành viên để hiển thị.'),
                  );
                }

                final users =
                    docs.map((d) => AppUser.fromFirestore(d)).toList();

                users.sort((a, b) {
                  int rank(String r) => r == 'room_leader' ? 0 : 1;
                  final ra = rank(a.role);
                  final rb = rank(b.role);
                  if (ra != rb) return ra.compareTo(rb);
                  return a.name.compareTo(b.name);
                });

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(me),
                    const SizedBox(height: 16),
                    ...users.map((u) => _memberTile(context, me, u)),
                  ],
                );
              },
            ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _buildHeader(AppUser me) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              me.role == 'admin'
                  ? 'Danh sách người dùng (không hiển thị Admin)'
                  : 'Danh sách thành viên trong phòng của bạn',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(BuildContext context, AppUser me, AppUser u) {
    final isMe = u.uid == me.uid;
    final currentRole = u.role;

    final allowedRoles = me.role == 'admin'
        ? ['member', 'room_leader', 'admin']
        : ['member', 'room_leader'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                roleColor[currentRole]?.withOpacity(0.15) ?? Colors.grey[200],
            child: Icon(
              Icons.person,
              color: roleColor[currentRole] ?? Colors.grey,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.name.isNotEmpty ? u.name : u.email,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMe ? 'Bạn' : u.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: roleColor[currentRole] ?? Colors.grey,
              ),
            ),
            child: DropdownButton<String>(
              value: currentRole,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down),
              items: allowedRoles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        roleLabel[r] ?? r,
                        style: TextStyle(
                          color: roleColor[r] ?? Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;

                if (me.role != 'admin' && value == 'admin') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Room Leader không thể cấp quyền Admin.'),
                    ),
                  );
                  return;
                }

                await _updateRole(uid: u.uid, newRole: value);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã cập nhật ${u.name} → ${roleLabel[value]}',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

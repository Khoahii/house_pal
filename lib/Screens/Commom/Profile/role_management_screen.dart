import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/models/app_user.dart';
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

  /// Stream lấy danh sách user theo role của người đang đăng nhập
  Stream<QuerySnapshot<Map<String, dynamic>>> _membersStream(AppUser me) {
    // roomId của bạn đang là DocumentReference? (đúng theo AppUser)
    final DocumentReference? myRoomRef = me.roomId;

    // ADMIN: thấy tất cả user của mọi phòng, nhưng KHÔNG hiển thị role=admin
    if (me.role == 'admin') {
      return _firestore
          .collection('users')
          .where('role', whereIn: ['member', 'room_leader'])
          .snapshots();
    }

    // ROOM_LEADER: thấy tất cả user trong phòng của mình (member + room_leader), KHÔNG hiển thị admin
    if (me.role == 'room_leader') {
      if (myRoomRef == null) {
        // Không có phòng => stream rỗng
        return const Stream.empty();
      }

      // Quan trọng: roomId là DocumentReference => query phải so sánh đúng DocumentReference
      return _firestore
          .collection('users')
          .where('roomId', isEqualTo: myRoomRef)
          .where('role', whereIn: ['member', 'room_leader'])
          .snapshots();
    }

    // Member thường không được vào màn này, trả stream rỗng
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
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Phân quyền thành viên'),
        centerTitle: true,
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
                  // Trường hợp room_leader không có roomId hoặc phòng chưa có ai
                  return const Center(
                    child: Text('Không có thành viên để hiển thị.'),
                  );
                }

                // Convert sang AppUser để dùng field rõ ràng
                final users = docs
                    .map((d) => AppUser.fromFirestore(d))
                    .toList();

                // Sort: room_leader lên trước, member sau
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
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me.role == 'admin'
                                ? "Danh sách (mọi phòng) — không hiển thị Admin"
                                : "Danh sách phòng của bạn — gồm Member & Room Leader",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ...users.map((u) {
                            final currentRole = u.role;
                            final isMe = u.uid == me.uid;

                            // admin được set đủ 3 role, room_leader chỉ được set member/room_leader
                            final allowedRoles = me.role == 'admin'
                                ? ['member', 'room_leader', 'admin']
                                : ['member', 'room_leader'];

                            // Nếu room_leader đang xem, dropdown không có admin
                            // Và user list đã không có admin rồi.

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F7FB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline,
                                      color: Colors.deepPurple),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u.name.isNotEmpty ? u.name : u.email,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isMe ? "Bạn" : (u.email),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  DropdownButton<String>(
                                    value: currentRole,
                                    underline: const SizedBox(),
                                    items: allowedRoles
                                        .map(
                                          (r) => DropdownMenuItem(
                                            value: r,
                                            child: Text(roleLabel[r] ?? r),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) async {
                                      if (value == null) return;

                                      // Optional: chặn room_leader tự set ai đó thành admin
                                      if (me.role != 'admin' &&
                                          value == 'admin') {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Room Leader không thể cấp quyền Admin.'),
                                          ),
                                        );
                                        return;
                                      }

                                      await _updateRole(
                                        uid: u.uid,
                                        newRole: value,
                                      );

                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Đã cập nhật ${u.name} -> ${roleLabel[value] ?? value}',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

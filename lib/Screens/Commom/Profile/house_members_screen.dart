import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:house_pal/models/user/app_user.dart';

// Constants
class _RoleConfig {
  static const String roomLeader = 'room_leader';
  static const String member = 'member';
  
  static Map<String, dynamic> getConfig(String role) {
    switch (role) {
      case roomLeader:
        return {
          'label': 'Quản lý phòng',
          'color': const Color(0xFFA16207),
          'bgColor': const Color(0xFFFEF9C3),
        };
      default:
        return {
          'label': 'Thành viên',
          'color': const Color(0xFF6B7280),
          'bgColor': const Color(0xFFF3F4F6),
        };
    }
  }
}

class HouseMembersScreen extends StatefulWidget {
  final DocumentReference roomRef;
  const HouseMembersScreen({super.key, required this.roomRef});

  @override
  State<HouseMembersScreen> createState() => _HouseMembersScreenState();
}

class _HouseMembersScreenState extends State<HouseMembersScreen> {
  late final Stream<DocumentSnapshot> _roomStream;

  @override
  void initState() {
    super.initState();
    _roomStream = widget.roomRef.snapshots();
  }

  Future<List<AppUser>> _fetchMembers(List<DocumentReference> refs) async {
    if (refs.isEmpty) return [];
    final snaps = await Future.wait(refs.map((ref) async {
      try {
        final doc = await ref.get();
        if (doc.exists) return AppUser.fromFirestore(doc);
      } catch (e) {
        debugPrint('Load member failed: $e');
      }
      return null;
    }));
    return snaps.whereType<AppUser>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Thành viên trong nhà'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _roomStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy phòng'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? '';
          final code = data['code'] ?? '';
          final members = List<DocumentReference>.from(data['members'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoomCard(name: name, code: code, memberCount: members.length),
                const SizedBox(height: 16),
                const Text(
                  'Danh sách thành viên',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<AppUser>>(
                  future: _fetchMembers(members),
                  builder: (context, memberSnapshot) {
                    if (memberSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final users = memberSnapshot.data ?? [];
                    if (users.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Chưa có thành viên trong phòng.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _MemberTile(user: users[index]),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String name;
  final String code;
  final int memberCount;
  const _RoomCard({required this.name, required this.code, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tên phòng', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(
            name.isNotEmpty ? name : 'Chưa đặt tên',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Mã phòng', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  code.isNotEmpty ? code : 'Chưa có mã',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              IconButton(
                onPressed: code.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép mã phòng')),
                        );
                      },
                icon: const Icon(Icons.copy, color: Colors.deepPurple),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.group, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                '$memberCount thành viên',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final AppUser user;
  const _MemberTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatar = user.avatarUrl ?? 'https://i.pravatar.cc/150?img=8';
    final roleConfig = _RoleConfig.getConfig(user.role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(avatar),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : 'Thành viên',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleConfig['bgColor'],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    roleConfig['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: roleConfig['color'],
                    ),
                  ),
                ),
              ],
            ), 
          ),
        ],
      ),
    );
  }
}
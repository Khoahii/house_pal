import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/services/notify/snack_bar_service.dart';
import '../../../models/room/room.dart';
import '../../../models/user/app_user.dart';
import '../../../services/room/room_service.dart';
import '../../../services/user/user_service.dart';

class AdminRoomScreen extends StatefulWidget {
  const AdminRoomScreen({super.key});

  @override
  State<AdminRoomScreen> createState() => _AdminRoomScreenState();
}

class _AdminRoomScreenState extends State<AdminRoomScreen> {
  final RoomService _roomService = RoomService();
  final UserService _userService = UserService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Controller và biến lưu giá trị tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Quản lý Phòng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _showUnassignedUsersSheet(context),
            icon: const Icon(Icons.person_search, color: Colors.deepPurple),
            tooltip: 'Người dùng tự do',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(), // Thanh tìm kiếm nằm cố định ở trên
          Expanded(
            child: StreamBuilder<List<Room>>(
              stream: _roomService.allRoomsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allRooms = snapshot.data ?? [];

                // Thực hiện lọc dữ liệu theo Query
                final filteredRooms = allRooms.where((room) {
                  final nameMatch = room.name.toLowerCase().contains(
                    _searchQuery,
                  );
                  final codeMatch = room.code.toLowerCase().contains(
                    _searchQuery,
                  );
                  return nameMatch || codeMatch;
                }).toList();

                if (filteredRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Chưa có phòng nào.'
                              : 'Không tìm thấy phòng phù hợp.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) =>
                      _buildRoomItem(filteredRooms[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRoomDialog(context),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // --- HÀM XỬ LÝ XÓA PHÒNG (Kèm dọn dẹp thành viên) ---
  Future<void> _deleteRoom(Room room) async {
    bool confirm = await _showConfirmDialog(
      'Xác nhận xóa phòng "${room.name}"?',
      content:
          'Tất cả thành viên trong phòng này sẽ trở thành người dùng tự do.',
    );

    if (!confirm) return;

    try {
      WriteBatch batch = _db.batch();

      // 1. Cập nhật tất cả member của phòng đó: roomId = null
      for (var memberRef in room.members) {
        batch.update(memberRef, {
          'roomId': null,
          'role': 'member',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Xóa document phòng
      batch.delete(_db.collection('rooms').doc(room.id));

      await batch.commit();

      if (mounted) {
        SnackBarService.showSuccess(
          context,
          'Đã xóa phòng "${room.name}" thành công',
        );
      }
    } catch (e) {
      if (mounted)
        SnackBarService.showError(context, 'Không thể xóa phòng: $e');
    }
  }

  // --- HÀM SỬA TÊN PHÒNG ---
  void _showEditRoomDialog(Room room) {
    final nameController = TextEditingController(text: room.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa tên phòng'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nhập tên phòng mới'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              String newName = nameController.text.trim();
              if (newName.isEmpty) return;
              try {
                await _db.collection('rooms').doc(room.id).update({
                  'name': newName,
                });
                if (mounted) {
                  Navigator.pop(context);
                  SnackBarService.showSuccess(
                    context,
                    'Đã đổi tên phòng thành $newName',
                  );
                }
              } catch (e) {
                if (mounted)
                  SnackBarService.showError(context, 'Lỗi cập nhật: $e');
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // --- WIDGET ITEM PHÒNG ---
  Widget _buildRoomItem(Room room) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade50,
          child: const Icon(Icons.home_work, color: Colors.deepPurple),
        ),
        title: Text(
          room.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Mã: ${room.code} • ${room.members.length} thành viên'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.blue),
              onPressed: () => _showEditRoomDialog(room),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteRoom(room),
            ),
          ],
        ),
        children: [const Divider(height: 1), _buildMemberList(room)],
      ),
    );
  }

  // --- DANH SÁCH THÀNH VIÊN TRONG PHÒNG ---
  Widget _buildMemberList(Room room) {
    if (room.members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Phòng trống', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: room.members.map((memberRef) {
        return FutureBuilder<AppUser?>(
          future: _userService.getUserById(memberRef.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final user = snapshot.data!;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null ? Text(user.name[0]) : null,
              ),
              title: Text(user.name),
              subtitle: Text(
                user.role == 'room_leader' ? 'Trưởng phòng' : 'Thành viên',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _onMemberAction(value, user, room),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'kick',
                    child: Text('Xóa khỏi phòng'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Xóa tài khoản',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  // --- LOGIC XỬ LÝ ACTION USER ---
  void _onMemberAction(String action, AppUser user, Room room) async {
    if (action == 'kick') {
      bool confirm = await _showConfirmDialog('Đuổi ${user.name} khỏi phòng?');
      if (confirm) {
        try {
          await _db.collection('rooms').doc(room.id).update({
            'members': FieldValue.arrayRemove([
              _db.collection('users').doc(user.uid),
            ]),
          });
          await _db.collection('users').doc(user.uid).update({
            'roomId': null,
            'role': 'member',
          });
          if (mounted)
            SnackBarService.showInfo(context, 'Đã mời ${user.name} rời phòng');
        } catch (e) {
          if (mounted) SnackBarService.showError(context, 'Lỗi: $e');
        }
      }
    } else if (action == 'delete') {
      bool confirm = await _showConfirmDialog(
        'Xóa VĨNH VIỄN tài khoản ${user.name}?',
      );
      if (confirm) {
        try {
          await _db.collection('users').doc(user.uid).delete();
          if (room.id.isNotEmpty) {
            await _db.collection('rooms').doc(room.id).update({
              'members': FieldValue.arrayRemove([
                _db.collection('users').doc(user.uid),
              ]),
            });
          }
          if (mounted)
            SnackBarService.showSuccess(context, 'Đã xóa tài khoản người dùng');
        } catch (e) {
          if (mounted)
            SnackBarService.showError(context, 'Lỗi xóa tài khoản: $e');
        }
      }
    }
  }

  // --- MÀN HÌNH USER TỰ DO ---
  void _showUnassignedUsersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Người dùng tự do',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('users')
                    .where('roomId', isNull: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final users = snapshot.data!.docs
                      .map((d) => AppUser.fromFirestore(d))
                      .toList();
                  if (users.isEmpty)
                    return const Center(
                      child: Text('Không có người dùng tự do'),
                    );

                  return ListView.builder(
                    controller: controller,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(u.name),
                        subtitle: Text(u.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.add_home,
                                color: Colors.blue,
                              ),
                              onPressed: () => _showAssignRoomPicker(u),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              onPressed: () => _onMemberAction(
                                'delete',
                                u,
                                Room(
                                  id: '',
                                  name: '',
                                  code: '',
                                  members: [],
                                  createdAt: DateTime.now(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CHỈ ĐỊNH PHÒNG ---
  void _showAssignRoomPicker(AppUser user) async {
    final rooms = await _db.collection('rooms').get();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đưa ${user.name} vào:'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: rooms.docs.length,
            itemBuilder: (context, index) {
              final r = Room.fromFirestore(rooms.docs[index]);
              return ListTile(
                title: Text(r.name),
                onTap: () async {
                  try {
                    await _db.collection('rooms').doc(r.id).update({
                      'members': FieldValue.arrayUnion([
                        _db.collection('users').doc(user.uid),
                      ]),
                    });
                    await _db.collection('users').doc(user.uid).update({
                      'roomId': _db.collection('rooms').doc(r.id),
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      SnackBarService.showSuccess(
                        context,
                        'Đã đưa ${user.name} vào phòng ${r.name}',
                      );
                    }
                  } catch (e) {
                    if (mounted) SnackBarService.showError(context, 'Lỗi: $e');
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // --- TẠO PHÒNG ---
  void _showCreateRoomDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo phòng mới'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Tên phòng'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await _roomService.createRoom(nameController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    SnackBarService.showSuccess(
                      context,
                      'Tạo phòng thành công',
                    );
                  }
                } catch (e) {
                  if (mounted)
                    SnackBarService.showError(context, 'Lỗi tạo phòng: $e');
                }
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  // --- DIALOG XÁC NHẬN ---
  Future<bool> _showConfirmDialog(String title, {String? content}) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: Text(content ?? title),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Đồng ý',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // --- SEARCH BAR WIDGET ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm tên phòng hoặc mã phòng...',
          prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

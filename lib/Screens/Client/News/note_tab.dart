import 'package:flutter/material.dart';
import '../../../models/bulletin.dart';
import '../../../services/bulletin_service.dart';

class NoteTab extends StatefulWidget {
  final String roomId;
  final bool isAdmin;

  const NoteTab({
    super.key,
    required this.roomId,
    required this.isAdmin,
  });

  @override
  State<NoteTab> createState() => _NoteTabState();

  // Giữ lại hàm static để gọi từ bên ngoài (ví dụ từ FloatingActionButton)
  static void showAddDialog(BuildContext context, String roomId) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final service = BulletinService();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thêm ghi chú"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Tiêu đề"),
            ),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(labelText: "Nội dung"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                service.add(
                  roomId,
                  titleCtrl.text,
                  contentCtrl.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }
}

class _NoteTabState extends State<NoteTab> {
  // Khởi tạo service và stream ở cấp độ State
  late final BulletinService _service;
  late Stream<List<Bulletin>> _bulletinStream;

  @override
  void initState() {
    super.initState();
    _service = BulletinService();
    // Khởi tạo stream một lần duy nhất khi vào trang
    _bulletinStream = _service.stream(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Bulletin>>(
      stream: _bulletinStream, // Sử dụng stream đã cố định, không tạo mới khi build
      builder: (context, snapshot) {
        // 1. Trạng thái lỗi
        if (snapshot.hasError) {
          print("Lỗi từ Stream: ${snapshot.error}");
          return const Center(child: Text("Đã xảy ra lỗi khi tải dữ liệu"));
        }

        // 2. Trạng thái đang tải (Chỉ hiện khi chưa có dữ liệu nào)
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // 3. Trạng thái không có dữ liệu
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text("Chưa có ghi chú nào"));
        }

        final pinned = data.where((b) => b.isPinned).toList();
        final others = data.where((b) => !b.isPinned).toList();

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (pinned.isNotEmpty) ...[
              const Text(
                '📌 Ghim',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...pinned.map((b) => _card(context, b)),
              const SizedBox(height: 16),
            ],
            if (others.isNotEmpty) ...[
              ...others.map((b) => _card(context, b)),
            ],
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, Bulletin b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          b.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(b.content),
        trailing: widget.isAdmin
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'pin') {
                    _service.togglePin(widget.roomId, b);
                  }
                  if (value == 'delete') {
                    _service.delete(widget.roomId, b.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Text(b.isPinned ? 'Bỏ ghim' : 'Ghim'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xóa'),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

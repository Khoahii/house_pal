import 'package:flutter/material.dart';
import '../../../models/note/bulletin.dart';
import '../../../services/note/bulletin_service.dart';

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

  // =======================
  // THÊM GHI CHÚ
  // =======================
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

  // =======================
  // SỬA GHI CHÚ
  // =======================
  static void showEditDialog(
    BuildContext context,
    String roomId,
    Bulletin bulletin,
  ) {
    final titleCtrl = TextEditingController(text: bulletin.title);
    final contentCtrl = TextEditingController(text: bulletin.content);
    final service = BulletinService();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa ghi chú"),
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
                service.update(
                  roomId,
                  bulletin.id,
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
  late final BulletinService _service;
  late final Stream<List<Bulletin>> _bulletinStream;

  @override
  void initState() {
    super.initState();
    _service = BulletinService();
    _bulletinStream = _service.stream(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Bulletin>>(
      stream: _bulletinStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Đã xảy ra lỗi khi tải dữ liệu"));
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

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
            ...others.map((b) => _card(context, b)),
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, Bulletin b) {
  return Card(
    elevation: 3, // Thêm shadow cho card
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: b.isPinned ? Colors.purple.shade50 : Colors.white,
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Icon(
        b.isPinned ? Icons.push_pin : Icons.sticky_note_2_outlined,
        color: b.isPinned ? Colors.purple : Colors.blueGrey,
      ),
      title: Text(
        b.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: b.isPinned ? Colors.purple.shade700 : Colors.black87,
        ),
      ),
      subtitle: Text(
        b.content,
        style: const TextStyle(fontSize: 14, height: 1.3),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) async {
          if (value == 'edit') {
            NoteTab.showEditDialog(context, widget.roomId, b);
          } else if (value == 'pin') {
            _service.togglePin(widget.roomId, b);
          } else if (value == 'delete') {
            await _service.delete(widget.roomId, b.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xoá ghi chú')),
              );
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Sửa')],
            ),
          ),
          PopupMenuItem(
            value: 'pin',
            child: Row(
              children: [
                Icon(b.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                const SizedBox(width: 8),
                Text(b.isPinned ? 'Bỏ ghim' : 'Ghim'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Xoá')],
            ),
          ),
        ],
      ),
    ),
  );
}



}

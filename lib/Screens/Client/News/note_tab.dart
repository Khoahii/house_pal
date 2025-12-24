import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/bulletin.dart';
import '../../../services/bulletin_service.dart';


class NoteTab extends StatelessWidget {
  final DocumentReference roomRef;
  final bool isAdmin;

  NoteTab({super.key, required this.roomRef, required this.isAdmin});

  final _service = BulletinService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Bulletin>>(
      stream: _service.bulletinsStream(roomRef),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pinned =
            snapshot.data!.where((e) => e.isPinned).toList();
        final others =
            snapshot.data!.where((e) => !e.isPinned).toList();

        return ListView(
          children: [
            if (isAdmin) _addButton(context),
            if (pinned.isNotEmpty) _section("📌 Ghim", pinned),
            if (others.isNotEmpty) _section("Ghi chú khác", others),
          ],
        );
      },
    );
  }

  Widget _addButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _openAdd(context),
      child: const Text("+ Thêm ghi chú mới"),
    );
  }

  Widget _section(String title, List<Bulletin> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map(_card),
      ],
    );
  }

  Widget _card(Bulletin b) {
    return Card(
      child: ListTile(
        title: Text(b.title),
        subtitle: Text(b.content),
        trailing: isAdmin
            ? IconButton(
                icon: Icon(
                    b.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                onPressed: () => _service.togglePin(
                  roomRef.collection('bulletins').doc(b.id),
                  !b.isPinned,
                ),
              )
            : null,
      ),
    );
  }

  void _openAdd(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: "Tiêu đề")),
            TextField(controller: contentCtrl, decoration: const InputDecoration(hintText: "Nội dung")),
            ElevatedButton(
              onPressed: () {
                _service.createBulletin(
                  roomRef: roomRef,
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  type: 'note',
                  creatorName: 'Bạn',
                );
                Navigator.pop(context);
              },
              child: const Text("Thêm"),
            )
          ],
        ),
      ),
    );
  }
}

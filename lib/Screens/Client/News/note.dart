import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/services/note_service.dart';

class NoteTab extends StatefulWidget {
  final bool isAdmin;
  final DocumentReference<Map<String, dynamic>> roomRef;


  const NoteTab({
    super.key,
    required this.isAdmin,
    required this.roomRef,
  });

  @override
  State<NoteTab> createState() => _NoteTabState();
}

class _NoteTabState extends State<NoteTab> {
  final NoteService _noteService = NoteService();

  // =======================
  // MOCK DATA (LOCAL)
  // =======================
  
  @override
Widget build(BuildContext context) {
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _noteService.getNotes(widget.roomRef),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (snapshot.hasError) {
        return const Center(child: Text('❌ Lỗi tải ghi chú'));
      }

      final docs = snapshot.data?.docs ?? [];

      if (docs.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: Text('Chưa có ghi chú')),
        );
      }

      final pinned = docs.where((d) => d['pinned'] == true).toList();
      final other = docs.where((d) => d['pinned'] != true).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddButton(),
          const SizedBox(height: 14),

          if (pinned.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.push_pin,
                    size: 18, color: Colors.deepPurple),
                const SizedBox(width: 6),
                Text(
                  "Ghim (${pinned.length})",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...pinned.map(_noteCard).toList(),
            const SizedBox(height: 14),
          ],

          if (other.isNotEmpty) ...[
            const Text(
              "Ghi chú khác",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ...other.map(_noteCard).toList(),
          ],
        ],
      );
    },
  );
}

  // =======================
  // ADD BUTTON (ADMIN ONLY)
  // =======================
  Widget _buildAddButton() {
    // ❌ Member KHÔNG được thêm ghi chú
    if (!widget.isAdmin) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: () => _openAddOrEditNote(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: const Text(
          '+  Thêm ghi chú mới',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // =======================
  // NOTE CARD
  // =======================
  Widget _noteCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F7),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.notes_rounded,
              color: Colors.black54, size: 18),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['title'] ?? '',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                data['content'] ?? '',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),

        if (widget.isAdmin)
          Column(
            children: [
              IconButton(
                icon: Icon(
                  data['pinned'] == true
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                  color: Colors.deepPurple,
                ),
                onPressed: () => _noteService.updateNote(
                  roomRef: widget.roomRef,
                  noteId: doc.id,
                  title: data['title'],
                  content: data['content'],
                  pinned: !(data['pinned'] == true),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _noteService.deleteNote(
                      roomRef: widget.roomRef,
                      noteId: doc.id,
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'delete', child: Text('Xoá')),
                ],
              ),
            ],
          ),
      ],
    ),
  );
}

 
  Future<void> _openAddOrEditNote({
  String? editId,
  String? oldTitle,
  String? oldContent,
  bool oldPinned = false,
}) async {
  final isEdit = editId != null;

  final titleCtrl = TextEditingController(text: oldTitle ?? '');
  final contentCtrl = TextEditingController(text: oldContent ?? '');
  bool pinned = oldPinned;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      final bottom = MediaQuery.of(context).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottom),
        child: StatefulBuilder(
          builder: (context, setLocal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isEdit ? "Sửa ghi chú" : "Thêm ghi chú",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    hintText: "Tiêu đề",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Nội dung...",
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: pinned,
                      onChanged: (v) => setLocal(() => pinned = v ?? false),
                    ),
                    const Text("Ghim ghi chú"),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      final t = titleCtrl.text.trim();
                      final c = contentCtrl.text.trim();
                      if (t.isEmpty || c.isEmpty) return;

                      if (isEdit) {
                        await _noteService.updateNote(
                          roomRef: widget.roomRef,
                          noteId: editId!,
                          title: t,
                          content: c,
                          pinned: pinned,
                        );
                      } else {
                        await _noteService.addNote(
                          roomRef: widget.roomRef,
                          title: t,
                          content: c,
                          pinned: pinned,
                        );
                      }

                      Navigator.pop(context);
                    },
                    child: Text(isEdit ? "Lưu" : "Thêm"),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

}

// =======================
// LOCAL MODEL (only for this tab)
// =======================

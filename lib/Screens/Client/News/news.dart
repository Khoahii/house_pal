import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  int tabIndex = 0; // 0 = Ghi chú, 1 = Mua sắm

  // =======================
  // MOCK DATA (LOCAL)
  // =======================
  final List<_Note> _notes = [
    _Note(
      id: 'n1',
      title: 'Mật khẩu Wifi',
      content: 'ID: AHIHI\nPassword: ahihi123@',
      pinned: true,
    ),
    _Note(
      id: 'n2',
      title: 'Liên hệ chủ nhà',
      content: 'Anh Minh: 0982857979\n(Có việc gì liên hệ trước 8PM)',
      pinned: true,
    ),
    _Note(
      id: 'n3',
      title: 'Quy định chung',
      content: '- Không ồn sau 10PM\n- Đóng cửa chính khi ra ngoài\n- Tắt điều hoà khi không có người',
      pinned: false,
    ),
    _Note(
      id: 'n4',
      title: 'Lịch sửa chữa',
      content: 'Thợ điện sẽ đến sửa công tắc phòng khách\nThứ 7, 18/11 lúc 2PM',
      pinned: false,
    ),
  ];

  final List<_ShoppingItem> _shopping = [
    _ShoppingItem(id: 's1', name: 'Giấy vệ sinh (12 cuộn)', info: 'Chi • 15/11', purchased: false),
    _ShoppingItem(id: 's2', name: 'Nước rửa bát Sunlight', info: 'Bình • 15/11', purchased: false),
    _ShoppingItem(id: 's3', name: 'Túi rác (loại lớn)', info: 'Anh Nguyễn • 14/11', purchased: false),
    _ShoppingItem(id: 's4', name: 'Dầu gội Clear', info: 'Em • 14/11', purchased: false),
    _ShoppingItem(id: 's5', name: 'Nước lau sàn', info: 'Đăng • 13/11', purchased: true),
  ];

  // =======================
  // HELPERS (SORT)
  // =======================
  List<_Note> get _pinnedNotes => _notes.where((e) => e.pinned).toList();
  List<_Note> get _otherNotes => _notes.where((e) => !e.pinned).toList();

  List<_ShoppingItem> get _needBuy => _shopping.where((e) => !e.purchased).toList();
  List<_ShoppingItem> get _bought => _shopping.where((e) => e.purchased).toList();

  String get _addButtonText => tabIndex == 0 ? '+  Thêm ghi chú mới' : '+  Thêm vào danh sách';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: const [
            Text(
              "🏠 HousePal",
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Trợ lý Ngôi nhà Chung",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bảng tin Chung",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            const Text(
              "Thông tin & Ghi chú",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            _buildTabSelector(),
            const SizedBox(height: 12),

            _buildAddButton(),
            const SizedBox(height: 14),

            if (tabIndex == 0) _buildNotesUI(),
            if (tabIndex == 1) _buildShoppingUI(),
          ],
        ),
      ),
    );
  }

  // =======================
  // TAB SELECTOR (FIGMA-LIKE)
  // =======================
  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _pillTab(
              label: "Ghi chú",
              selected: tabIndex == 0,
              onTap: () => setState(() => tabIndex = 0),
            ),
          ),
          Expanded(
            child: _pillTab(
              label: "Mua sắm (${_needBuy.length})",
              selected: tabIndex == 1,
              onTap: () => setState(() => tabIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  // =======================
  // ADD BUTTON
  // =======================
  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: () {
          if (tabIndex == 0) {
            _openAddOrEditNote();
          } else {
            _openAddOrEditShopping();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          _addButtonText,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // =======================
  // NOTES UI
  // =======================
  Widget _buildNotesUI() {
    final pinned = _pinnedNotes;
    final other = _otherNotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pinned.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.push_pin, size: 18, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Text("Ghim (${pinned.length})",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ...pinned.map(_noteCard).toList(),
          const SizedBox(height: 14),
        ],
        if (other.isNotEmpty) ...[
          const Text("Ghi chú khác", style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 10),
          ...other.map(_noteCard).toList(),
        ],
      ],
    );
  }

  Widget _noteCard(_Note note) {
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
          // icon bubble
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F7),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.notes_rounded, color: Colors.black54, size: 18),
          ),
          const SizedBox(width: 12),

          // content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  note.content,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.25),
                ),
              ],
            ),
          ),

          // right actions
          Column(
            children: [
              IconButton(
                tooltip: note.pinned ? 'Bỏ ghim' : 'Ghim',
                icon: Icon(
                  note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: Colors.deepPurple,
                ),
                onPressed: () => _togglePin(note.id),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _openAddOrEditNote(editId: note.id);
                  if (value == 'delete') _deleteNote(note.id);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Sửa')),
                  PopupMenuItem(value: 'delete', child: Text('Xoá')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _togglePin(String id) {
    setState(() {
      final idx = _notes.indexWhere((e) => e.id == id);
      if (idx >= 0) {
        _notes[idx] = _notes[idx].copyWith(pinned: !_notes[idx].pinned);
        // pinned luôn lên đầu list (cảm giác "hiện trên đầu")
        _notes.sort((a, b) => (b.pinned ? 1 : 0).compareTo(a.pinned ? 1 : 0));
      }
    });
  }

  void _deleteNote(String id) {
    setState(() => _notes.removeWhere((e) => e.id == id));
  }

  Future<void> _openAddOrEditNote({String? editId}) async {
    final isEdit = editId != null;
    _Note? existing = isEdit ? _notes.firstWhere((e) => e.id == editId) : null;

    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    bool pinned = existing?.pinned ?? false;

    final result = await showModalBottomSheet<bool>(
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
                      Text(isEdit ? "Sửa ghi chú" : "Thêm ghi chú",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: "Tiêu đề",
                      filled: true,
                      fillColor: const Color(0xFFF6F7FB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Nội dung...",
                      filled: true,
                      fillColor: const Color(0xFFF6F7FB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Checkbox(
                        value: pinned,
                        onChanged: (v) => setLocal(() => pinned = v ?? false),
                      ),
                      const Text("Ghim ghi chú"),
                    ],
                  ),

                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        final t = titleCtrl.text.trim();
                        final c = contentCtrl.text.trim();
                        if (t.isEmpty || c.isEmpty) return;

                        setState(() {
                          if (isEdit) {
                            final idx = _notes.indexWhere((e) => e.id == editId);
                            _notes[idx] = _notes[idx].copyWith(title: t, content: c, pinned: pinned);
                          } else {
                            _notes.insert(
                              0,
                              _Note(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: t,
                                content: c,
                                pinned: pinned,
                              ),
                            );
                          }

                          // pinned lên đầu nhóm ghim
                          _notes.sort((a, b) => (b.pinned ? 1 : 0).compareTo(a.pinned ? 1 : 0));
                        });

                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(isEdit ? "Lưu" : "Thêm",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result == true) {
      // optional
    }
  }

  // =======================
  // SHOPPING UI
  // =======================
  Widget _buildShoppingUI() {
    final need = _needBuy;
    final bought = _bought;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (need.isNotEmpty) ...[
          Text("Cần mua (${need.length})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...need.map(_shoppingItemCard).toList(),
          const SizedBox(height: 14),
        ],
        if (bought.isNotEmpty) ...[
          Text("Đã mua (${bought.length})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...bought.map(_shoppingItemCard).toList(),
        ],
      ],
    );
  }

  Widget _shoppingItemCard(_ShoppingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
      decoration: BoxDecoration(
        color: item.purchased ? const Color(0xFFEFFAF2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.purchased ? Colors.green : const Color(0xFFEDEDED)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.purchased,
            onChanged: (v) => _togglePurchased(item.id, v ?? false),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: item.purchased ? TextDecoration.lineThrough : TextDecoration.none,
                    color: item.purchased ? Colors.black54 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.info, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _openAddOrEditShopping(editId: item.id);
              if (value == 'delete') _deleteShopping(item.id);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Sửa')),
              PopupMenuItem(value: 'delete', child: Text('Xoá')),
            ],
          ),
        ],
      ),
    );
  }

  void _togglePurchased(String id, bool purchased) {
    setState(() {
      final idx = _shopping.indexWhere((e) => e.id == id);
      if (idx >= 0) {
        _shopping[idx] = _shopping[idx].copyWith(purchased: purchased);

        // ✅ ĐẨY XUỐNG CUỐI: luôn sort "chưa mua" lên trước, "đã mua" xuống sau
        _shopping.sort((a, b) {
          final ap = a.purchased ? 1 : 0;
          final bp = b.purchased ? 1 : 0;
          return ap.compareTo(bp); // 0 trước 1
        });
      }
    });
  }

  void _deleteShopping(String id) {
    setState(() => _shopping.removeWhere((e) => e.id == id));
  }

  Future<void> _openAddOrEditShopping({String? editId}) async {
    final isEdit = editId != null;
    _ShoppingItem? existing = isEdit ? _shopping.firstWhere((e) => e.id == editId) : null;

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final infoCtrl = TextEditingController(text: existing?.info ?? '');

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(isEdit ? "Sửa mục mua sắm" : "Thêm mục mua sắm",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: "Tên sản phẩm cần mua",
                  filled: true,
                  fillColor: const Color(0xFFF6F7FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: infoCtrl,
                decoration: InputDecoration(
                  hintText: "Ghi chú (vd: người thêm • ngày)",
                  filled: true,
                  fillColor: const Color(0xFFF6F7FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final info = infoCtrl.text.trim();
                    if (name.isEmpty) return;

                    setState(() {
                      if (isEdit) {
                        final idx = _shopping.indexWhere((e) => e.id == editId);
                        _shopping[idx] = _shopping[idx].copyWith(
                          name: name,
                          info: info.isEmpty ? _shopping[idx].info : info,
                        );
                      } else {
                        _shopping.insert(
                          0,
                          _ShoppingItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            info: info.isEmpty ? "Bạn • hôm nay" : info,
                            purchased: false,
                          ),
                        );
                      }

                      // luôn sort lại để "đã mua" xuống cuối
                      _shopping.sort((a, b) {
                        final ap = a.purchased ? 1 : 0;
                        final bp = b.purchased ? 1 : 0;
                        return ap.compareTo(bp);
                      });
                    });

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(isEdit ? "Lưu" : "Thêm",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =======================
// MODELS (LOCAL ONLY)
// =======================
class _Note {
  final String id;
  final String title;
  final String content;
  final bool pinned;

  _Note({
    required this.id,
    required this.title,
    required this.content,
    required this.pinned,
  });

  _Note copyWith({String? title, String? content, bool? pinned}) {
    return _Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      pinned: pinned ?? this.pinned,
    );
  }
}

class _ShoppingItem {
  final String id;
  final String name;
  final String info;
  final bool purchased;

  _ShoppingItem({
    required this.id,
    required this.name,
    required this.info,
    required this.purchased,
  });

  _ShoppingItem copyWith({String? name, String? info, bool? purchased}) {
    return _ShoppingItem(
      id: id,
      name: name ?? this.name,
      info: info ?? this.info,
      purchased: purchased ?? this.purchased,
    );
  }
}

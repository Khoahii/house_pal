import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/models/shopping.dart';
import 'package:house_pal/services/shopping_service.dart';

class ShoppingTab extends StatelessWidget {
  // final DocumentReference roomRef;
  final ShoppingService _shoppingService = ShoppingService();

  // const ShoppingTab({
  //   super.key,
  //   required this.roomRef,
  // });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShoppingItem>>(
      stream: _shoppingService.getByRoom().map((snapshot) => 
          snapshot.docs
              .map((doc) => ShoppingItem.fromFirestore(doc))
              .toList()
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text('❌ Lỗi tải danh sách mua sắm'));
        }

        final items = snapshot.data ?? [];
        final needBuy = items.where((e) => !e.purchased).toList();
        final bought = items.where((e) => e.purchased).toList();

        if (items.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAddButton(context),
                const SizedBox(height: 40),
                const Center(child: Text('Chưa có mục mua sắm')),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddButton(context),
              const SizedBox(height: 14),

              if (needBuy.isNotEmpty) ...[
                _sectionTitle('Cần mua (${needBuy.length})'),
                const SizedBox(height: 10),
                ...needBuy.map((e) => _shoppingItemCard(context, e)),
                const SizedBox(height: 14),
              ],

              if (bought.isNotEmpty) ...[
                _sectionTitle('Đã mua (${bought.length})'),
                const SizedBox(height: 10),
                ...bought.map((e) => _shoppingItemCard(context, e)),
              ],
            ],
          ),
        );
      },
    );
  }

  // =======================
  // ADD BUTTON
  // =======================
  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: () => _openAddOrEditSheet(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: const Text(
          '+  Thêm vào danh sách',
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
  // ITEM CARD
  // =======================
  Widget _shoppingItemCard(BuildContext context, ShoppingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
      decoration: BoxDecoration(
        color: item.purchased ? const Color(0xFFEFFAF2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.purchased ? Colors.green : const Color(0xFFEDEDED),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.purchased,
            onChanged: (v) => ShoppingService().togglePurchased(
              item.id,
              v ?? false,
            ),
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
                    decoration: item.purchased
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.assignedName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openAddOrEditSheet(context, editItem: item);
              }
              if (value == 'delete') {
                ShoppingService().deleteItem(item.id);
              }
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

  // =======================
  // SECTION TITLE
  // =======================
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  // =======================
  // ADD / EDIT BOTTOM SHEET
  // =======================
  Future<void> _openAddOrEditSheet(
    BuildContext context, {
    ShoppingItem? editItem,
  }) async {
    final isEdit = editItem != null;

    final nameCtrl = TextEditingController(text: editItem?.name ?? '');
    final assignedCtrl =
        TextEditingController(text: editItem?.assignedName ?? '');

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
                  Text(
                    isEdit ? 'Sửa mục mua sắm' : 'Thêm mục mua sắm',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Tên sản phẩm',
                  filled: true,
                  fillColor: Color(0xFFF6F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: assignedCtrl,
                decoration: const InputDecoration(
                  hintText: 'Người mua (vd: Chi)',
                  filled: true,
                  fillColor: Color(0xFFF6F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final assigned = assignedCtrl.text.trim();
                    if (name.isEmpty) return;

                    final service = ShoppingService();

                    if (isEdit) {
                      await service.updateItem(
                        itemId: editItem!.id,
                        name: name,
                        assignedName: assigned,
                      );
                    } else {
                      await service.addItem(
                        // roomRef: roomRef,
                        name: name,
                        assignedName: assigned,
                      );
                    }

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEdit ? 'Lưu' : 'Thêm',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

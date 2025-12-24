import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/shopping_item.dart';
import '../../../services/shopping_service.dart';
import '../../../services/fund_service.dart';
import '../../../models/fund.dart';
import 'package:house_pal/Screens/Client/Funds/create_or_edit_Expense.dart';


class ShoppingTab extends StatelessWidget {
  final DocumentReference roomRef;
  ShoppingTab({super.key, required this.roomRef});

  final _service = ShoppingService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShoppingItem>>(
      stream: _service.shoppingStream(roomRef),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final unbought =
            snapshot.data!.where((e) => e.linkedExpenseId == null);
        final bought =
            snapshot.data!.where((e) => e.linkedExpenseId != null);

        return ListView(
          children: [
            _addButton(context),
            _section("🛒 Cần mua", unbought.toList()),
            _section("✅ Đã mua", bought.toList()),
          ],
        );
      },
    );
  }

  Widget _addButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _openAddOrEditSheet(context),
      child: const Text("+ Thêm vào danh sách"),
    );
  }

  Widget _section(String title, List<ShoppingItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...items.map(_card),
      ],
    );
  }

  Widget _card(ShoppingItem item) {
    final done = item.linkedExpenseId != null;
    return Card(
      color: done ? Colors.green.shade50 : null,
      child: ListTile(
        title: Text(item.title),
        subtitle: Text("Quỹ: ${item.fundName}"),
        trailing:
            done ? const Icon(Icons.check_circle, color: Colors.green) : null,
      ),
    );
  }

  void _openAddOrEditSheet(
  BuildContext context, {
  ShoppingItem? editItem,
}) {
  final isEdit = editItem != null;

  final titleCtrl = TextEditingController(text: editItem?.title ?? '');
  final noteCtrl = TextEditingController(text: editItem?.note ?? '');

  String? selectedFundId = editItem?.fundId;
  String? selectedFundName = editItem?.fundName;

  final fundService = FundService();
  final shoppingService = ShoppingService();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      final bottom = MediaQuery.of(context).viewInsets.bottom;

      return Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: StatefulBuilder(
          builder: (context, setLocal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER =====
                Row(
                  children: [
                    Text(
                      isEdit ? 'Sửa mục mua sắm' : 'Thêm mục mua sắm',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ===== TITLE =====
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Tên sản phẩm',
                    filled: true,
                  ),
                ),

                const SizedBox(height: 10),

                // ===== NOTE =====
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ghi chú (tuỳ chọn)',
                    filled: true,
                  ),
                ),

                const SizedBox(height: 14),

                // ===== FUND DROPDOWN =====
                StreamBuilder<List<Fund>>(
                  stream: fundService.getMyFundsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final funds = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      value: selectedFundId,
                      hint: const Text('Chọn quỹ'),
                      items: funds.map((fund) {
                        return DropdownMenuItem(
                          value: fund.id,
                          child: Text(fund.name),
                        );
                      }).toList(),
                      onChanged: (v) {
                        final fund =
                            funds.firstWhere((f) => f.id == v);
                        setLocal(() {
                          selectedFundId = fund.id;
                          selectedFundName = fund.name;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ===== ACTION BUTTONS =====
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final note = noteCtrl.text.trim();

                      if (title.isEmpty ||
                          selectedFundId == null ||
                          selectedFundName == null) {
                        return;
                      }

                      if (isEdit) {
                        await roomRef
                            .collection('shopping_items')
                            .doc(editItem!.id)
                            .update({
                          'title': title,
                          'note': note.isEmpty ? null : note,
                          'fundId': selectedFundId,
                          'fundName': selectedFundName,
                          'updatedAt':
                              FieldValue.serverTimestamp(),
                        });
                      } else {
                        await shoppingService.addItem(
                          roomRef: roomRef,
                          title: title,
                          note: note,
                          fundId: selectedFundId!,
                          fundName: selectedFundName!,
                        );
                      }

                      Navigator.pop(context);
                    },
                    child: Text(isEdit ? 'Lưu' : 'Thêm'),
                  ),
                ),

                // ===== DELETE + CREATE EXPENSE =====
                if (isEdit) ...[
                  const SizedBox(height: 12),

                  // DELETE
                  TextButton(
                    onPressed: () async {
                      await roomRef
                          .collection('shopping_items')
                          .doc(editItem!.id)
                          .delete();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.red),
                    child: const Text('Xóa mục này'),
                  ),

                  // CREATE EXPENSE
                  if (editItem!.linkedExpenseId == null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                            CreateOrEditExpenseScreen(
                              fundId: editItem.fundId,
                              memberRefs: const [], // hoặc lấy từ room nếu bạn có
                            )

                            ),
                          );
                        },
                        child: const Text('Tạo chi tiêu'),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      );
    },
  );
}

}

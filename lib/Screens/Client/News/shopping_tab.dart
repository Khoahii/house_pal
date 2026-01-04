import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/services/snack_bar_service.dart';
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

        final unbought = snapshot.data!.where((e) => e.linkedExpenseId == null);
        final bought = snapshot.data!.where((e) => e.linkedExpenseId != null);

        return ListView(
          children: [
            _addButton(context),
            _section(context, "🛒 Cần mua", unbought.toList()),
            _section(context, "✅ Đã mua", bought.toList()),
          ],
        );
      },
    );
  }

  Widget _addButton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text(" Thêm mua sắm"),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _openAddOrEditSheet(context),
      ),
    ),
  );
}

Widget _section(
  BuildContext context,
  String title,
  List<ShoppingItem> items,
) {
  if (items.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 6),
            
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((e) => _card(context, e)),
      ],
    ),
  );
}

Widget _card(BuildContext context, ShoppingItem item) {
  final done = item.linkedExpenseId != null;

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: done ? Colors.green.shade50 : Colors.white,
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      onTap: done ? null : () => _openAddOrEditSheet(context, editItem: item),
      // Xóa leading icon hoàn toàn
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          decoration: done ? TextDecoration.lineThrough : null,
          color: done ? Colors.green.shade800 : Colors.black87,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quỹ: ${item.fundName}"),
          if (item.note != null)
            Text(
              item.note!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) async {
          if (value == 'edit' && !done) {
            _openAddOrEditSheet(context, editItem: item);
          }

          if (value == 'delete') {
            await roomRef.collection('shopping_items').doc(item.id).delete();
            if (context.mounted) {
              SnackBarService.showSuccess(context, "Đã xoá mục mua sắm");
            }
          }
        },
        itemBuilder: (_) => [
          if (!done)
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Sửa'),
                ],
              ),
            ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Xoá'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}



  void _openAddOrEditSheet(BuildContext context, {ShoppingItem? editItem}) {
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
                          final fund = funds.firstWhere((f) => f.id == v);
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
                          SnackBarService.showError(context, "Vui lòng nhập đủ thông tin");
                          return;
                        }

                        if (isEdit) {
                          await roomRef
                              .collection('shopping_items')
                              .doc(editItem.id)
                              .update({
                                'title': title,
                                'note': note.isEmpty ? null : note,
                                'fundId': selectedFundId,
                                'fundName': selectedFundName,
                                'updatedAt': FieldValue.serverTimestamp(),
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

                    // CREATE EXPENSE
                    if (editItem.linkedExpenseId == null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context); // Đóng BottomSheet mua sắm

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateOrEditExpenseScreen(
                                  fundId: editItem.fundId,
                                  initialTitle:
                                      editItem.title, // Dán tên đồ vào
                                  shoppingItemId: editItem.id,
                                  roomRef: roomRef,
                                ),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:house_pal/models/user/app_user.dart';
import 'package:house_pal/models/fund/expense.dart';
import 'package:house_pal/services/fund/expense_service.dart';
import 'package:house_pal/services/notify/snack_bar_service.dart';
import 'package:house_pal/ultils/fund/fund_category.dart';
import 'package:house_pal/ultils/fund/money_fomat.dart';
import 'package:intl/intl.dart';

class CreateOrEditExpenseScreen extends StatefulWidget {
  final String fundId;
  final List<DocumentReference> memberRefs;
  final Expense? expense;
  final bool? canModify;

  final String? initialTitle;
  final String? shoppingItemId;
  final DocumentReference? roomRef;

  const CreateOrEditExpenseScreen({
    super.key,
    required this.fundId,
    this.memberRefs = const [],
    this.expense,
    this.canModify,
    this.initialTitle,
    this.shoppingItemId,
    this.roomRef,
  });

  bool get isEdit => expense != null;

  @override
  State<CreateOrEditExpenseScreen> createState() =>
      _CreateOrEditExpenseScreenState();
}

class _CreateOrEditExpenseScreenState extends State<CreateOrEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final ExpenseService _expenseService = ExpenseService();

  List<AppUser> _members = [];
  bool _loadingMembers = true;
  DocumentReference? _paidBy;
  DateTime _date = DateTime.now();
  FundCategory? _selectedCategory;

  /// equal | custom
  String _splitType = 'equal';
  final Map<DocumentReference, int> _splitDetail = {};
  final Set<DocumentReference> _selectedMembers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null && !widget.isEdit) {
      _titleCtrl.text = widget.initialTitle!;
    }
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    List<DocumentReference> refs = widget.memberRefs;

    if (refs.isEmpty) {
      final fundDoc = await FirebaseFirestore.instance
          .collection('funds')
          .doc(widget.fundId)
          .get();
      if (fundDoc.exists) {
        final data = fundDoc.data() as Map<String, dynamic>;
        refs = List<DocumentReference>.from(data['members'] ?? []);
      }
    }

    final snaps = await Future.wait(refs.map((e) => e.get()));
    final users = snaps
        .where((d) => d.exists)
        .map(AppUser.fromFirestore)
        .toList();

    if (mounted) {
      setState(() {
        _members = users;
        _loadingMembers = false;

        if (!widget.isEdit) {
          // 1. Tự động chọn tất cả thành viên
          _selectedMembers.addAll(users.map((u) => _userRef(u.uid)));

          // 2. Tự động chọn người trả là User hiện tại
          final currentUid = FirebaseAuth.instance.currentUser?.uid;
          if (currentUid != null) {
            _paidBy = _userRef(currentUid);
          } else if (users.isNotEmpty) {
            _paidBy = _userRef(users.first.uid);
          }
        }
      });

      if (widget.isEdit) _initEditData();
    }
  }

  void _initEditData() {
    final e = widget.expense!;
    _titleCtrl.text = e.title;
    _amountCtrl.text = NumberFormat.decimalPattern('vi_VN').format(e.amount);
    _paidBy = e.paidBy;
    _date = e.date;
    _splitType = e.splitType;

    _splitDetail.clear();
    _selectedMembers.clear();

    for (final entry in e.splitDetail.entries) {
      final userRef = _userRef(entry.key);
      _selectedMembers.add(userRef);
      if (e.amount > 0) {
        _splitDetail[userRef] = ((entry.value / e.amount) * 100).round();
      }
    }

    _selectedCategory = fundCategories.firstWhere(
      (c) => c.id == e.iconId,
      orElse: () => fundCategories.first,
    );
    setState(() {});
  }

  DocumentReference _userRef(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _paidBy == null ||
        _selectedCategory == null) {
      SnackBarService.showError(context, "Vui lòng nhập đủ thông tin");
      return;
    }

    final amount = int.tryParse(_amountCtrl.text.replaceAll('.', ''));
    if (amount == null || amount <= 0) {
      SnackBarService.showError(context, "Số tiền không hợp lệ");
      return;
    }

    if (_selectedMembers.isEmpty) {
      SnackBarService.showError(context, "Phải chọn ít nhất 1 người tham gia");
      return;
    }

    Map<String, int> result = {};
    if (_splitType == 'equal') {
      final count = _selectedMembers.length;
      final per = amount ~/ count;
      int used = 0;
      final list = _selectedMembers.toList();
      for (int i = 0; i < count; i++) {
        final val = (i == count - 1) ? amount - used : per;
        used += val;
        result[list[i].id] = val;
      }
    } else {
      // Logic Tùy chỉnh (Tổng % phải = 100)
      final totalPercent = _selectedMembers.fold<int>(
        0,
        (sum, ref) => sum + (_splitDetail[ref] ?? 0),
      );
      if (totalPercent != 100) {
        SnackBarService.showError(
          context,
          "Tổng tỉ lệ phải bằng 100% (Hiện tại: $totalPercent%)",
        );
        return;
      }
      for (final ref in _selectedMembers) {
        result[ref.id] = (amount * (_splitDetail[ref] ?? 0) / 100).round();
      }
    }

    setState(() => _isSubmitting = true);
    try {
      if (widget.isEdit) {
        await _expenseService.updateExpense(
          fundId: widget.fundId,
          expense: widget.expense!,
          title: _titleCtrl.text.trim(),
          amount: amount,
          paidBy: _paidBy!,
          date: _date,
          iconId: _selectedCategory!.id,
          iconEmoji: _selectedCategory!.icon,
          splitType: _splitType,
          splitDetail: result,
        );
      } else {
        await _expenseService.createExpense(
          fundId: widget.fundId,
          title: _titleCtrl.text.trim(),
          amount: amount,
          paidBy: _paidBy!,
          date: _date,
          iconId: _selectedCategory!.id,
          iconEmoji: _selectedCategory!.icon,
          splitType: _splitType,
          splitDetail: result,
          shoppingItemId: widget.shoppingItemId,
          roomRef: widget.roomRef,
        );
      }
      if (mounted) {
        SnackBarService.showSuccess(context, "Thành công!");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) SnackBarService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Chỉnh sửa chi tiêu" : "Thêm chi tiêu"),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _loadingMembers
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBasicInfo(),
                  const SizedBox(height: 16),
                  _buildPaidBy(),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                  const SizedBox(height: 20),
                  Text(
                    "Chọn icon chi tiêu",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildCategory(),
                  const SizedBox(height: 20),
                  _buildSplitType(),
                  _buildSplitDetail(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CFE),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.isEdit ? "Lưu thay đổi" : "Thêm chi tiêu",
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        TextFormField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: "Số tiền (VNĐ)",
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: "0",
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            labelText: "Tiêu đề chi tiêu",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) => v!.isEmpty ? "Bắt buộc nhập tiêu đề" : null,
        ),
      ],
    );
  }

  Widget _buildPaidBy() {
    return DropdownButtonFormField<DocumentReference>(
      value: _paidBy,
      decoration: const InputDecoration(
        labelText: "Người thanh toán",
        border: OutlineInputBorder(),
      ),
      items: _members
          .map(
            (u) =>
                DropdownMenuItem(value: _userRef(u.uid), child: Text(u.name)),
          )
          .toList(),
      onChanged: (v) => setState(() => _paidBy = v),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: "Ngày thanh toán",
          border: OutlineInputBorder(),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(_date)),
      ),
    );
  }

  Widget _buildSplitType() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text("Chia đều"),
          selected: _splitType == 'equal',
          onSelected: (_) => setState(() => _splitType = 'equal'),
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text("Tùy chỉnh %"),
          selected: _splitType == 'custom',
          onSelected: (_) => setState(() => _splitType = 'custom'),
        ),
      ],
    );
  }

  Widget _buildSplitDetail() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: _members.map((u) {
          final ref = _userRef(u.uid);
          final isSelected = _selectedMembers.contains(ref);
          return ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selectedMembers.add(ref);
                } else if (_selectedMembers.length > 1) {
                  _selectedMembers.remove(ref);
                }
              }),
            ),
            title: Text(u.name),
            trailing: _splitType == 'custom' && isSelected
                ? SizedBox(
                    width: 70,
                    child: TextFormField(
                      key: ValueKey("custom_${u.uid}"),
                      initialValue: _splitDetail[ref]?.toString() ?? '0',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        suffixText: '%',
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          _splitDetail[ref] = int.tryParse(v) ?? 0,
                    ),
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategory() {
    return SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: fundCategories.length,
        itemBuilder: (_, i) {
          final c = fundCategories[i];
          final isSel = _selectedCategory?.id == c.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = c),
            child: Container(
              decoration: BoxDecoration(
                color: isSel ? Colors.indigo : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSel ? Colors.indigo : Colors.grey),
              ),
              child: Center(
                child: Text(c.icon, style: const TextStyle(fontSize: 26)),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }
}

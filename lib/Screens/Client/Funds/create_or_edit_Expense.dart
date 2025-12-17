import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/models/app_user.dart';
import 'package:house_pal/models/expense.dart';
import 'package:house_pal/services/expense_service.dart';
import 'package:house_pal/ultils/fund/fund_category.dart';

class CreateOrEditExpenseScreen extends StatefulWidget {
  final String fundId;
  final List<DocumentReference> memberRefs;
  final Expense? expense;

  const CreateOrEditExpenseScreen({
    super.key,
    required this.fundId,
    required this.memberRefs,
    this.expense,
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

  final Map<DocumentReference, TextEditingController> _splitCtrls = {};

  DocumentReference? _paidBy;
  DateTime _date = DateTime.now();

  FundCategory? _selectedCategory;

  /// equal | custom | percentage
  String _splitType = 'equal';

  /// % lưu cho custom + percentage
  final Map<DocumentReference, int> _splitDetail = {};
  final Set<DocumentReference> _customSelected = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  /// ================= INIT EDIT =================
  void _initEditData() {
    final e = widget.expense;
    if (e == null) return;

    _titleCtrl.text = e.title;
    _amountCtrl.text = e.amount.toString();
    _paidBy = e.paidBy;
    _date = e.date;
    _splitType = e.splitType;

    _splitDetail.clear();
    _customSelected.clear();

    for (final entry in e.splitDetail.entries) {
      final userId = entry.key;
      final vnd = entry.value;

      final member = _members.firstWhere(
        (m) => m.uid == userId,
        orElse: () => throw Exception("Member $userId not found"),
      );

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(member.uid);

      // 🔥 VND → %
      final percent = ((vnd / e.amount) * 100).round();

      _splitDetail[userRef] = percent;

      if (_splitType == 'custom') {
        _customSelected.add(userRef);
      }
    }

    _selectedCategory = fundCategories.firstWhere(
      (c) => c.id == e.iconId,
      orElse: () => fundCategories.first,
    );
  }

  /// ================= LOAD MEMBERS =================
  Future<void> _loadMembers() async {
    final snaps = await Future.wait(widget.memberRefs.map((e) => e.get()));
    final users = snaps.map(AppUser.fromFirestore).toList();

    setState(() {
      _members = users;
      _paidBy ??= FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);
      _loadingMembers = false;

      for (final u in users) {
        final ref = _userRef(u.uid);
        _splitCtrls[ref] = TextEditingController();
      }
    });

    _initEditData();
  }

  DocumentReference _userRef(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// ================= SUBMIT =================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _paidBy == null ||
        _selectedCategory == null) {
      _showError("Vui lòng nhập đủ thông tin");
      return;
    }

    final amount = int.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _showError("Số tiền không hợp lệ");
      return;
    }

    Map<String, int> result = {};

    /// ===== CHIA ĐỀU =====
    if (_splitType == 'equal') {
      final per = amount ~/ _members.length;
      int used = 0;

      for (int i = 0; i < _members.length; i++) {
        final uid = _members[i].uid;
        final value = (i == _members.length - 1) ? amount - used : per;

        used += value;
        result[uid] = value;
      }
    }
    /// ===== CHIA THEO % (BẮT BUỘC 100) =====
    else if (_splitType == 'percentage') {
      final total = _splitDetail.values.fold<int>(0, (a, b) => a + b);
      if (total != 100) {
        _showError("Tổng phần trăm phải bằng 100%");
        return;
      }

      for (final e in _splitDetail.entries) {
        result[e.key.id] = (amount * e.value / 100).round();
      }
    }
    /// ===== CUSTOM (KHÔNG BẮT BUỘC 100) =====
    else {
      for (final e in _splitDetail.entries) {
        result[e.key.id] = (amount * e.value / 100).round();
      }
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.isEdit) {
        await _expenseService.updateExpense(
          fundId: widget.fundId,
          expense: widget.expense!, // 🔥 FIX
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
        );
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Chỉnh sửa chi tiêu" : "Thêm chi tiêu"),
      ),
      body: _loadingMembers
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildBasicInfo(),
                    const SizedBox(height: 16),
                    _buildPaidBy(),
                    const SizedBox(height: 16),
                    _buildDatePicker(),
                    const SizedBox(height: 20),
                    _buildCategory(),
                    const SizedBox(height: 20),
                    _buildSplitType(),
                    if (_splitType != 'equal') _buildSplitDetail(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(
                        widget.isEdit ? "Lưu thay đổi" : "Thêm chi tiêu",
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// ================= UI =================

  Widget _buildBasicInfo() {
    return Column(
      children: [
        TextFormField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: "Tiêu đề chi tiêu",
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? "Bắt buộc" : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountCtrl,
          decoration: const InputDecoration(
            labelText: "Số tiền",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPaidBy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Người thanh toán"),
        const SizedBox(height: 6),
        DropdownButtonFormField<DocumentReference>(
          value: _paidBy,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: _members.map((u) {
            final ref = _userRef(u.uid);
            return DropdownMenuItem(value: ref, child: Text(u.name));
          }).toList(),
          onChanged: (v) => setState(() => _paidBy = v),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ngày thanh toán"),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _date = picked);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            child: Text("${_date.day}/${_date.month}/${_date.year}"),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Hình thức chia",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            _splitChip('equal', 'Chia đều', Icons.groups),
            _splitChip('custom', 'Tùy chỉnh %', Icons.person),
            _splitChip('percentage', 'Theo %', Icons.percent),
          ],
        ),
      ],
    );
  }

  Widget _splitChip(String value, String label, IconData icon) {
    return ChoiceChip(
      label: Text(label),
      selected: _splitType == value,
      onSelected: (_) {
        setState(() {
          _splitType = value;
          _splitDetail.clear();
          _customSelected.clear();
        });
      },
    );
  }

  Widget _buildSplitDetail() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: _members.map((u) {
          final ref = _userRef(u.uid);
          final enabled =
              _splitType == 'percentage' || _customSelected.contains(ref);

          final controller = TextEditingController(
            text: _splitDetail.containsKey(ref)
                ? _splitDetail[ref].toString()
                : '',
          );

          return ListTile(
            leading: _splitType == 'custom'
                ? Checkbox(
                    value: _customSelected.contains(ref),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _customSelected.add(ref);
                        } else {
                          _customSelected.remove(ref);
                          _splitDetail.remove(ref);
                        }
                      });
                    },
                  )
                : null,
            title: Text(u.name),
            trailing: SizedBox(
              width: 80,
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  suffixText: '%',
                  isDense: true,
                ),
                onChanged: (v) {
                  _splitDetail[ref] = int.tryParse(v) ?? 0;
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Biểu tượng chi tiêu",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: fundCategories.length,
            itemBuilder: (_, i) {
              final c = fundCategories[i];
              final selected = _selectedCategory?.id == c.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = c),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? Colors.indigo : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? Colors.indigo : Colors.grey,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.icon, style: const TextStyle(fontSize: 28)),
                      Text(
                        c.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    for (final c in _splitCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }
}

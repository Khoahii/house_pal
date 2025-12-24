import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:house_pal/models/app_user.dart';
import 'package:house_pal/models/expense.dart';
import 'package:house_pal/services/expense_service.dart';
import 'package:house_pal/ultils/fund/fund_category.dart';
import 'package:house_pal/ultils/fund/money_fomat.dart';
import 'package:intl/intl.dart';

class CreateOrEditExpenseScreen extends StatefulWidget {
  final String fundId;
  final List<DocumentReference> memberRefs;
  final Expense? expense;
  final bool? canModify;

  const CreateOrEditExpenseScreen({
    super.key,
    required this.fundId,
    required this.memberRefs,
    this.expense,
    this.canModify,
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
  final Set<DocumentReference> _selectedMembers = {};

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

    // 1. Gán các thông tin cơ bản
    _titleCtrl.text = e.title;

    // Định dạng số tiền có dấu chấm khi hiển thị (vi_VN: 100.000)
    final formatter = NumberFormat.decimalPattern('vi_VN');
    _amountCtrl.text = formatter.format(e.amount);

    _paidBy = e.paidBy;
    _date = e.date;
    _splitType = e.splitType;

    // 2. Làm sạch dữ liệu tạm trước khi map lại
    _splitDetail.clear();
    _selectedMembers.clear();

    // 3. Duyệt qua dữ liệu phân chia cũ trong DB
    for (final entry in e.splitDetail.entries) {
      final userId = entry.key;
      final amountVnd = entry.value;

      // Tìm member trong danh sách _members đã load từ fundId
      // Sử dụng try-catch hoặc findIndex để tránh crash nếu user đó đã bị xóa khỏi hệ thống hoàn toàn
      try {
        final member = _members.firstWhere((m) => m.uid == userId);

        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(member.uid);

        // Đánh dấu người này ĐÃ THAM GIA vào khoản chi này
        _selectedMembers.add(userRef);

        // Tính toán lại % (quan trọng cho chế độ 'percentage' và 'custom')
        if (e.amount > 0) {
          final percent = ((amountVnd / e.amount) * 100).round();
          _splitDetail[userRef] = percent;
        } else {
          _splitDetail[userRef] = 0;
        }
      } catch (e) {
        debugPrint(
          "Không tìm thấy thành viên $userId trong danh sách quỹ hiện tại.",
        );
        // Bỏ qua nếu người này không còn trong quỹ hoặc không tồn tại
      }
    }

    // 4. Khôi phục Icon/Category
    _selectedCategory = fundCategories.firstWhere(
      (c) => c.id == e.iconId,
      orElse: () => fundCategories.first,
    );

    // Cập nhật lại UI sau khi đã map xong data
    setState(() {});
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

      // Nếu là tạo mới: Mặc định chọn TẤT CẢ thành viên hiện tại
      if (!widget.isEdit) {
        for (final u in users) {
          _selectedMembers.add(_userRef(u.uid));
        }
      }

      _loadingMembers = false;
    });

    // Gọi Init Edit sau khi đã có danh sách members
    if (widget.isEdit) {
      _initEditData();
    }
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

    final rawAmount = _amountCtrl.text.replaceAll('.', '').trim();
    final amount = int.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      _showError("Số tiền không hợp lệ");
      return;
    }

    if (_selectedMembers.isEmpty) {
      _showError("Phải chọn ít nhất 1 người tham gia");
      return;
    }

    Map<String, int> result = {};

    /// ===== CHIA ĐỀU =====
    if (_splitType == 'equal') {
      final count = _selectedMembers.length;
      final per = amount ~/ count;
      int used = 0;

      // Chuyển Set sang List để lấy index
      final selectedList = _selectedMembers.toList();

      for (int i = 0; i < count; i++) {
        final ref = selectedList[i];
        final value = (i == count - 1) ? amount - used : per;
        used += value;
        result[ref.id] = value;
      }
    }
    /// ===== CHIA THEO % HOẶC CUSTOM =====
    else {
      // Logic kiểm tra 100% nếu là 'percentage'
      if (_splitType == 'percentage') {
        final total = _splitDetail.entries
            .where((e) => _selectedMembers.contains(e.key))
            .fold<int>(0, (a, b) => a + b.value);
        if (total != 100) {
          _showError("Tổng phần trăm phải bằng 100% (Hiện tại: $total%)");
          return;
        }
      }

      for (final ref in _selectedMembers) {
        final percent = _splitDetail[ref] ?? 0;
        result[ref.id] = (amount * percent / 100).round();
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
        title: Text(
          (widget.isEdit && widget.canModify == true)
              ? "Chỉnh sửa chi tiêu"
              : (widget.isEdit && widget.canModify == false)
              ? "Xem chi tiêu"
              : "Thêm chi tiêu",
        ),
        backgroundColor: const Color(0xFF2563EB), // Màu xanh Primary
        foregroundColor: Colors.white,
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
                    _buildSplitDetail(),
                    const SizedBox(height: 24),
                    (widget.canModify == true || widget.isEdit == false)
                        ? ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CFE),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.isEdit ? "Lưu thay đổi" : "Thêm chi tiêu",
                            ),
                          )
                        : Container(),
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
        // 1. Ô NHẬP TIỀN (Đã đưa lên trước và làm lớn hơn)
        TextFormField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center, // Căn giữa số tiền cho chuyên nghiệp
          style: const TextStyle(
            fontSize: 36, // Tăng kích thước lớn hơn nữa
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 52, 255, 126),
            letterSpacing: 1.2,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
          decoration: InputDecoration(
            labelText: "Số tiền (VNĐ)",
            floatingLabelBehavior: FloatingLabelBehavior
                .always, // Luôn hiển thị label nhỏ phía trên
            labelStyle: const TextStyle(fontSize: 18, color: Colors.grey),
            hintText: "0",
            suffixText: "", // Thêm đơn vị tiền tệ ở cuối
            suffixStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),

            // Loại bỏ Outline và chỉ dùng Underline
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromARGB(255, 52, 255, 126),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),

        const SizedBox(height: 20), // Khoảng cách rộng hơn
        // 2. Ô NHẬP TIÊU ĐỀ
        TextFormField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            labelText: "Tiêu đề chi tiêu",
            hintText: "Ví dụ: Ăn trưa, Đổ xăng...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) => v!.isEmpty ? "Bắt buộc nhập tiêu đề" : null,
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
        });
      },
    );
  }

  Widget _buildSplitDetail() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "Chọn người tham gia chia tiền:",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ..._members.map((u) {
            final ref = _userRef(u.uid);
            final isSelected = _selectedMembers.contains(ref);

            return ListTile(
              leading: Checkbox(
                value: isSelected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedMembers.add(ref);
                    } else {
                      // Không cho phép bỏ chọn hết sạch người
                      if (_selectedMembers.length > 1) {
                        _selectedMembers.remove(ref);
                        _splitDetail.remove(ref);
                      }
                    }
                  });
                },
              ),
              title: Text(u.name),
              trailing: (_splitType != 'equal')
                  ? SizedBox(
                      width: 80,
                      child: TextFormField(
                        // Sử dụng key để ép Flutter rebuild controller khi chuyển đổi thành viên
                        key: ValueKey("input_${u.uid}_$_splitType"),
                        initialValue: _splitDetail[ref]?.toString() ?? '',
                        enabled: isSelected,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          suffixText: '%',
                          isDense: true,
                        ),
                        onChanged: (v) {
                          _splitDetail[ref] = int.tryParse(v) ?? 0;
                        },
                      ),
                    )
                  : null, // Ở chế độ equal thì không hiện ô nhập %
            );
          }).toList(),
        ],
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
          height: 200,
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
                      Text(c.icon, style: const TextStyle(fontSize: 26)),
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

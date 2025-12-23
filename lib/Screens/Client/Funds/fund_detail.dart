import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Client/Funds/components/block_avatar.dart';
import 'package:house_pal/Screens/Client/Funds/create_or_edit_Expense.dart';
import 'package:house_pal/models/app_user.dart';
import 'package:house_pal/models/expense.dart';
import 'package:house_pal/models/fund.dart';
import 'package:house_pal/services/expense_service.dart';
import 'package:house_pal/services/user_service.dart';
import 'package:intl/intl.dart';

class FundDetailScreen extends StatefulWidget {
  final Fund fund;

  const FundDetailScreen({super.key, required this.fund});

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final UserService _userService = UserService();

  late Stream<Fund> _fundStream;
  late Stream<List<Expense>> _expensesStream;
  late Stream<AppUser?> _currentUserStream;

  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();

    _fundStream = _expenseService.getFundStream(widget.fund.id);
    _expensesStream = _expenseService.getFundExpenses(widget.fund.id);

    _currentUserStream = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .map((snap) => snap.exists ? AppUser.fromFirestore(snap) : null);
  }

  bool _canModifyExpense(AppUser currentUser, Expense expense) {
    final isAdmin = currentUser.role == 'admin';
    final isLeader = currentUser.role == 'room_leader';
    final isCreator = currentUser.uid == expense.createdBy;
    return isAdmin || isLeader || isCreator;
  }

  String _formatDateTime(DateTime date) {
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return isToday
        ? 'Hôm nay, ${DateFormat('HH:mm').format(date)}'
        : DateFormat('dd/MM/yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final String userId = widget.fund.creatorId.id;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Chi tiết quỹ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<AppUser?>(
        stream: _currentUserStream,
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = userSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeader(userId: userId),
                const SizedBox(height: 28),
                _buildTotalCard(),
                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Thành viên tham gia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildMembers(),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Danh sách chi tiêu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildExpenses(currentUser),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildAddExpenseButton(),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader({required String userId}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon Emoji với vòng tròn gradient nhẹ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4F46E5).withOpacity(0.1),
                  const Color(0xFF4F46E5).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Text(
              widget.fund.iconEmoji,
              style: const TextStyle(fontSize: 52),
            ),
          ),
          const SizedBox(height: 20),

          // Tên Quỹ
          Text(
            widget.fund.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937), // Màu xám đậm sang trọng
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Chip chứa thông tin thành viên và người tạo
          FutureBuilder<AppUser?>(
            future: _userService.getUserById(userId),
            builder: (context, snapshot) {
              String creatorName =
                  (snapshot.connectionState == ConnectionState.done)
                  ? (snapshot.data?.name ?? 'Không rõ')
                  : '...';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.fund.members.length} thành viên',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      'Tạo bởi: $creatorName',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= TOTAL CARD =================
  Widget _buildTotalCard() {
    return StreamBuilder<Fund>(
      stream: _fundStream,
      initialData: widget.fund,
      builder: (context, snapshot) {
        final fund = snapshot.data!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CFE), Color(0xFF6A1B9A)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng chi tiêu',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                currencyFormat.format(fund.totalSpent),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: () {},
                  label: const Text('Công nợ', style: TextStyle(fontSize: 18)),
                  icon: const Icon(Icons.monetization_on),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= MEMBERS =================
  Widget _buildMembers() {
    return Align(
      alignment: Alignment.centerLeft,
      child: FutureBuilder<List<AppUser>>(
        future: _getFundMembers(widget.fund.members),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator(strokeWidth: 2);
          }
          return AvatarStack(members: snapshot.data!);
        },
      ),
    );
  }

  // ================= EXPENSE LIST =================
  Widget _buildExpenses(AppUser currentUser) {
    return StreamBuilder<List<Expense>>(
      stream: _expensesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = snapshot.data!;
        if (expenses.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Chưa có chi tiêu nào',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: expenses.length,
          // Bỏ Divider vì chúng ta dùng khoảng trắng giữa các Card
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final exp = expenses[index];
            final canModify = _canModifyExpense(currentUser, exp);

            return FutureBuilder<AppUser?>(
              future: _userService.getUserById(exp.paidBy.id),
              builder: (context, userSnap) {
                final paidByName = userSnap.data?.name ?? 'Không rõ';

                return GestureDetector(
                  onTap: () => _openEditExpense(exp, canModify),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      // Hiệu ứng đổ bóng giúp Card trông nổi lên
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        // Vùng chứa Icon (Trái)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exp.iconEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Thông tin chi tiết (Giữa)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Người trả: $paidByName',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDateTime(exp.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Số tiền và Menu (Phải)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(height: 6),
                            // Số tiền
                            Text(
                              currencyFormat.format(exp.amount),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (canModify)
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(top: 8),
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _showExpenseActions(exp),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _openEditExpense(Expense expense, [bool canModify = false]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrEditExpenseScreen(
          fundId: widget.fund.id,
          memberRefs: widget.fund.members,
          expense: expense,
          canModify: canModify,
        ),
      ),
    );
  }

  void _showExpenseActions(Expense expense) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Chỉnh sửa chi tiêu"),
            onTap: () {
              Navigator.pop(context);
              _openEditExpense(expense, true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              "Xóa chi tiêu",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _expenseService.deleteExpense(
                fundId: widget.fund.id,
                expense: expense,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddExpenseButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateOrEditExpenseScreen(
                fundId: widget.fund.id,
                memberRefs: widget.fund.members,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CFE),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Thêm chi tiêu mới',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }

  Future<List<AppUser>> _getFundMembers(List<DocumentReference> refs) async {
    final snaps = await Future.wait(refs.map((e) => e.get()));
    return snaps.map(AppUser.fromFirestore).toList();
  }
}

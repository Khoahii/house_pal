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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            widget.fund.iconEmoji,
            style: const TextStyle(fontSize: 48),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.fund.name,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        FutureBuilder<AppUser?>(
          future: _userService.getUserById(userId),
          builder: (context, snapshot) {
            // Tên mặc định/placeholder
            String creatorName = '...';

            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                creatorName = 'Lỗi';
              } else if (snapshot.data != null) {
                // Giả sử AppUser có thuộc tính 'name'
                creatorName = snapshot.data!.name;
              } else {
                creatorName = 'Không rõ';
              }
            }

            return Text(
              '${widget.fund.members.length} thành viên • Tạo bởi $creatorName',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            );
          },
        ),
      ],
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
          return const CircularProgressIndicator();
        }

        final expenses = snapshot.data!;
        if (expenses.isEmpty) {
          return const Text('Chưa có chi tiêu nào');
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: expenses.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final exp = expenses[index];
            final canModify = _canModifyExpense(currentUser, exp);

            return FutureBuilder<AppUser?>(
              future: _userService.getUserById(exp.paidBy.id),
              builder: (context, userSnap) {
                final paidByName = userSnap.data?.name ?? 'Không rõ';

                return ListTile(
                  leading: Text(
                    exp.iconEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    exp.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Thanh toán: $paidByName',
                            style: const TextStyle(fontSize: 14),
                          ),
                          // const Icon(Icons.monetization_on_outlined, size: 16),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Số tiền: ',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            currencyFormat.format(exp.amount),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              //- in nghiêng
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDateTime(exp.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (canModify)
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showExpenseActions(exp),
                        ),
                    ],
                  ),
                  onTap: ()=> _openEditExpense(exp, canModify),
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

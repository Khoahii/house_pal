import 'package:cloud_firestore/cloud_firestore.dart';
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

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Lắng nghe thay đổi của tài liệu Fund (để cập nhật totalSpent)
    _fundStream = _expenseService.getFundStream(widget.fund.id);
    // Lắng nghe danh sách Expenses trong subcollection
    _expensesStream = _expenseService.getFundExpenses(widget.fund.id);
  }

  String _formatDateTime(DateTime date) {
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    if (isToday) {
      return 'Hôm nay, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = widget.fund.creatorId.id;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Chi tiết quỹ'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Icon + Tên quỹ + Người tạo
            Column(
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
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
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
            ),

            const SizedBox(height: 28),

            // Card số tiền đã chi + còn lại (Dùng StreamBuilder)
            StreamBuilder<Fund>(
              stream: _fundStream,
              initialData: widget.fund,
              builder: (context, snapshot) {
                final currentFund = snapshot.data ?? widget.fund;
                final totalSpent = currentFund.totalSpent;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CFE), Color(0xFF6A1B9A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Tổng chi tiêu',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              currencyFormat.format(totalSpent),
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      //- công nợ
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton.icon(
                          onPressed: () {},
                          label: const Text(
                            'Công nợ',
                            style: TextStyle(fontSize: 18),
                          ),
                          icon: const Icon(Icons.monetization_on),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Thành viên
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Thành viên quỹ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<List<AppUser>>(
                  future: _getFundMembers(widget.fund.members),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const SizedBox(
                        width: 100,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    final members = snapshot.data!;
                    // Sử dụng hàm build avatarstack có sẵn
                    return AvatarStack(members: members);
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Giao dịch gần đây
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Giao dịch gần đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Danh sách chi tiêu (Dùng StreamBuilder)
            // Danh sách chi tiêu (Dùng StreamBuilder)
            StreamBuilder<List<Expense>>(
              stream: _expensesStream,
              builder: (context, snapshot) {
                // Xử lý trạng thái đang tải
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Xử lý trạng thái lỗi
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi tải chi tiêu: ${snapshot.error}'),
                  );
                }

                final expenses = snapshot.data;

                // Xử lý trạng thái rỗng
                if (expenses == null || expenses.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: Text('Chưa có chi tiêu nào trong quỹ này.'),
                    ),
                  );
                }

                // Hiển thị danh sách chi tiêu
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    // Lấy ID người dùng (Nếu cần, bạn có thể phải tách ID từ path tại đây)
                    final String userId = exp.paidBy.id;

                    // Bọc widget hiển thị trong FutureBuilder để lấy tên người dùng
                    return FutureBuilder<AppUser?>(
                      // Gọi hàm bất đồng bộ để lấy thông tin người dùng
                      future: _userService.getUserById(userId),
                      builder: (context, userSnapshot) {
                        String paidByName;

                        // Xử lý các trạng thái của Future<AppUser?>
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          paidByName =
                              'Đang tải...'; // Tên placeholder khi đang tải
                        } else if (userSnapshot.hasError) {
                          paidByName = 'Lỗi tên'; // Xử lý lỗi
                        } else if (userSnapshot.data != null) {
                          // Lấy tên người dùng nếu có dữ liệu
                          paidByName = userSnapshot.data!.name;
                        } else {
                          paidByName = 'Người dùng không tồn tại';
                        }

                        // Widget chi tiêu
                        return GestureDetector(
                          onTap: () {
                            // Thêm logic chỉnh sửa chi tiêu tại đây nếu cần
                          },
                          child: Row(
                            children: [
                              // Icon chi tiêu
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  exp.iconEmoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Tên chi tiêu và thông tin người trả
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      // SỬ DỤNG TÊN ĐÃ TẢI XONG
                                      exp.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      // Hiển thị thời gian
                                      '${paidByName} trả ${_formatDateTime(exp.createdAt)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Số tiền chi tiêu
                              Text(
                                '-${currencyFormat.format(exp.amount)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }, // Kết thúc FutureBuilder builder
                    ); // Kết thúc FutureBuilder
                  },
                );
              },
            ),

            const SizedBox(height: 100), // Để nút bottom không che
          ],
        ),
      ),

      // Nút thêm chi tiêu
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
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
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
          ),
          child: const Text(
            'Thêm chi tiêu mới',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<List<AppUser>> _getFundMembers(List<DocumentReference> refs) async {
    final snapshots = await Future.wait(refs.map((ref) => ref.get()));
    return snapshots.map((snap) => AppUser.fromFirestore(snap)).toList();
  }
}

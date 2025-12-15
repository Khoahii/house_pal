import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Client/Funds/components/block_avatar.dart';
import 'package:house_pal/Screens/Client/Funds/create_or_edit_Expense.dart';
import 'package:house_pal/models/app_user.dart';
import 'package:house_pal/models/expense.dart';
import 'package:house_pal/models/fund.dart';
import 'package:intl/intl.dart';

class FundDetailScreen extends StatefulWidget {
  final Fund fund;

  const FundDetailScreen({super.key, required this.fund});

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen> {
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  // MOCK DATA - Các chi tiêu gần đây (subcollection expenses)
  final List<Expense> mockExpenses = [
    Expense(
      id: 'exp1',
      title: 'Vé máy bay khứ hồi',
      amount: 4500000,
      paidBy: FirebaseFirestore.instance.collection('users').doc('1'),
      date: DateTime.now().subtract(const Duration(days: 2)),
      iconId: 'flight',
      iconEmoji: '✈️',
      splitType: 'equal',
      splitDetail: {},
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    ),
    Expense(
      id: 'exp2',
      title: 'Khách sạn 3 đêm',
      amount: 2800000,
      paidBy: FirebaseFirestore.instance.collection('users').doc('2'),
      date: DateTime.now().subtract(const Duration(days: 1)),
      iconId: 'hotel',
      iconEmoji: '🏨',
      splitType: 'custom',
      splitDetail: {},
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
    ),
    Expense(
      id: 'exp3',
      title: 'Ăn tối nhà hàng',
      amount: 750000,
      paidBy: FirebaseFirestore.instance.collection('users').doc('3'),
      date: DateTime.now(),
      iconId: 'food',
      iconEmoji: '🍜',
      splitType: 'equal',
      splitDetail: {},
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays} ngày trước';
    if (diff.inHours >= 1) return '${diff.inHours} giờ trước';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
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
    final totalBudget = 10000000;
    final remaining = totalBudget - widget.fund.totalSpent;

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
                Text(
                  '5 thành viên • Tạo bởi Minh Tuấn',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Card số tiền đã chi + còn lại
            Container(
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
                  Text(
                    'Tổng chi tiêu',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          currencyFormat.format(remaining),
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

            // Danh sách chi tiêu
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockExpenses.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final exp = mockExpenses[index];
                // final payer = mockMembers.firstWhere(
                //   (m) => m.uid == exp.paidBy.id,
                //   orElse: () => mockMembers[0],
                // );

                return Row(
                  children: [
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDateTime(exp.createdAt)} ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-${currencyFormat.format(exp.amount)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
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

  Widget _buildAvatarStack(List<AppUser> members) {
    final display = members.take(4).toList();
    final extra = members.length - 4;

    return SizedBox(
      height: 50,
      child: Stack(
        children: [
          ...display.asMap().entries.map((e) {
            final index = e.key;
            final user = e.value;
            final name = user.name.isNotEmpty
                ? user.name.trim().split(' ').last
                : 'U';
            return Positioned(
              left: index * 32.0,
              child: CircleAvatar(
                radius: 22,
                backgroundColor:
                    Colors.primaries[index % Colors.primaries.length],
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
          if (extra > 0)
            Positioned(
              left: 4 * 32.0,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey[800],
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<List<AppUser>> _getFundMembers(List<DocumentReference> refs) async {
    final snapshots = await Future.wait(refs.map((ref) => ref.get()));
    return snapshots.map((snap) => AppUser.fromFirestore(snap)).toList();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/Screens/Client/Funds/components/loading_overlay.dart';
import 'package:house_pal/models/fund.dart';
import 'package:house_pal/services/fund_service.dart';
import 'package:house_pal/services/snack_bar_service.dart';
import 'package:intl/intl.dart';

class FundDebtScreen extends StatelessWidget {
  final Fund fund;
  const FundDebtScreen({super.key, required this.fund});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Nền xám nhạt hiện đại
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF2563EB), // Màu xanh Primary
        foregroundColor: Colors.white,
        title: Column(
          children: [
            const Text(
              'Công nợ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              fund.name,
              style: TextStyle(
                fontSize: 13,
                color: const Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fund_members')
            .where('fundId', isEqualTo: fund.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final members = snapshot.data!.docs;
          List<Map<String, dynamic>> settlements = _calculateSettlements(
            members,
          );

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              _buildSectionTitle("Trạng thái thành viên"),
              const SizedBox(height: 12),
              ...members.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildModernMemberCard(data, currencyFormat);
              }).toList(),

              const SizedBox(height: 32),
              _buildSectionTitle("Lộ trình quyết toán tối ưu"),
              const SizedBox(height: 12),
              if (settlements.isEmpty)
                _buildEmptyState()
              else
                // Thay đổi dòng map cũ:
                ...settlements
                    .map(
                      (item) =>
                          _buildSettlementStep(item, currencyFormat, context),
                    )
                    .toList(),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  // Thiết kế Item Thành viên mới: Đẹp và trực quan hơn
  Widget _buildModernMemberCard(Map<String, dynamic> data, NumberFormat fmt) {
    // Lấy dữ liệu từ Firestore
    int totalPaid = (data['totalPaid'] ?? 0).toInt();
    int totalOwed = (data['totalOwed'] ?? 0).toInt();
    int balance = (data['balance'] ?? 0).toInt();
    bool isNegative = balance < 0;
    String name = data['userName'] ?? 'Thành viên';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Bo góc lớn giống ảnh mẫu
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Thanh màu chỉ báo bên cạnh trái (Xanh nếu dư, Đỏ nếu nợ)
              Container(
                width: 6,
                color: isNegative ? Colors.redAccent : Colors.greenAccent[400],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Phần thông tin phía trên (Avatar, Tên, Trạng thái, Balance)
                      Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: data['userAvatar'] != null
                                    ? NetworkImage(data['userAvatar'])
                                    : null,
                                child: data['userAvatar'] == null
                                    ? const Icon(Icons.person, size: 30)
                                    : null,
                              ),
                              if (isNegative)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.error,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${isNegative ? '-' : '+'} ${fmt.format(balance.abs())}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isNegative
                                  ? Colors.redAccent
                                  : Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Phần thông tin chi tiết phía dưới (Nền xám nhạt)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA), // Màu nền xám nhạt
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              "$name đã chi:",
                              fmt.format(totalPaid),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              "Phần $name phải trả:",
                              fmt.format(totalOwed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  // Widget hiển thị bước thanh toán (A -> B)
  Widget _buildSettlementStep(
    Map<String, dynamic> item,
    NumberFormat fmt,
    BuildContext context,
  ) {
    // Lấy ID người dùng hiện tại
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    // Chỉ người nhận mới thấy nút xác nhận
    bool isRecipient = item['toId'] == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _nameTag(item['from'], isDebtor: true)),
              Column(
                children: [
                  Text(
                    fmt.format(item['amount']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.blueAccent,
                    size: 16,
                  ),
                ],
              ),
              Expanded(child: _nameTag(item['to'], isDebtor: false)),
            ],
          ),
          if (isRecipient) ...[
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmSettlement(context, item),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text("Xác nhận đã nhận tiền"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmSettlement(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận thanh toán"),
        content: Text(
          "Bạn xác nhận đã nhận đủ tiền từ ${item['from']}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Đóng Dialog xác nhận trước

              // 1. Hiển thị màn hình Loading chờ đợi
              LoadingOverlay.show(context, message: "Đang cập nhật công nợ...");

              try {
                // 2. Thực hiện tính toán trên Firebase
                final service = FundService();
                await service.settleDebt(
                  fundId: fund.id,
                  fromUserId: item['fromId'],
                  toUserId: item['toId'],
                  amount: item['amount'],
                );

                // 3. Xử lý xong thì ẩn Loading
                if (context.mounted) LoadingOverlay.hide(context);

                if (context.mounted) {
                  SnackBarService.showSuccess(
                    context,
                    "Quyết toán thành công!",
                  );
                }
              } catch (e) {
                // Ẩn loading nếu có lỗi
                if (context.mounted) LoadingOverlay.hide(context);

                if (context.mounted) {
                  SnackBarService.showError(context, "Lỗi: ${e.toString()}");
                }
              }
            },
            child: const Text(
              "Xác nhận",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameTag(String name, {required bool isDebtor}) {
    return Text(
      name,
      textAlign: isDebtor ? TextAlign.left : TextAlign.right,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Color(0xFF334155),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.check_circle_outline, size: 48, color: Colors.green[200]),
          const SizedBox(height: 8),
          const Text(
            "Mọi người đã thanh toán hết nợ!",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Thuật toán Greedy Debt Settlement (Giữ nguyên logic chính xác của bạn)
  List<Map<String, dynamic>> _calculateSettlements(
    List<QueryDocumentSnapshot> docs,
  ) {
    List<Map<String, dynamic>> netBalances = [];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      netBalances.add({
        'id': data['userId'], // Quan trọng: lấy ID để biết ai là người nhận
        'name': data['userName'],
        'balance': (data['balance'] ?? 0).toInt(),
      });
    }

    List<Map<String, dynamic>> creditors = netBalances
        .where((e) => e['balance'] > 0)
        .toList();
    List<Map<String, dynamic>> debtors = netBalances
        .where((e) => e['balance'] < 0)
        .toList();

    creditors.sort((a, b) => b['balance'].compareTo(a['balance']));
    debtors.sort((a, b) => a['balance'].compareTo(b['balance']));

    List<Map<String, dynamic>> result = [];
    int i = 0, j = 0;

    while (i < debtors.length && j < creditors.length) {
      int pay = debtors[i]['balance'].abs();
      int receive = creditors[j]['balance'];
      int settled = pay < receive ? pay : receive;

      if (settled > 0) {
        result.add({
          'from': debtors[i]['name'],
          'fromId': debtors[i]['id'], // Lưu ID người nợ
          'to': creditors[j]['name'],
          'toId': creditors[j]['id'], // Lưu ID người nhận
          'amount': settled,
        });
      }

      debtors[i]['balance'] += settled;
      creditors[j]['balance'] -= settled;
      if (debtors[i]['balance'] == 0) i++;
      if (creditors[j]['balance'] == 0) j++;
    }
    return result;
  }
}

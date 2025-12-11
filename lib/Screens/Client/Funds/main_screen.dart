import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Client/Funds/create_fund_bottom_sheet.dart';
import 'package:intl/intl.dart';

class MainFundScreen extends StatelessWidget {
  MainFundScreen({super.key});

  // ========== MOCK DATA==========
  final currentUserId = "user_minhtc"; // giả sử user đang đăng nhập
  final bool isAdmin = false; // đổi thành true để test quyền admin
  final bool isRoomLeader = true; // đổi thành true/false để test

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  final List<FundMock> mockFunds = [
    FundMock(
      fundId: "fund_001",
      name: "Du lịch Đà Lạt",
      icon: "plane", // FontAwesome: 
      status: FundStatus.open,
      lastUpdated: "Cập nhật 2 giờ trước",
      memberCount: 5, // 3 ảnh + +2
      totalSpent: 12500000,
      creatorId: "user_minhtc", // Minh tạo → có quyền xóa
    ),
    FundMock(
      fundId: "fund_002",
      name: "Ăn trưa Công ty",
      icon: "utensils", // 
      status: FundStatus.open,
      lastUpdated: "Cập nhật hôm qua",
      memberCount: 8,
      totalSpent: 2150000,
      creatorId:
          "user_anhboss", // không phải Minh tạo → không xóa được nếu không phải admin/leader
    ),
    FundMock(
      fundId: "fund_003",
      name: "Tiền nhà trọ T8",
      icon: "home", // 
      status: FundStatus.closed,
      lastUpdated: "Đã quyết toán",
      memberCount: 4,
      totalSpent: 8000000,
      creatorId: "user_minhtc",
    ),
  ];

  // Tổng hợp để hiển thị card tím
  int get totalBalance => 4250000;
  int get totalToCollect => 5100000;
  int get totalToPay => 850000;

  bool canDeleteFund(String creatorId) {
    return isAdmin || isRoomLeader || creatorId == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Quỹ Nhóm"),
        centerTitle: false,
        actions: [
          CircleAvatar(
            backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=1"),
          ),
          const SizedBox(width: 16),
          Container(
            child: const Text(
              "Xin chào, Minh!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== CARD TỔNG SỐ DƯ ======
            _buildSummaryCard(),

            const SizedBox(height: 32),

            // ====== TIÊU ĐỀ + SỐ LƯỢNG QUỸ ======
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Quỹ đang hoạt động",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "${mockFunds.length} quỹ",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ====== DANH SÁCH QUỸ ======
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockFunds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final fund = mockFunds[index];
                return _buildFundCard(fund);
              },
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4F46E5),
        onPressed: () => _showCreateFundBottomSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateFundBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateFundBottomSheet(),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.25, -0.25),
          end: Alignment(0.75, 1.25),
          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tổng số dư tất cả quỹ",
                style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(totalBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem(
                      icon: Icons.arrow_upward,
                      color: const Color(0xFF86EFAC),
                      label: "Cần thu",
                      amount: totalToCollect,
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    _summaryItem(
                      icon: Icons.arrow_downward,
                      color: const Color(0xFFFCA5A5),
                      label: "Cần trả",
                      amount: totalToPay,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Hiệu ứng bong bóng trang trí
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required Color color,
    required String label,
    required int amount,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 12),
            ),
            Text(
              currencyFormat.format(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFundCard(FundMock fund) {
    final bool canDelete = canDeleteFund(fund.creatorId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: fund.status == FundStatus.closed
            ? Colors.white.withOpacity(0.7)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getIconBackground(fund.icon),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconData(fund.icon),
                      color: _getIconColor(fund.icon),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fund.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        fund.lastUpdated,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: fund.status == FundStatus.open
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      fund.status == FundStatus.open ? "Đang mở" : "Đóng",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: fund.status == FundStatus.open
                            ? const Color(0xFF15803D)
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  if (canDelete) ...[
                    const SizedBox(width: 8),
                    // ✅ FIX: Wrap trong Builder để có context
                    Builder(
                      builder: (context) => PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteDialog(context, fund);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  "Xóa quỹ",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMemberAvatars(fund.memberCount),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Tổng chi tiêu",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    currencyFormat.format(fund.totalSpent),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAvatars(int count) {
    final displayed = count > 3 ? 3 : count;
    return SizedBox(
      width: 110,
      height: 36,
      child: Stack(
        children:
            List.generate(displayed, (i) {
              return Positioned(
                left: i * 24,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: DecorationImage(
                      image: NetworkImage(
                        "https://i.pravatar.cc/150?img=${i + 10}",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            })..addIf(
              count > 3,
              Positioned(
                left: 72,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      "+${count - 3}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, FundMock fund) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa quỹ"),
        content: Text(
          "Bạn có chắc muốn xóa quỹ “${fund.name}” không? Hành động này không thể hoàn tác.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              // TODO: gọi hàm xóa trên Firestore
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Đã xóa quỹ")));
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getIconBackground(String icon) {
    switch (icon) {
      case "plane":
        return const Color(0xFFDBEAFE);
      case "utensils":
        return const Color(0xFFFFEDD5);
      case "home":
        return const Color(0xFFF3E8FF);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getIconColor(String icon) {
    switch (icon) {
      case "plane":
        return const Color(0xFF2563EB);
      case "utensils":
        return const Color(0xFFEA580C);
      case "home":
        return const Color(0xFF9333EA);
      default:
        return Colors.grey;
    }
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case "plane":
        return Icons.flight;
      case "utensils":
        return Icons.restaurant;
      case "home":
        return Icons.home;
      default:
        return Icons.category;
    }
  }
}

// ========== MODEL & ENUM ==========
enum FundStatus { open, closed }

class FundMock {
  final String fundId;
  final String name;
  final String icon;
  final FundStatus status;
  final String lastUpdated;
  final int memberCount;
  final int totalSpent;
  final String creatorId;

  FundMock({
    required this.fundId,
    required this.name,
    required this.icon,
    required this.status,
    required this.lastUpdated,
    required this.memberCount,
    required this.totalSpent,
    required this.creatorId,
  });
}

// Extension để dễ thêm điều kiện trong list
extension ListX<T> on List<Widget> {
  void addIf(bool condition, Widget widget) {
    if (condition) add(widget);
  }
}

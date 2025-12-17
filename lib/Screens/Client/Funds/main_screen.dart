import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Client/Funds/components/block_avatar.dart';
import 'package:house_pal/Screens/Client/Funds/fund_detail.dart';
import 'package:house_pal/models/app_user.dart';
import 'package:house_pal/models/fund.dart';
import 'package:house_pal/services/fund_service.dart';
import 'package:intl/intl.dart';
import 'create_or_edit_fund_bottom_sheet.dart';

class MainFundScreen extends StatefulWidget {
  const MainFundScreen({super.key});

  @override
  State<MainFundScreen> createState() => _MainFundScreenState();
}

class _MainFundScreenState extends State<MainFundScreen> {
  final FundService _fundService = FundService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  late Stream<List<Fund>> _fundsStream;
  late Stream<Map<String, int>> _summaryStream;
  late Stream<AppUser?> _currentUserStream;

  @override
  void initState() {
    super.initState();
    _fundsStream = _fundService.getMyFundsStream();
    _summaryStream = _fundService.getFundSummaryStream();
    _currentUserStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snap) => snap.exists ? AppUser.fromFirestore(snap) : null);
  }

  void _showCreateFundSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateOrEditFundBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Quỹ Nhóm",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),

      // BỌC StreamBuilder CỦA DANH SÁCH QUỸ BÊN TRONG StreamBuilder CỦA USER
      body: StreamBuilder<AppUser?>(
        stream: _currentUserStream,
        builder: (context, userSnapshot) {
          // Xử lý trạng thái tải người dùng đầu tiên
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final currentUser = userSnapshot.data;

          // Tiếp tục xây dựng body chính bằng StreamBuilder của Funds
          return StreamBuilder<List<Fund>>(
            stream: _fundsStream,
            builder: (context, fundSnapshot) {
              if (fundSnapshot.hasError) {
                return Center(child: Text("Lỗi: ${fundSnapshot.error}"));
              }

              if (!fundSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final funds = fundSnapshot.data!;
              // 1. TÍNH TOÁN TỔNG CHI TIÊU TOÀN BỘ QUỸ
              final totalSpen = funds.isEmpty
                  ? 0
                  : funds.map((f) => f.totalSpent).reduce((a, b) => a + b);


              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CARD TỔNG DƯ (Tổng Chi Tiêu, Cần Thu, Cần Trả)
                    StreamBuilder<Map<String, int>>(
                      stream: _summaryStream,
                      builder: (context, summarySnapshot) {
                        int totalToCollect = 0;
                        int totalToPay = 0;

                        // Lấy dữ liệu Cần Thu và Cần Trả từ Stream
                        if (summarySnapshot.hasData) {
                          final data = summarySnapshot.data!;

                          // Lấy Tổng Cần Thu (Tổng balance dương)
                          totalToCollect = data['totalToCollect'] ?? 0;

                          // Lấy Tổng Cần Trả (Tổng balance âm đã chuyển sang dương)
                          totalToPay = data['totalToPay'] ?? 0;
                        }

                        // HIỂN THỊ CARD VỚI 3 GIÁ TRỊ:
                        return _buildSummaryCard(
                          // Tham số 1: Tổng Chi Tiêu Toàn Quỹ
                          totalSpen,

                          // Tham số 2: Tổng Cần Thu cá nhân (từ FundService đã tính)
                          totalToCollect,

                          // Tham số 3: Tổng Cần Trả cá nhân (từ FundService đã tính)
                          totalToPay,
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Quỹ đang hoạt động",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${funds.length} quỹ",
                          style: const TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Danh sách Quỹ
                    funds.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: funds.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final fund = funds[index];
                              return _buildFundCard(fund, currentUser);
                            },
                          ),
                  ],
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4F46E5),
        onPressed: _showCreateFundSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard(int totalSpen, int toCollect, int toPay) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tổng tiền tất cả quỹ",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(totalSpen),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _summaryItem("Cần thu", toCollect, Colors.green)),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(child: _summaryItem("Cần trả", toPay, Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, int amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFundCard(Fund fund, AppUser? currentUser) {
    // 1. Kiểm tra vai trò (Role-based check)
    final isAdmin = currentUser?.role == "admin";
    final isLeader = currentUser?.role == "room_leader";

    // 2. Kiểm tra Người tạo (Creator check)
    // So sánh ID người dùng hiện tại với ID người tạo quỹ.
    // Lưu ý: fund.creatorId là DocumentReference, cần lấy .id để so sánh với String ID.
    final isCreator = currentUser?.uid == fund.creatorId.id;

    // 3. Logic Xóa (Delete permission)
    // Có thể xóa nếu là Admin, Room Leader, HOẶC Người tạo
    final canDelete = isAdmin || isLeader || isCreator;

    return Dismissible(
      key: Key(fund.id),
      // Điều hướng Dismissible chỉ được kích hoạt nếu canDelete là true
      direction: canDelete
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _fundService.deleteFund(fund.id, fund.creatorId.id),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FundDetailScreen(fund: fund),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          fund.iconEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fund.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Cập nhật gần đây",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // —— CHỈ ADMIN, LEADER, CREATOR MỚI THẤY MORE VERTICAL ——
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Đang mở",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Chỉ hiển thị IconButton nếu có quyền xóa
                      if (canDelete) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onPressed: () => _showFundActions(fund),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // avatar + totalSpent
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<List<AppUser>>(
                    future: _getFundMembers(fund.members),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Tổng chi tiêu",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
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
        ),
      ),
    );
  }

  Future<List<AppUser>> _getFundMembers(List<DocumentReference> refs) async {
    final snapshots = await Future.wait(refs.map((ref) => ref.get()));
    return snapshots.map((snap) => AppUser.fromFirestore(snap)).toList();
  }

  void _showDeleteDialog(Fund fund) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa quỹ"),
        content: Text("Xóa vĩnh viễn “${fund.name}”? Không thể khôi phục!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              _fundService.deleteFund(fund.id, fund.creatorId.id);
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openEditFundSheet(Fund fund) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateOrEditFundBottomSheet(fund: fund),
    );
  }


  void _showFundActions(Fund fund) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Chỉnh sửa quỹ"),
            onTap: () {
              Navigator.pop(context);
              _openEditFundSheet(fund);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Xóa quỹ", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteDialog(fund);
            },
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.wallet, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "Chưa có quỹ nào",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            "Bấm nút + để tạo quỹ đầu tiên",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

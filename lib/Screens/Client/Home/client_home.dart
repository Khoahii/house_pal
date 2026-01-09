import 'package:flutter/material.dart';
import 'package:house_pal/models/user/app_user.dart';
import 'package:house_pal/models/task/leaderboard_score.dart';
import 'package:house_pal/models/task/task_model.dart';
import 'package:house_pal/providers/auth_provider.dart';
import 'package:house_pal/services/task/completion_service.dart';
import 'package:house_pal/services/fund/fund_service.dart';
import 'package:house_pal/services/task/leaderboard_service.dart';
import 'package:house_pal/services/task/task_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ClientHome extends StatelessWidget {
  final VoidCallback onViewAllTasks;
  const ClientHome({super.key, required this.onViewAllTasks});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);
    final user = authProvider.currentUser;
    final roomId = user?.roomId?.id ?? '';

    // Khởi tạo các service
    final taskService = TaskService();
    final leaderboardService = LeaderboardService();
    final fundService = FundService();
    final completionService = CompletionService();

    if (user == null || roomId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_filled), // Thay bằng path logo của bạn
            const SizedBox(width: 8),
            const Text(
              'HousePal',
              style: TextStyle(
                color: Color(0xFF6A4CBC),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Text(
            'Trợ lý Ngôi nhà Chung',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => authProvider.refreshUser(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Welcome Card
              _buildWelcomeCard(
                user,
                5,
                3,
              ), // 5 thành viên, 3 việc (Hardcode ví dụ)

              const SizedBox(height: 16),

              // 2. Row: Điểm của bạn & Số dư
              Row(
                children: [
                  Expanded(
                    child:
                        StreamBuilder<({LeaderboardScore? score, int? rank})?>(
                          stream: leaderboardService.getCurrentUserScore(
                            roomId,
                            user.uid,
                          ),
                          builder: (context, snapshot) {
                            final data = snapshot.data;
                            return _buildStatusCard(
                              icon: Icons.emoji_events_outlined,
                              iconColor: Colors.green,
                              title: 'Điểm của bạn',
                              value: '${data?.score?.score ?? 0} điểm',
                              subValue: 'Hạng #${data?.rank ?? '-'} tháng này',
                              bgColor: const Color(0xFFE8F5E9),
                            );
                          },
                        ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<Map<String, int>>(
                      stream: fundService.getFundSummaryStream(),
                      builder: (context, snapshot) {
                        final totalBalance =
                            snapshot.data?['totalBalance'] ?? 0;
                        final formattedBalance = NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: 'đ',
                        ).format(totalBalance);
                        return _buildStatusCard(
                          icon: Icons.attach_money,
                          iconColor: Colors.red,
                          title: 'Số dư của bạn',
                          value: formattedBalance,
                          subValue: totalBalance < 0
                              ? 'Bạn đang nợ'
                              : 'Bạn đang dư',
                          bgColor: const Color(0xFFFFEBEE),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 3. Section: Việc nhà hôm nay
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Việc nhà hôm nay',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed:
                        onViewAllTasks, // Gọi hàm callback thay vì Navigator.push
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              StreamBuilder<List<Task>>(
                stream: taskService.getTasks(roomId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final tasks = snapshot.data!
                      .take(2)
                      .toList(); // Lấy 2 task đầu
                  return Column(
                    children: tasks
                        .map(
                          (task) => _buildTaskItem(
                            context,
                            task,
                            user.uid,
                            () => completionService.completeTask(
                              roomId: roomId,
                              task: task,
                              currentUser: user,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 4. Nhắc nhở thanh toán (Vùng màu cam)
              // _buildPaymentReminder('Chi', 50000, 'tiền điện tháng 11'),

              const SizedBox(height: 24),

              // 5. Section: Top Contributors
              const Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Top Contributors',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text('Tháng 11/2025', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<LeaderboardScore>>(
                stream: leaderboardService.getTop3(roomId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return Column(
                    children: snapshot.data!
                        .map((score) => _buildContributorItem(score))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Components ---

  Widget _buildWelcomeCard(AppUser user, int members, int tasks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E44AD), Color(0xFFEF4DB6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(user.name?[0] ?? '')
                : null,
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xin chào,',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$members thành viên • $tasks việc đang chờ',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subValue,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            subValue,
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    Task task,
    String currentUserId,
    VoidCallback onComplete,
  ) {
    bool isMyTurn = false;
    if (task.assignMode == 'manual') {
      isMyTurn = task.manualAssignedTo?.id == currentUserId;
    } else {
      // Logic auto rotation từ service của bạn
      final currentAssigneeRef = task.rotationOrder?[task.rotationIndex ?? 0];
      isMyTurn = currentAssigneeRef?.id == currentUserId;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Color(0xFF6A4CBC),
            ), // Thay đổi icon tùy task.title
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isMyTurn
                      ? 'Đến lượt bạn • +${task.point} điểm'
                      : 'Đến lượt người khác',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isMyTurn ? onComplete : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isMyTurn
                  ? const Color(0xFFF3E5F5)
                  : Colors.grey[200],
              foregroundColor: isMyTurn ? const Color(0xFF6A4CBC) : Colors.grey,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(isMyTurn ? 'Làm ngay' : 'Chờ'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentReminder(String targetName, int amount, String note) {
    final formatted = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    ).format(amount);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Nhắc nhở thanh toán',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Bạn nợ $targetName $formatted ($note)'),
          const SizedBox(height: 4),
          const Text(
            'Xem chi tiết →',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorItem(LeaderboardScore score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: score.userAvatar != null
                ? NetworkImage(score.userAvatar!)
                : null,
            child: score.userAvatar == null
                ? Text(score.userName?[0] ?? '')
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            score.userName ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            '${score.score} điểm',
            style: const TextStyle(
              color: Color(0xFF6A4CBC),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

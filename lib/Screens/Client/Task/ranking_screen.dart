import 'package:flutter/material.dart';
import '../../../models/leaderboard_score.dart';
import '../../../services/leaderboard_service.dart';
import '../../../services/auth_service.dart';

class RankingScreen extends StatefulWidget {
  final String roomId; // Room ID để query leaderboard

  const RankingScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final Color primaryColor = const Color(0xFF5B5CE2);
  final LeaderboardService _leaderboardService = LeaderboardService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bảng Xếp Hạng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: StreamBuilder<List<LeaderboardScore>>(
        // Stream toàn bộ leaderboard tháng hiện tại (đã sort theo score DESC)
        stream: _leaderboardService.getMonthlyScores(widget.roomId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          }

          final allScores = snapshot.data ?? [];
          final top3 = allScores.take(3).toList();

          // Tìm user hiện tại trong danh sách
          LeaderboardScore? currentUserScore;
          int? currentUserRank;
          
          if (currentUserId != null) {
            final userIndex = allScores.indexWhere((s) => s.userId == currentUserId);
            if (userIndex != -1) {
              currentUserScore = allScores[userIndex];
              currentUserRank = userIndex + 1; // Rank = index + 1
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _topThreeCard(top3, currentUserScore, currentUserRank),
                const SizedBox(height: 16),
                _fullRankingList(allScores),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= TOP 3 =================
  Widget _topThreeCard(
    List<LeaderboardScore> top3,
    LeaderboardScore? currentUserScore,
    int? currentUserRank,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Top 3 Xuất Sắc',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hiển thị top 3 theo thứ tự: 2nd, 1st, 3rd
          if (top3.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Chưa có dữ liệu xếp hạng tháng này',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Rank 2 (trái)
                if (top3.length >= 2)
                  _topItem(
                    name: top3[1].userName ?? 'User',
                    score: top3[1].score,
                    rank: 2,
                    image: top3[1].userAvatar ?? 'https://i.pravatar.cc/150?img=2',
                    color: Colors.grey,
                  )
                else
                  const SizedBox(width: 80),
                
                // Rank 1 (giữa, cao hơn)
                if (top3.isNotEmpty)
                  _topItem(
                    name: top3[0].userName ?? 'User',
                    score: top3[0].score,
                    rank: 1,
                    image: top3[0].userAvatar ?? 'https://i.pravatar.cc/150?img=1',
                    color: Colors.amber,
                    isCenter: true,
                  ),
                
                // Rank 3 (phải)
                if (top3.length >= 3)
                  _topItem(
                    name: top3[2].userName ?? 'User',
                    score: top3[2].score,
                    rank: 3,
                    image: top3[2].userAvatar ?? 'https://i.pravatar.cc/150?img=3',
                    color: Colors.orange,
                  )
                else
                  const SizedBox(width: 80),
              ],
            ),
          const SizedBox(height: 16),
          // Highlight user hiện tại nếu có
          if (currentUserScore != null && currentUserRank != null)
            _highlightUser(currentUserScore, currentUserRank),
        ],
      ),
    );
  }

  Widget _topItem({
    required String name,
    required int score,
    required int rank,
    required String image,
    required Color color,
    bool isCenter = false,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
              child: CircleAvatar(
                backgroundImage: NetworkImage(image),
                onBackgroundImageError: (_, __) {},
                backgroundColor: Colors.grey[300],
              ),
            ),
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score điểm',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ================= HIGHLIGHT USER HIỆN TẠI =================
  Widget _highlightUser(LeaderboardScore userScore, int rank) {
    // Xác định badge dựa trên rank
    String badgeText;
    Color badgeColor;
    
    if (rank == 1) {
      badgeText = 'Xuất sắc nhất 🏆';
      badgeColor = Colors.amber;
    } else if (rank <= 3) {
      badgeText = 'Top $rank';
      badgeColor = Colors.orange;
    } else if (rank <= 10) {
      badgeText = 'Hạng $rank';
      badgeColor = Colors.blue;
    } else {
      badgeText = 'Hạng $rank';
      badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: userScore.userAvatar != null
                ? NetworkImage(userScore.userAvatar!)
                : const NetworkImage('https://i.pravatar.cc/150?img=0'),
            onBackgroundImageError: (_, __) {},
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userScore.userName ?? 'Bạn',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${userScore.score}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ================= DANH SÁCH XẾP HẠNG ĐẦY ĐỦ =================
  Widget _fullRankingList(List<LeaderboardScore> allScores) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Bảng Xếp Hạng Đầy Đủ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (allScores.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Chưa có dữ liệu',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...allScores.asMap().entries.map((entry) {
              final index = entry.key;
              final score = entry.value;
              final rank = index + 1;
              
              // Xác định màu theo rank
              Color rankColor;
              if (rank == 1) {
                rankColor = Colors.amber;
              } else if (rank == 2) {
                rankColor = Colors.grey;
              } else if (rank == 3) {
                rankColor = Colors.orange;
              } else {
                rankColor = primaryColor;
              }
              
              return _rankItem(
                rank,
                score.userName ?? 'User',
                score.score,
                rankColor,
                score.userAvatar,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _rankItem(int rank, String name, int score, Color color, String? avatarUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl)
                : const NetworkImage('https://i.pravatar.cc/150?img=0'),
            onBackgroundImageError: (_, __) {},
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

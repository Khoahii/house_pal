import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  final Color primaryColor = const Color(0xFF5B5CE2);

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _topThreeCard(),
            const SizedBox(height: 16),
            _rankingList(),
          ],
        ),
      ),
    );
  }

  

  // ================= TOP 3 =================
  Widget _topThreeCard() {
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
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _topItem(
                name: 'Hương',
                score: 72,
                rank: 2,
                image: 'https://i.pravatar.cc/150?img=5',
                color: Colors.grey,
              ),
              _topItem(
                name: 'Minh',
                score: 85,
                rank: 1,
                image: 'https://i.pravatar.cc/150?img=3',
                color: Colors.amber,
                isCenter: true,
              ),
              _topItem(
                name: 'Tuấn',
                score: 68,
                rank: 3,
                image: 'https://i.pravatar.cc/150?img=8',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _highlightUser(),
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
          alignment: Alignment.topRight,
          children: [
            CircleAvatar(
              radius: isCenter ? 40 : 30,
              backgroundImage: NetworkImage(image),
            ),
            if (rank == 1)
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.orange,
                child: Icon(Icons.emoji_events, size: 14, color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$score điểm', style: TextStyle(color: color)),
      ],
    );
  }

  // ================= USER ĐANG XEM =================
  Widget _highlightUser() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/150?img=3',
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Minh\nXuất sắc nhất',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(
            '85',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ================= DANH SÁCH XẾP HẠNG =================
  Widget _rankingList() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Bảng Xếp Hạng Đầy Đủ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _rankItem(1, 'Minh', 85, Colors.amber),
          _rankItem(2, 'Hương', 72, Colors.grey),
          _rankItem(3, 'Tuấn', 68, Colors.orange),
        ],
      ),
    );
  }

  Widget _rankItem(int rank, String name, int score, Color color) {
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
              ),
            ),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/150?img=3',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
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

import 'package:flutter/material.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  final Color primaryColor = const Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lau nhà toàn bộ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _assigneeCard(),
                  const SizedBox(height: 16),
                  _descriptionCard(),
                  const SizedBox(height: 16),
                  _detailInfoCard(),
                ],
              ),
            ),
          ),
          _bottomButton(),
        ],
      ),
    );
  }

  // ================= PHÂN CÔNG =================
  Widget _assigneeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/150?img=3',
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phân công cho',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Minh Anh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'Điểm thưởng',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Row(
                children: [
                  Text(
                    '10',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.star, color: Colors.orange, size: 16),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= MÔ TẢ CÔNG VIỆC =================
  Widget _descriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.description, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Mô tả công việc',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Lau sạch sàn nhà ở tất cả các phòng bao gồm phòng khách, phòng ngủ, bếp và hành lang. '
            'Sử dụng nước lau sàn chuyên dụng.',
            style: TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ================= THÔNG TIN CHI TIẾT =================
  Widget _detailInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: Colors.pink),
              SizedBox(width: 8),
              Text(
                'Thông tin chi tiết',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            icon: Icons.trending_up,
            label: 'Độ khó',
            value: 'Trung bình',
            badgeColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.repeat,
            label: 'Tần suất',
            value: 'Hàng tuần',
            badgeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: badgeColor.withOpacity(0.15),
          child: Icon(icon, color: badgeColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ================= NÚT DƯỚI =================
  Widget _bottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.check_circle_outline),
          label: const Text(
            'Hoàn Thành Ngay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
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

import 'package:flutter/material.dart';

class ClientHome extends StatelessWidget {
  const ClientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Column(
          children: const [
            Text(
              "🏠 HousePal",
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Trợ lý Ngôi nhà Chung",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ======================
            // THẺ CHÀO MỪNG (GRADIENT)
            // ======================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFFFF416C)],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Text(
                      "A",
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Xin chào,",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "Anh Nguyễn",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        
                        Text(
                          "5 thành viên • 3 việc đang chờ",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ======================
            // ĐIỂM + SỐ DƯ
            // ======================
            Row(
              children: [
                _infoCard(
                  icon: Icons.emoji_events,
                  title: "Điểm của bạn",
                  value: "120 điểm",
                  sub: "Hạng #2 tháng này",
                  color: Colors.green[50]!,
                  iconColor: Colors.green,
                ),
                const SizedBox(width: 12),
                _infoCard(
                  icon: Icons.attach_money,
                  title: "Số dư của bạn",
                  value: "-50.000đ",
                  sub: "Bạn đang nợ",
                  color: Colors.red[50]!,
                  iconColor: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ======================
            // VIỆC NHÀ HÔM NAY
            // ======================
            _sectionHeader("Việc nhà hôm nay", "Xem tất cả"),
            const SizedBox(height: 12),

            _taskItem(
              icon: Icons.delete,
              title: "Đổ rác",
              sub: "Đến lượt bạn • +10 điểm",
              action: "Làm ngay",
            ),
            _taskItem(
              icon: Icons.cleaning_services,
              title: "Lau nhà",
              sub: "Đến lượt Bình • +15 điểm",
              action: "Chờ",
              disabled: true,
            ),

            const SizedBox(height: 20),

            // ======================
            // NHẮC NHỞ THANH TOÁN
            // ======================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        "Nhắc nhở thanh toán",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text("Bạn nợ Chi 50.000đ (tiền điện tháng 11)"),
                  SizedBox(height: 6),
                  Text(
                    "Xem chi tiết →",
                    style: TextStyle(color: Colors.orange),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ======================
            // TOP CONTRIBUTORS
            // ======================
            _sectionHeader("🏆 Top Contributors", "Tháng 11/2025"),
            const SizedBox(height: 12),

            _rankItem("B", "Bình", "145 điểm", Colors.amber),
            _rankItem("A", "Anh Nguyễn", "120 điểm", Colors.grey),
            _rankItem("C", "Chi", "95 điểm", Colors.deepOrange),
          ],
        ),
      ),
    );
  }

  // ======================
  // WIDGET PHỤ
  // ======================

  static Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    required String sub,
    required Color color,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 13)),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(sub, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  static Widget _sectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        Text(action, style: const TextStyle(color: Colors.deepPurple)),
      ],
    );
  }

  static Widget _taskItem({
    required IconData icon,
    required String title,
    required String sub,
    required String action,
    bool disabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(sub,
                    style: TextStyle(
                        fontSize: 12,
                        color: disabled ? Colors.grey : Colors.black54)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: disabled ? null : () {},
            child: Text(action),
          )
        ],
      ),
    );
  }

  static Widget _rankItem(
      String avatar, String name, String point, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Text(avatar, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text(
            point,
            style: const TextStyle(
                color: Colors.deepPurple, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}

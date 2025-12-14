import 'package:flutter/material.dart';

class AutoRotateScreen extends StatelessWidget {
  const AutoRotateScreen({super.key});

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
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phân Công Tự Động',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Hệ thống Auto-Rotate thông minh',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _currentAssigneeCard(),
            const SizedBox(height: 16),
            _rotationSection(),
            const SizedBox(height: 16),
            _scheduleSection(),
            const SizedBox(height: 24),
            _viewAllButton(),
          ],
        ),
      ),
    );
  }

  // ================= Người phụ trách hiện tại =================
  Widget _currentAssigneeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3'),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Tuần này (18-24/12)',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= Vòng xoay phân công =================
  Widget _rotationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔁 Vòng xoay phân công',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _AvatarItem(name: 'Minh', order: 'Vị trí 1', badge: '1'),
              _AvatarItem(name: 'Hương', order: 'Vị trí 2', badge: '2'),
              _AvatarItem(name: 'Tuấn', order: 'Vị trí 3', badge: '3'),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '➡️ Tự động chuyển theo thứ tự ➡️',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ================= Lịch phân công =================
  Widget _scheduleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Lịch phân công chi tiết',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _scheduleItem(
            title: 'Tuần này (18-24/12)',
            name: 'Minh',
            status: 'Hiện tại',
            color: primaryColor,
          ),
          _scheduleItem(
            title: 'Tuần sau (25-31/12)',
            name: 'Hương',
            status: 'Tiếp theo',
            color: Colors.green,
          ),
          _scheduleItem(title: 'Tuần 1-7/1/2025', name: 'Tuấn'),
        ],
      ),
    );
  }

  Widget _scheduleItem({
    required String title,
    required String name,
    String? status,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(name),
              ],
            ),
          ),
          if (status != null)
            Chip(label: Text(status), backgroundColor: color?.withOpacity(0.2)),
        ],
      ),
    );
  }

  // ================= Nút xem toàn bộ =================
  Widget _viewAllButton() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.history),
      label: const Text('Xem Lịch Sử Phân Công'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
      ],
    );
  }
}

class _AvatarItem extends StatelessWidget {
  final String name;
  final String order;
  final String badge;

  const _AvatarItem({
    required this.name,
    required this.order,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=7'),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.blue,
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(order, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

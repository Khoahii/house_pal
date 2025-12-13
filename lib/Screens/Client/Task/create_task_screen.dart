import 'package:flutter/material.dart';

class CreateTaskScreen extends StatelessWidget {
  const CreateTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Tạo Việc Mới',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Tên công việc'),
            _buildTextField('Ví dụ: Lau nhà, Rửa bát...'),

            const SizedBox(height: 16),

            _buildLabel('Mô tả'),
            _buildTextField('Mô tả chi tiết công việc cần làm...', maxLines: 3),

            const SizedBox(height: 24),

            _buildLabel('Độ khó'),
            const SizedBox(height: 8),
            _buildDifficultySelector(),

            const SizedBox(height: 24),

            _buildLabel('Tần suất'),
            const SizedBox(height: 8),
            _buildFrequencySelector(),

            const SizedBox(height: 24),

            _buildLabel('Phân công'),
            const SizedBox(height: 8),
            _buildAutoAssignCard(),

            const SizedBox(height: 12),
            _buildMemberItem('Hương', 'A', Colors.pink),
            _buildMemberItem('Minh', 'B', Colors.blue),
            _buildMemberItem('Tuấn', 'C', Colors.green),

            const SizedBox(height: 24),

            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ===== Widgets nhỏ =====

  Widget _buildLabel(String text) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6, color: Color(0xFF4F46E5)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTextField(String hint, {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Row(
      children: const [
        _DifficultyItem(
          label: 'Dễ',
          point: '5 điểm',
          icon: Icons.sentiment_satisfied,
          selected: true,
        ),
        SizedBox(width: 12),
        _DifficultyItem(
          label: 'Trung bình',
          point: '10 điểm',
          icon: Icons.sentiment_neutral,
        ),
        SizedBox(width: 12),
        _DifficultyItem(
          label: 'Khó',
          point: '15 điểm',
          icon: Icons.sentiment_dissatisfied,
        ),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Row(
      children: const [
        _FrequencyItem(label: 'Hàng ngày'),
        SizedBox(width: 12),
        _FrequencyItem(label: 'Hàng tuần', selected: true),
        SizedBox(width: 12),
        _FrequencyItem(label: 'Hàng tháng'),
      ],
    );
  }

  Widget _buildAutoAssignCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4F46E5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.autorenew, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tự động xoay vòng',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Hệ thống tự phân công',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF4F46E5)),
        ],
      ),
    );
  }

  Widget _buildMemberItem(String name, String letter, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Text(letter, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {},
        child: const Text(
          'Lưu Việc Nhà',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _DifficultyItem extends StatelessWidget {
  final String label;
  final String point;
  final IconData icon;
  final bool selected;

  const _DifficultyItem({
    required this.label,
    required this.point,
    required this.icon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F8EF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.green : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(point, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _FrequencyItem extends StatelessWidget {
  final String label;
  final bool selected;

  const _FrequencyItem({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

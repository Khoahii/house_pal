import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/task_model.dart';
import '../../../models/room.dart';
import '../../../models/app_user.dart';
import '../../../services/task_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final Room currentRoom;
  final AppUser currentUser;

  const CreateTaskScreen({
    super.key,
    required this.currentRoom,
    required this.currentUser,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _difficulty = 'easy';
  int _point = 5;
  String _frequency = 'daily';
  String _assignMode = 'auto';
  DocumentReference? _manualAssignedTo;

  List<AppUser> roomMembers = [];

  @override
  void initState() {
    super.initState();
    _loadRoomMembers();
  }

  void _loadRoomMembers() async {
    List<AppUser> members = [];
    for (var memberRef in widget.currentRoom.members) {
      final doc = await memberRef.get();
      members.add(AppUser.fromFirestore(doc));
    }
    setState(() {
      roomMembers = members;
    });
  }

  void _saveTask() async {
    if (_titleController.text.isEmpty) return;

    final task = Task(
      title: _titleController.text,
      description: _descController.text,
      difficulty: _difficulty,
      point: _point,
      frequency: _frequency,
      assignMode: _assignMode,
      rotationOrder: _assignMode == 'auto' ? widget.currentRoom.members : null,
      rotationIndex: _assignMode == 'auto' ? 0 : null,
      manualAssignedTo:
          _assignMode == 'manual' ? _manualAssignedTo : null,
      createdBy: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    await TaskService().createTask(widget.currentRoom.id, task);
    Navigator.pop(context);
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tạo việc nhà mới',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Tên công việc'),
            _buildTextField('Nhập tên công việc', controller: _titleController),
            const SizedBox(height: 20),
            _buildLabel('Mô tả'),
            _buildTextField('Nhập mô tả công việc',
                maxLines: 3, controller: _descController),
            const SizedBox(height: 20),
            _buildLabel('Độ khó'),
            const SizedBox(height: 12),
            _buildDifficultySelector(),
            const SizedBox(height: 20),
            _buildLabel('Tần suất'),
            const SizedBox(height: 12),
            _buildFrequencySelector(),
            const SizedBox(height: 20),
            _buildLabel('Phân công'),
            const SizedBox(height: 12),
            _buildAutoAssignCard(),
          const SizedBox(height: 12),
            const Text(
             'Hoặc chỉ định thành viên:',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
           const SizedBox(height: 12),
            _buildMemberList(),
            const SizedBox(height: 32),
           _buildSaveButton(),
         ],
       ),
     ),
    ); }

  // ===== UI giữ nguyên =====

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

  Widget _buildTextField(String hint,
      {int maxLines = 1, required TextEditingController controller}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
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
      children: ['easy', 'medium', 'hard'].map((level) {
        final isSelected = _difficulty == level;
        String point = level == 'easy'
            ? '5 điểm'
            : level == 'medium'
                ? '10 điểm'
                : '15 điểm';
        IconData icon = level == 'easy'
            ? Icons.sentiment_satisfied
            : level == 'medium'
                ? Icons.sentiment_neutral
                : Icons.sentiment_dissatisfied;
        String label = level == 'easy'
            ? 'Dễ'
            : level == 'medium'
                ? 'Trung bình'
                : 'Khó';
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _difficulty = level;
                _point = int.parse(point.split(' ')[0]);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F8EF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(icon, color: isSelected ? Colors.green : Colors.grey, size: 28),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(point, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencySelector() {
    return Row(
      children: ['daily', 'weekly', 'monthly'].map((freq) {
        final isSelected = _frequency == freq;
        String label = freq == 'daily'
            ? 'Hàng ngày'
            : freq == 'weekly'
                ? 'Hàng tuần'
                : 'Hàng tháng';
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _frequency = freq;
              });
            },
            child: Container(
              height: 44,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAutoAssignCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _assignMode = 'auto';
          _manualAssignedTo = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _assignMode == 'auto' ? const Color(0xFF4F46E5) : Colors.grey),
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
            Icon(
              Icons.check_circle,
              color: _assignMode == 'auto' ? const Color(0xFF4F46E5) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberList() {
    return Column(
      children: roomMembers.map((user) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _assignMode = 'manual';
              _manualAssignedTo =
                  FirebaseFirestore.instance.collection('users').doc(user.uid);
            });
          },
          child: _buildMemberItem(
            user.name,
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '',
            Colors.blue,
          ),
        );
      }).toList(),
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
        onPressed: _saveTask,
        child: const Text(
          'Lưu Việc Nhà',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

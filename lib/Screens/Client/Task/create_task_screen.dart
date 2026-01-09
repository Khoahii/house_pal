import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/services/notify/snack_bar_service.dart';
import '../../../models/task/task_model.dart';
import '../../../models/room/room.dart';
import '../../../models/user/app_user.dart';
import '../../../services/task/task_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final Room currentRoom;
  final AppUser currentUser;
  final Task? editingTask;  // ✅ MỚI: null = create, có value = edit

  const CreateTaskScreen({
    super.key,
    required this.currentRoom,
    required this.currentUser,
    this.editingTask,
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
  
  // ✅ Anti-spam flags
  bool _isSaving = false;
  bool _hasPopped = false;
  
  // ✅ MỚI: Biến lưu task gốc (nếu edit mode)
  late Task? _originalTask;
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _originalTask = widget.editingTask;
    _isEditMode = widget.editingTask != null;
    _loadRoomMembers();
    
    // ✅ MỚI: Nếu edit mode, điền dữ liệu vào form
    if (_isEditMode && _originalTask != null) {
      _titleController.text = _originalTask!.title;
      _descController.text = _originalTask!.description;
      _difficulty = _originalTask!.difficulty;
      _point = _originalTask!.point;
      _frequency = _originalTask!.frequency;
      _assignMode = _originalTask!.assignMode;
      // ✅ FIX: Đặt assignMode trước, rồi mới assign manualAssignedTo
      if (_originalTask!.assignMode == 'manual') {
        _manualAssignedTo = _originalTask!.manualAssignedTo;
      }
    }
  }

  // ✅ THÊM: Dispose controllers
  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomMembers() async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.currentRoom.id);

    try {
      final qs = await FirebaseFirestore.instance
          .collection('users')
          .where('roomId', isEqualTo: roomRef)
          .where('role', whereIn: ['member', 'room_leader'])
          .get();

      final members = qs.docs.map((d) => AppUser.fromFirestore(d)).toList();
      
      // ✅ THÊM: Check mounted trước setState
      if (mounted) {
        setState(() => roomMembers = members);
      }
    } catch (e) {
      debugPrint('Error loading room members: $e');
      if (mounted) {
        setState(() => roomMembers = []);
      }
    }
  }

  void _saveTask() async {
    // ✅ FIX: Validate title không rỗng
    if (_titleController.text.trim().isEmpty) {
      SnackBarService.showError(context, 'Vui lòng nhập tên công việc');
      return;
    }
    
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final task = Task(
        id: _isEditMode ? _originalTask!.id : '', // ✅ FIX: ID phải có khi edit
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        difficulty: _difficulty,
        point: _point,
        frequency: _frequency,
        assignMode: _isEditMode ? _originalTask!.assignMode : _assignMode, // ✅ FIX: Giữ nguyên assignMode khi edit
        rotationOrder: _isEditMode ? _originalTask!.rotationOrder : null,  // ✅ Giữ nguyên khi edit
        rotationIndex: _isEditMode ? _originalTask!.rotationIndex : null,  // ✅ Giữ nguyên khi edit
        manualAssignedTo: _isEditMode 
            ? _originalTask!.manualAssignedTo  // ✅ FIX: Giữ nguyên assignee khi edit
            : (_assignMode == 'manual' ? _manualAssignedTo : null),
        createdBy: _isEditMode 
            ? _originalTask!.createdBy 
            : FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid),
        createdAt: _isEditMode ? _originalTask!.createdAt : Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // ✅ MỚI: Xử lý create vs update
      if (_isEditMode) {
        // ✅ FIX: Validate task.id trước khi update
        if (task.id.isEmpty) {
          throw Exception('Task ID không hợp lệ');
        }
        // Edit mode: update task
        await TaskService().updateTask(
          widget.currentRoom.id,
          task,
        );

        if (mounted) {
          SnackBarService.showSuccess(context, "Đã cập nhật việc thành công!");
        }
      } else {
        // Create mode: create new task
        await TaskService().createTask(widget.currentRoom.id, task);

        if (mounted) {
          SnackBarService.showSuccess(context, "Đã tạo việc mới thành công!");
        }
      }

      if (!_hasPopped) {
        _hasPopped = true;
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error saving task: $e');
      if (mounted) {
        String errorMsg = _isEditMode ? 'Cập nhật việc thất bại' : 'Tạo việc thất bại';
        if (e.toString().contains('network')) {
          errorMsg = 'Kiểm tra kết nối mạng';
        } else if (e.toString().contains('permission')) {
          errorMsg = 'Bạn không có quyền thực hiện hành động này';
        } else if (e.toString().contains('already exists')) {
          errorMsg = 'Công việc này đã tồn tại';
        } else if (e.toString().contains('Task ID không hợp lệ')) {
          errorMsg = 'Lỗi: ID công việc không hợp lệ';
        }

        SnackBarService.showError(context, errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
        title: Text(
          // ✅ MỚI: Động title dựa theo mode
          _isEditMode ? 'Chỉnh sửa việc nhà' : 'Tạo việc nhà mới',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
            // ✅ MỚI: Ẩn phần "Phân công" khi edit (giữ nguyên assignee)
            if (!_isEditMode) ...[
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
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Phân công không thể thay đổi khi chỉnh sửa',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

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
    // ✅ FIX: Check null và isEmpty
    if (roomMembers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Không có thành viên để phân công',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: roomMembers.map((user) {
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        final isSelected =
            _assignMode == 'manual' && _manualAssignedTo?.id == user.uid;

        return GestureDetector(
          onTap: () {
            setState(() {
              _assignMode = 'manual';
              _manualAssignedTo = userRef;
            });
          },
          child: _buildMemberItem(
            name: user.name,
            avatarUrl: user.avatarUrl,
            isSelected: isSelected,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMemberItem({
    required String name,
    String? avatarUrl,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFE0E7FF)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF4F46E5)
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          avatarUrl != null && avatarUrl.isNotEmpty
              ? CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(avatarUrl),
                  backgroundColor: Colors.grey[300],
                )
              : CircleAvatar(
                  backgroundColor: isSelected
                      ? const Color(0xFF4F46E5)
                      : Colors.blue,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : Colors.black,
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              color: Color(0xFF4F46E5),
            ),
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
        onPressed: _isSaving ? null : _saveTask,
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                // ✅ MỚI: Động button text dựa theo mode
                _isEditMode ? 'Cập Nhật' : 'Lưu Việc Nhà',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

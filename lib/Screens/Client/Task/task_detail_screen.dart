import 'package:flutter/material.dart';
import 'package:house_pal/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:house_pal/models/task_model.dart';
import 'package:house_pal/services/completion_service.dart';  // ✅ Thêm import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/models/app_user.dart';
class TaskDetailScreen extends StatefulWidget {
  final String roomId;
  final String assignmentId;

  const TaskDetailScreen({
    super.key,  // ✅ THÊM dòng này
    required this.roomId,
    required this.assignmentId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final Color primaryColor = const Color(0xFF4F46E5);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CompletionService _completionService = CompletionService();

  late final Future<Task?> _taskFuture = _loadData(); // cache future
  bool _isLoading = false;

  static const _freqMap = {
    'daily': 'Hàng ngày',
    'weekly': 'Hàng tuần',
    'monthly': 'Hàng tháng',
  };
  static const _diffMap = {
    'easy': 'Dễ',
    'medium': 'Trung bình',
    'hard': 'Khó',
  };

  // ✅ SỬA: Lấy Task trực tiếp từ tasks collection
  Future<Task?> _loadData() async {
    try {
      final taskSnap = await _firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('tasks') // ✅ Sửa từ 'assignments' thành 'tasks'
          .doc(widget.assignmentId)
          .get();

      if (!taskSnap.exists) {
        print('Task không tồn tại');
        return null;
      }

      return Task.fromMap(taskSnap.id, taskSnap.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error loading task: $e');
      return null;
    }
  }

  Future<bool?> _showDeleteConfirm() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Bạn có chắc chắn muốn xóa công việc này không?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDelete() async {
    final shouldDelete = await _showDeleteConfirm();
    if (shouldDelete == true) {
      setState(() => _isLoading = true);
      try {
        // ✅ SỬA: Xóa từ tasks collection
        await _firestore
            .collection('rooms')
            .doc(widget.roomId)
            .collection('tasks') // ✅ Sửa từ 'assignments' thành 'tasks'
            .doc(widget.assignmentId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa công việc thành công')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ✅ THÊM: Hàm hoàn thành task
  Future<void> _handleCompleteTask(Task task) async {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _completionService.completeTask(
        roomId: widget.roomId,
        task: task,
        currentUser: currentUser,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hoàn thành thành công! +${task.point} điểm'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(); // bỏ delay
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getFrequencyText(String frequency) =>
      _freqMap[frequency.toLowerCase()] ?? frequency;

  String _getDifficultyText(String difficulty) =>
      _diffMap[difficulty.toLowerCase()] ?? difficulty;

  bool _isCurrentUserAssignee(Task task, AppUser? currentUser) {
    if (currentUser == null) return false;

    // Ưu tiên manualAssignedTo
    DocumentReference? assigneeRef = task.manualAssignedTo;

    // Fallback rotation nếu thiếu
    if (assigneeRef == null && task.rotationOrder != null && task.rotationOrder!.isNotEmpty) {
      final idx = (task.rotationIndex ?? 0) % task.rotationOrder!.length;
      assigneeRef = task.rotationOrder![idx];
    }

    return assigneeRef != null && assigneeRef.id == currentUser.uid;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: FutureBuilder<Task?>(
        future: _taskFuture, // dùng future đã cache
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final task = snapshot.data;
          if (task == null) {
            return const Center(child: Text('Không tìm thấy công việc'));
          }

          final canComplete = _isCurrentUserAssignee(task, currentUser); // ✅

          return Column(
            children: [
              _buildAppBar(currentUser, task),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _assigneeCard(task),
                      const SizedBox(height: 16),
                      _descriptionCard(task),
                      const SizedBox(height: 16),
                      _detailInfoCard(task),
                    ],
                  ),
                ),
              ),
              if (canComplete) _bottomButton(task), // ✅ Chỉ hiển thị khi là người được giao
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(dynamic currentUser, Task task) {
    return AppBar(
      backgroundColor: primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        task.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (currentUser != null && currentUser.canCreateTask)
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _handleDelete,
                ),
      ],
    );
  }

  // ✅ SỬA: Nhận Task object thay vì DocumentReference
  Widget _assigneeCard(Task task) {
    // Ưu tiên manualAssignedTo
    DocumentReference? assigneeRef = task.manualAssignedTo;

    // Fallback rotation nếu thiếu
    if (assigneeRef == null && task.rotationOrder != null && task.rotationOrder!.isNotEmpty) {
      final int idx = task.rotationIndex ?? 0;
      final int safeIndex = idx % task.rotationOrder!.length;
      assigneeRef = task.rotationOrder![safeIndex];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: FutureBuilder<DocumentSnapshot>(
        future: assigneeRef != null ? assigneeRef.get() : null,
        builder: (context, snapshot) {
          String userName = 'Chưa phân công';
          String? avatarUrl;

          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            if (userData != null) {
              userName = userData['name'] ?? userData['fullName'] ?? 'Không có tên';
              avatarUrl = userData['avatarUrl'] ?? userData['avatar'] ?? userData['photoURL'];
            }
          }

          return Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : const NetworkImage('https://i.pravatar.cc/150?img=3'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Phân công cho', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Điểm thưởng', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('${task.point} ⭐', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _descriptionCard(Task task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Mô tả công việc',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.description.isNotEmpty
                ? task.description
                : 'Không có mô tả',
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _detailInfoCard(Task task) {
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
            value: _getDifficultyText(task.difficulty),
            badgeColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.repeat,
            label: 'Tần suất',
            value: _getFrequencyText(task.frequency),
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
        Expanded(child: Text(label)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ✅ SỬA: _bottomButton nhận task parameter
  Widget _bottomButton(Task task) {
    final disabled = _isLoading;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: disabled
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  ),
                ),
              )
            : ElevatedButton.icon(
                onPressed: disabled ? null : () => _handleCompleteTask(task),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Hoàn Thành Ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:house_pal/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:house_pal/models/task_model.dart';
import 'package:house_pal/services/completion_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/models/app_user.dart';

class TaskDetailScreen extends StatefulWidget {
  final String roomId;
  final String assignmentId;

  const TaskDetailScreen({
    super.key,
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

  bool _isLoading = false;
  bool _hasPopped = false;
  bool _justCompleted = false;

  // ✅ THÊM: Reset flags mỗi lần vào màn hình
  @override
  void initState() {
    super.initState();
    _hasPopped = false;
    _justCompleted = false;
  }

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

  // ✅ OPTIMIZATION: Tách riêng dialog để tránh rebuild
  Future<bool> _showDeleteConfirm() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa công việc này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _handleEdit(Task task) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng chỉnh sửa đang được phát triển'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleDelete() async {
    if (!await _showDeleteConfirm()) return;

    setState(() => _isLoading = true);
    
    try {
      await _firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('tasks')
          .doc(widget.assignmentId)
          .delete();

      if (!mounted) return;

      _showSnackBar('Đã xóa công việc thành công');

      if (!_hasPopped) {
        _hasPopped = true;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi khi xóa: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCompleteTask(Task task) async {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      _showSnackBar('Vui lòng đăng nhập', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await _completionService.completeTask(
        roomId: widget.roomId,
        task: task,
        currentUser: currentUser,
      );

      if (!mounted) return;

      // ✅ Chỉ set khi thành công
      setState(() {
        _justCompleted = true;
      });

      _showSnackBar(
        'Hoàn thành thành công! +${task.point} điểm',
        isSuccess: true,
      );

      // Manual task → pop ngay
      if (task.assignMode == 'manual' && !_hasPopped) {
        _hasPopped = true;
        Navigator.of(context).pop();
      }
      // Auto task → để StreamBuilder tự pop khi detect không còn được assign
      
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ OPTIMIZATION: Helper method cho SnackBar
  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Colors.red 
            : isSuccess 
                ? Colors.green 
                : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getFrequencyText(String frequency) =>
      _freqMap[frequency.toLowerCase()] ?? frequency;

  String _getDifficultyText(String difficulty) =>
      _diffMap[difficulty.toLowerCase()] ?? difficulty;

  bool _isCurrentUserAssignee(Task task, AppUser? currentUser) {
    if (currentUser == null) return false;

    DocumentReference? assigneeRef;
    
    if (task.assignMode == 'manual') {
      assigneeRef = task.manualAssignedTo;
    } else if (task.assignMode == 'auto') {
      if (task.rotationOrder != null && task.rotationOrder!.isNotEmpty) {
        final idx = (task.rotationIndex ?? 0) % task.rotationOrder!.length;
        assigneeRef = task.rotationOrder![idx];
      }
    }

    return assigneeRef?.id == currentUser.uid;
  }

  // ✅ OPTIMIZATION: Tách logic pop để tránh duplicate code
  void _popIfNeeded() {
    if (mounted && !_hasPopped) {
      _hasPopped = true;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('rooms')
            .doc(widget.roomId)
            .collection('tasks')
            .doc(widget.assignmentId)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          // Task đã bị xóa (manual task)
          if (!snapshot.hasData || !snapshot.data!.exists) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _popIfNeeded());
            return const SizedBox.shrink();
          }

          final task = Task.fromMap(
            snapshot.data!.id,
            snapshot.data!.data() as Map<String, dynamic>,
          );

          final canComplete = _isCurrentUserAssignee(task, currentUser);

          // ✅ Auto task completed → user không còn được assign → pop
          if (task.assignMode == 'auto' && _justCompleted && !canComplete) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _popIfNeeded());
            return const SizedBox.shrink();
          }

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
              if (canComplete) _bottomButton(task),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AppUser? currentUser, Task task) {
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
        if (currentUser?.canCreateTask ?? false)
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _handleEdit(task);
                    } else if (value == 'delete') {
                      _handleDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    _buildPopupMenuItem(
                      value: 'edit',
                      icon: Icons.edit,
                      label: 'Chỉnh sửa',
                      color: primaryColor,
                    ),
                    _buildPopupMenuItem(
                      value: 'delete',
                      icon: Icons.delete,
                      label: 'Xóa',
                      color: Colors.red,
                    ),
                  ],
                ),
      ],
    );
  }

  // ✅ OPTIMIZATION: Extract popup menu item
  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color == Colors.red ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assigneeCard(Task task) {
    DocumentReference? assigneeRef;

    if (task.assignMode == 'manual') {
      assigneeRef = task.manualAssignedTo;
    } else if (task.assignMode == 'auto') {
      if (task.rotationOrder != null && task.rotationOrder!.isNotEmpty) {
        final idx = (task.rotationIndex ?? 0) % task.rotationOrder!.length;
        assigneeRef = task.rotationOrder![idx];
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: FutureBuilder<DocumentSnapshot>(
        future: assigneeRef?.get(),
        builder: (context, snapshot) {
          String userName = 'Chưa phân công';
          String? avatarUrl;

          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            if (userData != null) {
              userName = userData['name'] ?? 
                         userData['fullName'] ?? 
                         'Không có tên';
              avatarUrl = userData['avatarUrl'] ?? 
                         userData['avatar'] ?? 
                         userData['photoURL'];
            }
          }

          return Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                // ✅ OPTIMIZATION: Null-safe avatar
                backgroundImage: (avatarUrl?.isNotEmpty ?? false)
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: (avatarUrl?.isEmpty ?? true)
                    ? Icon(Icons.person, color: Colors.grey[400])
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phân công cho',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Điểm thưởng',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${task.point} ⭐',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
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
            style: TextStyle(
              color: task.description.isNotEmpty 
                  ? Colors.black87 
                  : Colors.grey,
            ),
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
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomButton(Task task) {
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
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4F46E5),
                    ),
                  ),
                ),
              )
            : ElevatedButton.icon(
                onPressed: () => _handleCompleteTask(task),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Hoàn Thành Ngay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
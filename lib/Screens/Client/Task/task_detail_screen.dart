import 'package:flutter/material.dart';
import 'package:house_pal/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:house_pal/models/task_model.dart';
import 'package:house_pal/services/completion_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_pal/models/app_user.dart';
import 'package:house_pal/Screens/Client/Task/create_task_screen.dart';
import 'package:house_pal/models/room.dart';
import 'package:house_pal/services/snack_bar_service.dart';

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

  bool _isProcessing = false;
  bool _isDeleting = false;
  bool _hasPopped = false;
  bool _justCompleted = false;
  Task? _cachedTask;
  AppUser? _cachedCurrentUser;

  Map<String, Map<String, dynamic>> _assigneeCache = {};

  // ✅ OPT #1: Constants tập trung ở một chỗ
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

  static const _loadingSize = 24.0;
  static const _popDelay = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _hasPopped = false;
    _justCompleted = false;
    _isDeleting = false;
    _cachedTask = null;
    _cachedCurrentUser = null;
  }

  // ✅ OPT #2: Helper function tập trung xử lý Pop + Result
  void _popWithResult({
    required bool isCompleted,
    required String message,
    required String type,
    int? points,
  }) {
    if (!_hasPopped && mounted) {
      _hasPopped = true;
      Navigator.of(context).pop({
        'completed': isCompleted,
        'deleted': !isCompleted,
        'showMessage': true,
        'message': message,
        'type': type,
        if (points != null) 'points': points,
      });
    }
  }

  DocumentReference? _getAssigneeReference(Task task) {
    if (task.assignMode == 'manual') {
      return task.manualAssignedTo;
    } else if (task.assignMode == 'auto') {
      if (task.rotationOrder != null && task.rotationOrder!.isNotEmpty) {
        final idx = (task.rotationIndex ?? 0) % task.rotationOrder!.length;
        return task.rotationOrder![idx];
      }
    }
    return null;
  }

  Future<bool> _showDeleteConfirm() async {
    return await showDialog<bool>(
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
    ) ?? false;
  }

  void _handleEdit(Task task) async {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null || currentUser.roomId == null) {
      SnackBarService.showError(context, 'Lỗi: Không tìm thấy phòng');
      return;
    }

    try {
      final roomDoc = await currentUser.roomId!.get();
      
      if (!roomDoc.exists) {
        SnackBarService.showError(context, 'Lỗi: Phòng không tồn tại');
        return;
      }

      final room = Room.fromFirestore(roomDoc);

      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateTaskScreen(
              currentRoom: room,
              currentUser: currentUser,
              editingTask: task,
            ),
          ),
        );

        if (result == true && mounted) {
          setState(() {
            _assigneeCache.clear();
          });
        }
      }
    } catch (e) {
      debugPrint('Error in edit: $e');
      if (mounted) {
        SnackBarService.showError(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // ✅ OPT #3: Tối ưu _handleDelete - Loại bỏ duplicated setState
  Future<void> _handleDelete() async {
    if (!await _showDeleteConfirm()) return;

    setState(() {
      _isDeleting = true;
      _isProcessing = false;
      _justCompleted = false;
      _cachedTask = null;
    });

    try {
      await _firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('tasks')
          .doc(widget.assignmentId)
          .delete();

      if (!mounted) return;

      await Future.delayed(_popDelay);
      _popWithResult(
        isCompleted: false,
        message: 'Đã xóa công việc thành công',
        type: 'success',
      );
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'Lỗi khi xóa: $e');
        setState(() {
          _isDeleting = false;
          _isProcessing = false;
          _justCompleted = false;
        });
      }
    }
  }

  // ✅ OPT #4: Tối ưu _handleCompleteTask - Loại bỏ duplicated setState
  Future<void> _handleCompleteTask(Task task) async {
    if (_isProcessing || _isDeleting) return;

    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      SnackBarService.showError(context, 'Vui lòng đăng nhập');
      return;
    }

    setState(() {
      _cachedTask = task;
      _cachedCurrentUser = currentUser;
      _isProcessing = true;
      _justCompleted = true;
    });

    try {
      await _completionService.completeTask(
        roomId: widget.roomId,
        task: task,
        currentUser: currentUser,
      );

      if (!mounted) return;

      await Future.delayed(_popDelay);
      _popWithResult(
        isCompleted: true,
        message: 'Hoàn thành thành công! +${task.point} điểm',
        type: 'success',
        points: task.point,
      );
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'Lỗi: $e');
        setState(() {
          _isProcessing = false;
          _justCompleted = false;
          _cachedTask = null;
          _cachedCurrentUser = null;
        });
      }
    }
  }

  String _getFrequencyText(String frequency) =>
      _freqMap[frequency.toLowerCase()] ?? frequency;

  String _getDifficultyText(String difficulty) =>
      _diffMap[difficulty.toLowerCase()] ?? difficulty;

  bool _isCurrentUserAssignee(Task task, AppUser? currentUser) {
    if (currentUser == null) return false;
    final assigneeRef = _getAssigneeReference(task);
    return assigneeRef?.id == currentUser.uid;
  }

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
          if (_isDeleting) {
            return const Center(
              child: SizedBox(
                width: _loadingSize,
                height: _loadingSize,
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (_justCompleted && _cachedTask != null) {
            return _buildTaskUI(
              task: _cachedTask!,
              currentUser: _cachedCurrentUser,
              isProcessing: true,
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _popIfNeeded());
            return const SizedBox.shrink();
          }

          final task = Task.fromMap(
            snapshot.data!.id,
            snapshot.data!.data() as Map<String, dynamic>,
          );

          return _buildTaskUI(
            task: task,
            currentUser: currentUser,
            isProcessing: _isProcessing,
          );
        },
      ),
    );
  }

  Widget _buildTaskUI({
    required Task task,
    required AppUser? currentUser,
    required bool isProcessing,
  }) {
    final canComplete = _isCurrentUserAssignee(task, currentUser);

    if (task.assignMode == 'auto' && _justCompleted && !canComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _popIfNeeded());
      return const SizedBox.shrink();
    }

    final disableActions = isProcessing || _isDeleting;

    return Column(
      children: [
        _buildAppBar(currentUser, task, disableActions: disableActions),
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
        if (canComplete)
          _bottomButton(task, isProcessing: isProcessing || _isDeleting),
      ],
    );
  }

  Widget _bottomButton(Task task, {bool isProcessing = false}) {
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
        child: isProcessing
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  ),
                ),
              )
            : ElevatedButton.icon(
                onPressed: () => _handleCompleteTask(task),
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

  Widget _buildAppBar(AppUser? currentUser, Task task, {bool disableActions = false}) {
    return AppBar(
      backgroundColor: primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: disableActions ? null : () => Navigator.pop(context),
      ),
      title: Text(
        task.title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        if ((currentUser?.canCreateTask ?? false))
          disableActions
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

  // ✅ OPT #5: Tối ưu _assigneeCard - Combine logic cache vào một chỗ
  Widget _assigneeCard(Task task) {
    final assigneeRef = _getAssigneeReference(task);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: FutureBuilder<DocumentSnapshot>(
        future: assigneeRef?.get(),
        builder: (context, snapshot) {
          String userName = 'Chưa phân công';
          String avatarUrl = 'https://i.pravatar.cc/150?img=3';

          // Tối ưu: Kiểm tra cache trước, sau đó fetch
          if (assigneeRef != null && _assigneeCache.containsKey(assigneeRef.id)) {
            final cached = _assigneeCache[assigneeRef.id]!;
            userName = cached['name'] ?? 'Không có tên';
            avatarUrl = cached['avatarUrl'] ?? cached['avatar'] ?? avatarUrl;
          } else if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            if (userData != null) {
              _assigneeCache[assigneeRef!.id] = userData;
              userName = userData['name'] ?? userData['fullName'] ?? 'Không có tên';
              avatarUrl = userData['avatarUrl'] ?? 
                         userData['avatar'] ?? 
                         userData['photoURL'] ?? 
                         avatarUrl;
            }
          }

          return Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty ? Icon(Icons.person, color: Colors.grey[400]) : null,
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
            task.description.isNotEmpty ? task.description : 'Không có mô tả',
            style: TextStyle(
              color: task.description.isNotEmpty ? Colors.black87 : Colors.grey,
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
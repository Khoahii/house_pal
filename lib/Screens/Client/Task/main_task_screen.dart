import 'package:flutter/material.dart';
import 'create_task_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:house_pal/models/app_user.dart';
import 'package:house_pal/Screens/Client/Task/ranking_screen.dart';
import 'package:house_pal/Screens/Client/Task/task_detail_screen.dart';
import 'package:house_pal/models/room.dart';
import 'package:house_pal/services/leaderboard_service.dart';
import 'package:house_pal/models/leaderboard_score.dart';

void main() {
  runApp(const MainTaskScreen());
}

class MainTaskScreen extends StatelessWidget {
  const MainTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Roboto'),
      ),
      home: const MainTask(),
    );
  }
}

class MainTask extends StatefulWidget {
  const MainTask({super.key});
  @override
  State<MainTask> createState() => _MainTaskState();
}

class _MainTaskState extends State<MainTask> {
  AppUser? currentUser;
  Room? currentRoom;
  bool isLoadingUser = true;
  String _filterType = 'my_tasks';
  
  final Map<String, Map<String, dynamic>> _userCache = {};
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;


    if (firebaseUser == null) {
      setState(() {
        currentUser = null;
        currentRoom = null; 
        isLoadingUser = false;
        _userCache.clear();
        _filterType = 'my_tasks';
      });
      return;
    }

    _currentUserId = firebaseUser.uid;
    
    _userCache.clear();

    final userRef = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
    final doc = await userRef.get();

    AppUser? newUser;
    if (doc.exists) {
      newUser = AppUser.fromFirestore(doc);
    }

    Room? newRoom;
    final roomQuery = await FirebaseFirestore.instance
        .collection('rooms')
        .where('members', arrayContains: userRef)
        .limit(1)
        .get();

    if (roomQuery.docs.isNotEmpty) {
      newRoom = Room.fromFirestore(roomQuery.docs.first);
    }

    setState(() {
      currentUser = newUser;
      currentRoom = newRoom;
      isLoadingUser = false;
    });
  }

  DocumentReference? _getAssigneeReference(Map<String, dynamic> taskData) {
    final assignMode = taskData['assignMode'] ?? 'auto';

    if (assignMode == 'manual') {
      return taskData['manualAssignedTo'] as DocumentReference?;
    } else if (assignMode == 'auto') {
      final rotationOrder = taskData['rotationOrder'] as List<dynamic>?;
      final rotationIndex = taskData['rotationIndex'] as int?;

      if (rotationOrder != null && rotationOrder.isNotEmpty) {
        final safeIndex = (rotationIndex ?? 0) % rotationOrder.length;
        return rotationOrder[safeIndex] as DocumentReference;
      }
    }
    return null;
  }

  // Hàm cache assignee data
  Future<Map<String, dynamic>> _getAssigneeData(DocumentReference? ref) async {
    if (ref == null) {
      return {
        'name': 'Chưa phân công',
        'avatar': 'https://i.pravatar.cc/150?img=3',
      };
    }
    // Kiểm tra cache trước
    if (_userCache.containsKey(ref.id)) {
      return _userCache[ref.id]!;
    }

    try {
      final doc = await ref.get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final assigneeData = {
          'name': userData['name'] ?? 'Thành viên',
          'avatar': userData['avatarUrl'] ?? userData['avatar'] ?? 'https://i.pravatar.cc/150?img=3',
        };
        // Lưu vào cache
        _userCache[ref.id] = assigneeData;
        return assigneeData;
      }
    } catch (e) {
      // Error handling - silently fall back to default
    }
    return {
      'name': 'Chưa phân công',
      'avatar': 'https://i.pravatar.cc/150?img=3',
    };
  }

  Widget _buildPopupMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF374151),
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check,
              color: Color(0xFF4F46E5),
              size: 20,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lịch Việc Nhà",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: isLoadingUser
          ? null
          : (currentUser != null && currentUser!.canCreateTask && currentRoom != null)
              ? FloatingActionButton(
                  heroTag: 'createTask',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateTaskScreen(
                          currentUser: currentUser!,
                          currentRoom: currentRoom!,
                        ),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF4F46E5),
                  elevation: 4,
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                )
              : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bảng xếp hạng
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🏆 Bảng Xếp Hạng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (currentRoom != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RankingScreen(
                                  roomId: currentRoom!.id,
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Xem tất cả',
                          style: TextStyle(
                            color: Color(0xFFE0E7FF),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (currentRoom != null)
                    StreamBuilder<List<LeaderboardScore>>(
                      stream: LeaderboardService().getTop3(currentRoom!.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 80,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'Chưa có dữ liệu xếp hạng',
                                style: TextStyle(
                                  color: Color(0xFFE0E7FF),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }

                        final top3 = snapshot.data!;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (top3.isNotEmpty)
                              LeaderboardItem(
                                name: top3[0].userName ?? 'User',
                                image: top3[0].userAvatar ?? 'https://i.pravatar.cc/150?img=1',
                                isWinner: true,
                              )
                            else
                              const SizedBox(width: 60),
                            if (top3.length >= 2)
                              LeaderboardItem(
                                name: top3[1].userName ?? 'User',
                                image: top3[1].userAvatar ?? 'https://i.pravatar.cc/150?img=2',
                              )
                            else
                              const SizedBox(width: 60),
                            if (top3.length >= 3)
                              LeaderboardItem(
                                name: top3[2].userName ?? 'User',
                                image: top3[2].userAvatar ?? 'https://i.pravatar.cc/150?img=3',
                              )
                            else
                              const SizedBox(width: 60),
                          ],
                        );
                      },
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Vui lòng tham gia phòng',
                          style: TextStyle(
                            color: Color(0xFFE0E7FF),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh Sách Việc',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    setState(() => _filterType = value);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'my_tasks',
                      child: _buildPopupMenuItem(
                        icon: Icons.person_outline,
                        title: 'Việc của tôi',
                        isSelected: _filterType == 'my_tasks',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'all_tasks',
                      child: _buildPopupMenuItem(
                        icon: Icons.list_alt,
                        title: 'Tất cả việc',
                        isSelected: _filterType == 'all_tasks',
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _filterType == 'my_tasks' ? Icons.person_outline : Icons.list_alt,
                          color: const Color(0xFF4F46E5),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _filterType == 'my_tasks' ? 'Của tôi' : 'Tất cả',
                          style: const TextStyle(
                            color: Color(0xFF4F46E5),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF4F46E5),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (currentRoom != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(currentRoom!.id)
                    .collection('tasks')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("Chưa có công việc nào."),
                      ),
                    );
                  }

                  var tasks = snapshot.data!.docs;

      
                  if (_filterType == 'my_tasks' && currentUser != null) {
                    final currentUserRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUserId);

                    tasks = tasks.where((taskDoc) {
                      final data = taskDoc.data() as Map<String, dynamic>;
                      final assigneeRef = _getAssigneeReference(data);
                      return assigneeRef?.path == currentUserRef.path;
                    }).toList();
                  }

                  if (tasks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          _filterType == 'my_tasks'
                              ? 'Bạn chưa có công việc nào được phân công.'
                              : 'Chưa có công việc nào.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final taskDoc = tasks[index];
                      final data = taskDoc.data() as Map<String, dynamic>;

                      final difficulty = data['difficulty'] ?? 'easy';
                      Color diffColor;
                      Color diffBg;
                      String diffLabel;

                      if (difficulty == 'hard') {
                        diffColor = const Color(0xFFB91C1C);
                        diffBg = const Color(0xFFFEE2E2);
                        diffLabel = 'Khó';
                      } else if (difficulty == 'medium') {
                        diffColor = const Color(0xFFA16207);
                        diffBg = const Color(0xFFFEF9C3);
                        diffLabel = 'Trung bình';
                      } else {
                        diffColor = const Color(0xFF15803D);
                        diffBg = const Color(0xFFDCFCE7);
                        diffLabel = 'Dễ';
                      }

                      final assignMode = data['assignMode'] ?? 'auto';
                      DocumentReference? assigneeRef;

                      if (assignMode == 'manual') {
                        assigneeRef = data['manualAssignedTo'] as DocumentReference?;
                      } else if (assignMode == 'auto') {
                        final rotationOrder = data['rotationOrder'] as List<dynamic>?;
                        final rotationIndex = data['rotationIndex'] as int?;

                        if (rotationOrder != null && rotationOrder.isNotEmpty) {
                          final safeIndex = (rotationIndex ?? 0) % rotationOrder.length;
                          assigneeRef = rotationOrder[safeIndex] as DocumentReference;
                        }
                      }

                      final isManual = (assignMode == 'manual');
                      final Color modeColor = isManual
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFF59E0B);
                      final IconData modeIcon = isManual ? Icons.person : Icons.bolt;
                      final String modeLabel = isManual ? 'Chỉ định' : 'Tự gán';

                      return FutureBuilder<Map<String, dynamic>>(
                        future: _getAssigneeData(assigneeRef),
                        builder: (context, userSnapshot) {
                          String assigneeName = 'Chưa phân công';
                          String assigneeAvatar = 'https://i.pravatar.cc/150?img=3';

                          if (userSnapshot.hasData) {
                            assigneeName = userSnapshot.data!['name'] ?? 'Chưa phân công';
                            assigneeAvatar = userSnapshot.data!['avatar'] ?? 'https://i.pravatar.cc/150?img=3';
                          }

                          return TaskCardItem(
                            difficulty: diffLabel,
                            difficultyColor: diffColor,
                            difficultyBg: diffBg,
                            points: '+${data['point'] ?? 0}',
                            title: data['title'] ?? 'Không tên',
                            description: data['description'] ?? '',
                            assignee: assigneeName,
                            assigneeAvatar: assigneeAvatar,
                            onDetailTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaskDetailScreen(
                                    roomId: currentRoom!.id,
                                    assignmentId: taskDoc.id,
                                  ),
                                ),
                              );
                            },
                            modeLabel: modeLabel,
                            modeIcon: modeIcon,
                            modeColor: modeColor,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ============ Các Widget Con ============

class LeaderboardItem extends StatelessWidget {
  final String name;
  final String image;
  final bool isWinner;

  const LeaderboardItem({
    super.key,
    required this.name,
    required this.image,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(image),
                backgroundColor: Colors.grey[300],
              ),
            ),
            if (isWinner)
              const Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: Text('👑', style: TextStyle(fontSize: 18)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class FilterTab extends StatelessWidget {
  final String text;
  final bool isSelected;

  const FilterTab({super.key, required this.text, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class TaskCardItem extends StatelessWidget {
  final String difficulty;
  final Color difficultyColor;
  final Color difficultyBg;
  final String points;
  final String title;
  final String description;
  final String assignee;
  final String assigneeAvatar;
  final VoidCallback onDetailTap;
  final String modeLabel;
  final IconData modeIcon;
  final Color modeColor;

  const TaskCardItem({
    super.key,
    required this.difficulty,
    required this.difficultyColor,
    required this.difficultyBg,
    required this.points,
    required this.title,
    required this.description,
    required this.assignee,
    required this.assigneeAvatar,
    required this.onDetailTap,
    required this.modeLabel,
    required this.modeIcon,
    required this.modeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: difficultyBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  difficulty,
                  style: TextStyle(
                    color: difficultyColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                points,
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Tooltip(
                message: modeLabel,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(modeIcon, size: 16, color: modeColor),
                    const SizedBox(width: 6),
                    Text(
                      modeLabel,
                      style: TextStyle(
                        color: modeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage(assigneeAvatar),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    assignee,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onDetailTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: const Color(0xFFEEF2FF),
                  foregroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Chi tiết',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'create_task_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:house_pal/models/app_user.dart';
import 'package:house_pal/Screens/Client/Task/ranking_screen.dart';
import 'package:house_pal/Screens/Client/Task/task_detail_screen.dart ';
import 'package:house_pal/models/room.dart';
import 'package:house_pal/models/task_model.dart'; // Đảm bảo đường dẫn import đúng với project của bạn

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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      setState(() => isLoadingUser = false);
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
    final doc = await userRef.get();

    if (doc.exists) {
      currentUser = AppUser.fromFirestore(doc);
    }

   final roomQuery = await FirebaseFirestore.instance
          .collection('rooms')
          .where('members', arrayContains: userRef)
          .limit(1)
          .get();

      if (roomQuery.docs.isNotEmpty) {
        currentRoom = Room.fromFirestore(roomQuery.docs.first);
      }
    setState(() => isLoadingUser = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nút cộng vẫn giữ nguyên
      floatingActionButton: isLoadingUser
          ? null
          : (currentUser != null && currentUser!.canCreateTask && currentRoom != null)
          ? FloatingActionButton(
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

      body: Stack(
        children: [
          // 1. NỀN GRADIENT CỐ ĐỊNH
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),

          // 2. NỘI DUNG CHIA LÀM 2 PHẦN: CỐ ĐỊNH & CUỘN
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= PHẦN CỐ ĐỊNH (KHÔNG CUỘN) =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Header Title
                      const Text(
                        'Lịch Việc Nhà',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bảng xếp hạng
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RankingScreen(),
                                      ),
                                    );
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                LeaderboardItem(
                                  name: 'Minh',
                                  image: 'https://placehold.co/48x48',
                                  isWinner: true,
                                ),
                                LeaderboardItem(
                                  name: 'Hương',
                                  image: 'https://placehold.co/48x48',
                                ),
                                LeaderboardItem(
                                  name: 'Tuấn',
                                  image: 'https://placehold.co/48x48',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // ================= PHẦN CUỘN (SCROLLABLE) =================
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề danh sách
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
                            //Nút nagivator đến auto rotate screen
                                                     ],
                        ),

                        const SizedBox(height: 24),

                        // Hiển thị danh sách Task từ Firestore
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

                              final tasks = snapshot.data!.docs;

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: tasks.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final data = tasks[index].data() as Map<String, dynamic>;
                                  // Xử lý màu sắc dựa trên độ khó
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

                                  // Xác định Reference của người được giao việc
                                  DocumentReference? assigneeRef;
                                  if (data['assignMode'] == 'manual') {
                                    assigneeRef = data['manualAssignedTo'] as DocumentReference?;
                                  } else {
                                    // Xử lý chế độ xoay vòng (auto)
                                    final List<dynamic>? rotationOrder = data['rotationOrder'];
                                    final int rotationIndex = data['rotationIndex'] ?? 0;
                                    if (rotationOrder != null && rotationOrder.isNotEmpty) {
                                      // Dùng phép chia lấy dư để đảm bảo index luôn hợp lệ
                                      final int safeIndex = rotationIndex % rotationOrder.length;
                                      assigneeRef = rotationOrder[safeIndex] as DocumentReference?;
                                    }
                                  }

                                  // Dùng FutureBuilder để tải thông tin user từ Reference
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: assigneeRef?.get(),
                                    builder: (context, userSnapshot) {
                                      String assigneeName = '...';
                                      if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                                        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                        assigneeName = userData['name'] ?? 'Thành viên';
                                      }

                                      return TaskCardItem(
                                        difficulty: diffLabel,
                                        difficultyColor: diffColor,
                                        difficultyBg: diffBg,
                                        points: '+${data['point'] ?? 0}',
                                        title: data['title'] ?? 'Không tên',
                                        description: data['description'] ?? '',
                                        assignee: assigneeName,
                                        assigneeAvatar: 'https://placehold.co/32x32',
                                        onDetailTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const TaskDetailScreen(),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),

                        // Khoảng trống dưới cùng (quan trọng để list cuộn lên hết không bị FAB che)
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- CÁC WIDGET CON (GIỮ NGUYÊN) ----------------

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
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: onDetailTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Chi tiết',
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
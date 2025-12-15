import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Giả lập role hiện tại (sau này lấy từ AuthProvider)
  final String currentUserRole = "admin";

  /// Danh sách thành viên (mock data)
  final List<Map<String, String>> members = [
    {"name": "Nguyễn Minh An", "role": "admin"},
    {"name": "Anh Nguyễn", "role": "room_leader"},
    {"name": "Chi", "role": "member"},
    {"name": "Bình", "role": "member"},
  ];

  final Map<String, String> roleLabel = {
    "admin": "Admin",
    "room_leader": "Room Leader",
    "member": "Member",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ===== AVATAR =====
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.deepPurple, width: 2),
                ),
                child: const Icon(Icons.person, size: 50, color: Colors.grey),
              ),

              const SizedBox(height: 12),

              const Text(
                "Nguyễn Minh An",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Admin nhà",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ===== QUẢN LÝ =====
              _sectionTitle("Quản lý"),

              _menuCard(icon: Icons.group, title: "Thành viên trong nhà"),
              _menuCard(icon: Icons.calendar_month, title: "Lịch việc nhà"),
              _menuCard(icon: Icons.attach_money, title: "Quỹ chung"),
              _menuCard(icon: Icons.emoji_events, title: "Bảng xếp hạng"),

              /// ===============================
              /// PHÂN QUYỀN – CHỈ ADMIN THẤY
              /// ===============================
              if (currentUserRole == "admin") ...[
                const SizedBox(height: 30),
                _sectionTitle("Phân quyền thành viên"),
                const SizedBox(height: 8),
                _roleManagementCard(),
              ],

              const SizedBox(height: 20),

              _dangerCard(icon: Icons.exit_to_app, title: "Rời khỏi nhà"),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.black54),
                    SizedBox(width: 8),
                    Text(
                      "Đăng xuất",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ======================
  // PHÂN QUYỀN UI
  // ======================
  Widget _roleManagementCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: members.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member["name"]!,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                DropdownButton<String>(
                  value: member["role"],
                  underline: const SizedBox(),
                  items: roleLabel.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      members[index]["role"] = value!;
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ======================
  // UI HELPERS
  // ======================
  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _menuCard({required IconData icon, required String title}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _dangerCard({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.red),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.red,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.red),
        ],
      ),
    );
  }
}

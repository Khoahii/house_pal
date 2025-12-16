import 'package:flutter/material.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  // Mock danh sách thành viên (sau này lấy từ Firestore)
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
      appBar: AppBar(
        title: const Text("Phân quyền thành viên"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline,
                    color: Colors.deepPurple),
                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    member["name"]!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
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
        },
      ),
    );
  }
}

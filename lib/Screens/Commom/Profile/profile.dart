import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Commom/Profile/screen_update_info.dart';
import 'package:house_pal/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:house_pal/providers/auth_provider.dart';
import 'package:provider/provider.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Consumer<MyAuthProvider>(
            builder: (context, authProvider, child) {
              final AppUser? user = authProvider.currentUser;
              final bool isLoading = user == null && authProvider.isLoggedIn;
              // Nếu chưa load xong user nhưng đã login, có thể show loading

              return Column(
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
                    child: ClipOval(
                      child: user?.avatarUrl != null
                          ? Image.network(
                              user!.avatarUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== NAME =====
                  Text(
                    user?.name ?? "Chưa có tên",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ===== NÚT CHỈNH SỬA =====
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        // Navigate đến screen chỉnh sửa
                        final bool? updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );

                        // Nếu screen edit trả về true (cập nhật thành công), refresh user
                        if (updated == true) {
                          authProvider.refreshUser();
                        }
                      },
                      child: const Text(
                        "Chỉnh sửa",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== QUẢN LÝ =====
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Quản lý",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _menuCard(icon: Icons.group, title: "Thành viên trong nhà"),
                  _menuCard(icon: Icons.calendar_month, title: "Lịch việc nhà"),
                  _menuCard(icon: Icons.attach_money, title: "Quỹ chung"),
                  _menuCard(icon: Icons.emoji_events, title: "Bảng xếp hạng"),

                  const SizedBox(height: 16),

                  // ===== RỜI KHỎI NHÀ =====
                  _dangerCard(icon: Icons.exit_to_app, title: "Rời khỏi nhà"),

                  const SizedBox(height: 20),

                  // ===== ĐĂNG XUẤT =====
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      // MyAuthProvider sẽ tự động cập nhật currentUser = null
                    },
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
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // MENU ITEM
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  // DANGER ITEM
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
                fontWeight: FontWeight.w500,
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

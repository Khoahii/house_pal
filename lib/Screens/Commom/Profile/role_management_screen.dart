import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/app_user.dart';
import '../../../services/role_management_service.dart';

class RoleManagementScreen extends StatelessWidget {
  const RoleManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<MyAuthProvider>(context);
    final AppUser user = auth.currentUser!;

    final service = RoleManagementService();

    Stream<List<AppUser>> stream;

    if (user.role == 'admin') {
      stream = service.getAllUsers();
    } else if (user.role == 'room_leader' && user.roomId != null) {
      stream = service.getUsersInRoom(user.roomId!);
    } else {
      return const Center(child: Text('Không có quyền'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Phân quyền thành viên')),
      body: StreamBuilder<List<AppUser>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;

          if (users.isEmpty) {
            return const Center(child: Text('Không có thành viên'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(u.name),
                subtitle: Text(u.role),
                trailing: _roleDropdown(user, u),
              );
            },
          );
        },
      ),
    );
  }

  /// Dropdown chỉ cho admin & room_leader
  Widget _roleDropdown(AppUser currentUser, AppUser targetUser) {
    if (currentUser.role == 'room_leader' &&
        targetUser.role == 'admin') {
      return const SizedBox(); // không cho thấy admin
    }

    return DropdownButton<String>(
      value: targetUser.role,
      items: const [
        DropdownMenuItem(value: 'member', child: Text('Member')),
        DropdownMenuItem(value: 'room_leader', child: Text('Room Leader')),
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
      ],
      onChanged: (_) {},
    );
  }
}

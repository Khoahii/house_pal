import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:house_pal/models/user/app_user.dart';
import 'package:house_pal/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/user/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  XFile? _selectedImage; // Dùng XFile để tương thích cả web và mobile
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();

    final currentUser = Provider.of<MyAuthProvider>(
      context,
      listen: false,
    ).currentUser;
    if (currentUser != null) {
      _nameController.text = currentUser.name;
      _phoneController.text = currentUser.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _saveChanges() async {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final String? uid = authProvider.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _userService.updateUser(
        uid: uid,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        avatarFile: _selectedImage,
      );

      await authProvider.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<MyAuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: SizedBox(
                          width: 140,
                          height: 140,
                          child: _buildAvatarPreview(currentUser),
                        ),
                      ),
                    ),
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm riêng để build preview avatar (xử lý async cho web)
  Widget _buildAvatarPreview(AppUser? currentUser) {
    // Ưu tiên 1: Ảnh mới được chọn
    if (_selectedImage != null) {
      if (kIsWeb) {
        // Web: Sử dụng FutureBuilder để chờ đọc bytes async
        return FutureBuilder<Uint8List>(
          future: _selectedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  width: 140,
                  height: 140,
                );
              } else {
                return const Icon(Icons.error, size: 80, color: Colors.red);
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      } else {
        // Mobile: Hiển thị trực tiếp từ file path
        return Image.file(
          File(_selectedImage!.path),
          fit: BoxFit.cover,
          width: 140,
          height: 140,
        );
      }
    }
    // Ưu tiên 2: Avatar từ Firestore
    else if (currentUser?.avatarUrl != null &&
        currentUser!.avatarUrl!.isNotEmpty) {
      return Image.network(
        currentUser.avatarUrl!,
        fit: BoxFit.cover,
        width: 140,
        height: 140,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const CircularProgressIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 80, color: Colors.grey);
        },
      );
    }

    // Mặc định: Icon người
    return const Icon(Icons.person, size: 80, color: Colors.grey);
  }
}

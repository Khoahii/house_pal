import 'package:flutter/material.dart';
import 'package:house_pal/services/auth/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng điền đầy đủ thông tin"),
          backgroundColor: Color.fromARGB(255, 0, 0, 0),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text("Đăng ký thành công!"),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      // Logic mapping lỗi Firebase giữ nguyên của bạn...
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Đảm bảo body tự động co giãn khi có bàn phím
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // GIẢI PHÁP: Bọc toàn bộ nội dung trong cuộn
          physics: const BouncingScrollPhysics(), // Hiệu ứng cuộn mượt mà
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Đăng ký',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Full Name
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Nhập tên của bạn',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),

                // Email
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Nhập email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Password
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Mật khẩu',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),

                const SizedBox(height: 40),

                // Button Register
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Đăng ký tài khoản',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                // Divider "or"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'hoặc',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 20),

                // Social Buttons (Có thể tách widget để code sạch hơn)
                _buildSocialButton(
                  onPressed: () {},
                  icon: Icons.facebook,
                  label: 'Đăng nhập với Facebook',
                  color: const Color(0xFF1877F2),
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  onPressed: () {},
                  icon: Icons.apple,
                  label: 'Đăng nhập với Apple',
                  color: Colors.black,
                ),

                const SizedBox(height: 40), // Thay thế cho Spacer()
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Bạn đã có tài khoản? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: Color(0xFF9C27B0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Padding cuối trang
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget Helper để code DRY (Don't Repeat Yourself) hơn
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        // prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black, size: 24),
      label: Text(
        label,
        style: const TextStyle(color: Colors.black, fontSize: 16),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

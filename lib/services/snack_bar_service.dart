import 'package:flutter/material.dart';

class SnackBarService {
  // Thông báo Thành công (Màu xanh)
  static void showSuccess(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF10B981),
    );
  }

  // Thông báo Lỗi (Màu đỏ)
  static void showError(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFEF4444),
    );
  }

  // Thông báo Cảnh báo/Thông tin (Màu xanh dương)
  static void showInfo(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: const Color(0xFF3B82F6),
    );
  }

  static void _showCustomSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar(); // Ẩn thông báo cũ nếu có

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            Colors.transparent, // Để dùng Container bo góc bên trong
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

enum Onboardingposition { page1, page2, page3 }

extension OnboardingPositionExtension on Onboardingposition {
  String getPathImage() {
    switch (this) {
      case Onboardingposition.page1:
        return "assets/images/onboarding_img_page1.png";
      case Onboardingposition.page2:
        return "assets/images/onboarding_img_page2.png";
      case Onboardingposition.page3:
        return "assets/images/onboarding_img_page3.png";
    }
  }

  String getTitle() {
    switch (this) {
      case Onboardingposition.page1:
        return "Lịch Việc Nhà thông minh";
      case Onboardingposition.page2:
        return "Thuận tiện chi tiêu";
      case Onboardingposition.page3:
        return "Bảng tin chung";
    }
  }

  String getDescription() {
    switch (this) {
      case Onboardingposition.page1:
        return "Phân công công việc công bằng và tự động theo vòng quay.";
      case Onboardingposition.page2:
        return "Ghi lại chi tiêu và chia tiền công bằng cho mọi thành viên.";
      case Onboardingposition.page3:
        return "Ghim ghi chú quan trọng và quản lý danh sách mua sắm chung cho cả nhà";
    }
  }

  List<Map<String, dynamic>> getContent() {
    switch (this) {
      case Onboardingposition.page1:
        return [
          {
            'icon': Icons.calendar_today,
            'text': 'Phân công theo lịch.',
          },
          {
            'icon': Icons.rotate_90_degrees_ccw,
            'text': 'Xoay vòng công bằng.',
          },
          {'icon': Icons.check, 'text': 'Đánh dấu hoàn thành dễ dàng.'},
        ];
      case Onboardingposition.page2:
        return [
          {'icon': Icons.add, 'text': 'Thêm Chi Tiêu Nhanh.'},
          {'icon': Icons.card_membership, 'text': 'Chia Tiền Linh Hoạt.'},
          {'icon': Icons.list, 'text': 'Theo Dõi Rõ Ràng.'},
        ];
      case Onboardingposition.page3:
        return [
          {'icon': Icons.text_snippet, 'text': 'Ghi chú Chung.'},
          {'icon': Icons.shopping_cart, 'text': ' Danh sách Mua sắm Chung.'},
        ];
    }
  }
}

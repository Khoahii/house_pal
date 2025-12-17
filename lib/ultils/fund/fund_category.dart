// lib/utils/fund_category.dart

class FundCategory {
  final String id;
  final String name;
  final String icon;

  const FundCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

// lib/utils/fund_category.dart
const List<FundCategory> fundCategories = [
  FundCategory(id: "travel", name: "Đi chơi", icon: "✈️"),
  FundCategory(id: "food", name: "Ăn uống", icon: "🍜"),
  FundCategory(id: "party", name: "Tiệc tùng", icon: "🥳"),
  FundCategory(id: "rent", name: "Tiền nhà", icon: "🏠"),
  FundCategory(id: "shopping", name: "Mua sắm", icon: "🛍️"),
  FundCategory(id: "coffee", name: "Café", icon: "☕"),
  FundCategory(id: "game", name: "Game", icon: "🎮"),
  FundCategory(id: "gift", name: "Quà tặng", icon: "🎁"),
  FundCategory(id: "health", name: "Gym / Sức khỏe", icon: "💪"),
  FundCategory(id: "pet", name: "Thú cưng", icon: "🐶"),
  FundCategory(id: "car", name: "Xăng xe", icon: "🚗"),
  FundCategory(id: "study", name: "Học tập", icon: "📚"),
  FundCategory(id: "internet", name: "Internet", icon: "🌐"),
  FundCategory(id: "electric", name: "Điện", icon: "🔌"),
  FundCategory(id: "water", name: "Nước", icon: "💧"),
  FundCategory(id: "cinema", name: "Xem phim", icon: "🎬"),
  FundCategory(id: "beauty", name: "Làm đẹp", icon: "💅"),
  FundCategory(id: "baby", name: "Em bé", icon: "🍼"),
  FundCategory(id: "phone", name: "Điện thoại", icon: "📱"),
  FundCategory(id: "work", name: "Công việc", icon: "💼"),
  FundCategory(id: "other", name: "Khác", icon: "📦"),
];


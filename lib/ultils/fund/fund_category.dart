// lib/utils/fund_category.dart

class FundCategory {
  final String id;
  final String name;
  final String icon; // emoji

  const FundCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

const List<FundCategory> fundCategories = [
  FundCategory(id: "travel", name: "Đi chơi", icon: "Airplane"),
  FundCategory(id: "food", name: "Ăn uống", icon: "Noodles"),
  FundCategory(id: "party", name: "Tiệc tùng", icon: "Party Popper"),
  FundCategory(id: "rent", name: "Tiền nhà", icon: "House"),
  FundCategory(id: "shopping", name: "Mua sắm", icon: "Shopping Bags"),
  FundCategory(id: "coffee", name: "Café / Trà sữa", icon: "Hot Beverage"),
  FundCategory(id: "game", name: "Game / Giải trí", icon: "Video Game"),
  FundCategory(id: "gift", name: "Quà tặng", icon: "Wrapped Gift"),
  FundCategory(id: "health", name: "Gym / Y tế", icon: "Flexed Biceps"),
  FundCategory(id: "pet", name: "Thú cưng", icon: "Dog"),
  FundCategory(id: "car", name: "Xăng xe / Gara", icon: "Automobile"),
  FundCategory(id: "study", name: "Học phí", icon: "Books"),
  FundCategory(id: "internet", name: "Internet", icon: "Globe"),
  FundCategory(id: "electric", name: "Điện", icon: "Electric Plug"),
  FundCategory(id: "water", name: "Nước", icon: "Droplet"),
  FundCategory(id: "cinema", name: "Xem phim", icon: "Clapper Board"),
  FundCategory(id: "work", name: "Công việc", icon: "Briefcase"),
  FundCategory(id: "phone", name: "Điện thoại", icon: "Mobile Phone"),
  FundCategory(id: "beauty", name: "Làm đẹp", icon: "Nail Polish"),
  FundCategory(id: "baby", name: "Em bé", icon: "Baby Bottle"),
  FundCategory(id: "other", name: "Khác", icon: "Package"),
];

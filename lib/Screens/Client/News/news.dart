import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  int tabIndex = 0; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "🏠 HousePal",
              style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Text(
              "Trợ lý Ngôi nhà Chung",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),

      // BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bảng tin Chung",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Thông tin & Ghi chú",
                style: TextStyle(fontSize: 13, color: Colors.grey)),

            const SizedBox(height: 16),

            // tab selector
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => tabIndex = 0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: tabIndex == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Ghi chú",
                          style: TextStyle(
                            fontWeight:
                                tabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => tabIndex = 1),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: tabIndex == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Mua sắm (4)",
                          style: TextStyle(
                            fontWeight:
                                tabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // button add note
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "+  Thêm Ghi chú mới",
                style: TextStyle(color: Colors.white, fontSize: 16), // 🔥 CHỮ MÀU TRẮNG
              ),
            ),

            const SizedBox(height: 20),

            // content switch
            tabIndex == 0 ? _buildNotesUI() : _buildShoppingUI(),
          ],
        ),
      ),
    );
  }

  //ghi chú
  Widget _buildNotesUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Ghim (2)",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),

        const SizedBox(height: 12),

        _noteCard(
          icon: Icons.wifi,
          title: "Mật khẩu Wifi",
          content: "ID: AHIHI\nPassword: ahihi123@",
          color: Colors.blue[50],
        ),

        const SizedBox(height: 12),

        _noteCard(
          icon: Icons.phone,
          title: "Liên hệ chủ nhà",
          content: "Anh Minh: 0982857979\n(Có việc gì liên hệ trước 8PM)",
          color: Colors.green[50],
        ),

        const SizedBox(height: 20),
        Text("Ghi chú khác",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),

        const SizedBox(height: 12),

        _noteCard(
          icon: Icons.note_alt,
          title: "Quy định Chung",
          content:
              "- Không ở sau 10PM\n- Đóng cửa khi ra ngoài\n- Tắt điện khi không có người",
          color: Colors.purple[50],
        ),

        const SizedBox(height: 12),

        _noteCard(
          icon: Icons.build,
          title: "Lịch Sửa chữa",
          content: "Thợ điện sửa công tắc phòng khách\nThứ 7, 18/11 lúc 2PM",
          color: Colors.orange[50],
        ),
      ],
    );
  }

  Widget _noteCard({
    required IconData icon,
    required String title,
    required String content,
    Color? color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.push_pin_outlined, color: Colors.purple),
            ],
          ),
          SizedBox(height: 10),
          Text(content, style: TextStyle(fontSize: 14, height: 1.3)),
        ],
      ),
    );
  }

  //mua sắm
  Widget _buildShoppingUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Cần mua (4)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 12),

        _shoppingItem("Giấy vệ sinh (12 cuộn)", "Chi • 15/11"),
        _shoppingItem("Nước rửa bát Sunlight", "Bình • 15/11"),
        _shoppingItem("Túi rác (loại lớn)", "Anh Nguyễn • 14/11"),
        _shoppingItem("Dầu gội Clear", "Em • 14/11"),

        const SizedBox(height: 25),
        Text("Đã mua (1)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 12),

        _shoppingItem("Nước lau sàn", "Đăng • 13/11", purchased: true),
      ],
    );
  }

  Widget _shoppingItem(String name, String info, {bool purchased = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: purchased ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: purchased ? Colors.green : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Checkbox(value: purchased, onChanged: (_) {}),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(info, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

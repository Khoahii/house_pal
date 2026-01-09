import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:house_pal/models/user/app_user.dart';
import 'package:house_pal/models/fund/fund.dart';
import 'package:house_pal/services/fund/fund_service.dart';
import 'package:house_pal/services/notify/snack_bar_service.dart';
import 'package:house_pal/ultils/fund/fund_category.dart';

class CreateOrEditFundBottomSheet extends StatefulWidget {
  final Fund? fund;

  const CreateOrEditFundBottomSheet({super.key, this.fund});

  bool get isEdit => fund != null;

  @override
  State<CreateOrEditFundBottomSheet> createState() =>
      _CreateOrEditFundBottomSheetState();
}

class _CreateOrEditFundBottomSheetState
    extends State<CreateOrEditFundBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  FundCategory? _selectedCategory;
  final Set<DocumentReference> _selectedMembers = {};

  bool _isLoading = false;
  List<AppUser> _roomMembers = [];
  DocumentReference? _currentRoomRef;

  final FundService _fundService = FundService();

  @override
  void initState() {
    super.initState();
    _loadRoomAndMembers();

    if (widget.isEdit) {
      final fund = widget.fund!;

      _nameController.text = fund.name;

      _selectedCategory = fundCategories.firstWhere((c) => c.id == fund.iconId);

      _selectedMembers.addAll(fund.members);
    }
  }

  Future<void> _loadRoomAndMembers() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final roomRef = userSnap['roomId'] as DocumentReference?;
    if (roomRef == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final roomSnap = await roomRef.get();
    final memberRefs = List<DocumentReference>.from(roomSnap['members'] ?? []);

    // Lấy tất cả snapshot của các member refs
    final memberSnapshots = await Future.wait(
      memberRefs.map((ref) => ref.get()),
    );

    // Tạo map để lookup nhanh theo id
    final Map<String, DocumentSnapshot> snapById = {
      for (final s in memberSnapshots) s.id: s,
    };

    // Chuyển thành AppUser và lọc bỏ admin
    final members = memberSnapshots
        .map((snap) => AppUser.fromFirestore(snap))
        .where((u) => (u.role) != 'admin')
        .toList();

    // Lọc memberRefs tương ứng với users không phải admin
    final filteredMemberRefs = memberRefs.where((ref) {
      final snap = snapById[ref.id];
      if (snap == null) {
        return false; // phòng hợp lệ nhưng không tìm thấy user -> bỏ
      }
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final role = (data['role'] ?? '').toString();
      return role != 'admin';
    }).toList();

    setState(() {
      _roomMembers = members;
      _currentRoomRef = roomRef;

      // 🔥 SỬA TẠI ĐÂY:
      // Nếu không phải là chế độ Edit, thì mới mặc định chọn tất cả thành viên trong phòng
      if (!widget.isEdit) {
        _selectedMembers.clear();
        _selectedMembers.addAll(filteredMemberRefs);
      } else {
        // Nếu là chế độ Edit, _selectedMembers ĐÃ được khởi tạo trong initState
        // Chúng ta không gọi addAll(filteredMemberRefs) ở đây nữa để tránh chọn thừa người
      }
    });
  }

  Future<void> _submitFund() async {
    if (!_formKey.currentState!.validate() ||
        _selectedCategory == null ||
        _currentRoomRef == null ||
        _selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isEdit) {
        await _fundService.updateFund(
          fundId: widget.fund!.id,
          name: _nameController.text.trim(),
          iconId: _selectedCategory!.id,
          iconEmoji: _selectedCategory!.icon,
          members: _selectedMembers.toList(),
        );

        if (mounted) {
          SnackBarService.showSuccess(context, "Cập nhật quỹ thành công!");
        }
      } else {
        await _fundService.createFund(
          name: _nameController.text.trim(),
          iconId: _selectedCategory!.id,
          iconEmoji: _selectedCategory!.icon,
          roomRef: _currentRoomRef!,
          memberRefs: _selectedMembers.toList(),
        );

        if (mounted) {
          SnackBarService.showSuccess(context, "Đã tạo quỹ mới thành công!");
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, "Đã xảy ra lỗi: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(widget.isEdit ? "Chỉnh sửa quỹ" : "Tạo quỹ mới"),

              const SizedBox(height: 24),

              // Tên quỹ
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: "Tên quỹ",
                  hintText: "Ví dụ: Du lịch Đà Lạt 30/4",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wallet),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Vui lòng nhập tên quỹ";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Chọn biểu tượng quỹ
              const Text(
                "Chọn biểu tượng quỹ",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // GridView có chiều cao cố định, scroll độc lập
              SizedBox(
                height: 200,
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: fundCategories.length,
                  itemBuilder: (context, index) {
                    final category = fundCategories[index];
                    debugPrint("cate: $category");
                    final isSelected = _selectedCategory?.id == category.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isSelected ? 0.25 : 0.08,
                              ),
                              blurRadius: isSelected ? 16 : 8,
                              offset: Offset(0, isSelected ? 8 : 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category.icon,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Danh sách thành viên tham gia
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Thành viên tham gia",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "${_selectedMembers.length}/${_roomMembers.length}",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_roomMembers.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _roomMembers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final user = _roomMembers[i];
                    final userRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid);
                    final isChecked = _selectedMembers.contains(userRef);

                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : "U",
                              )
                            : null,
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(user.email),
                      value: isChecked,
                      activeColor: const Color(0xFF4F46E5),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedMembers.add(userRef);
                          } else {
                            _selectedMembers.remove(userRef);
                          }
                        });
                      },
                    );
                  },
                ),

              const SizedBox(height: 32),

              // Nút Tạo quỹ
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitFund,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(widget.isEdit ? "Lưu thay đổi" : "Tạo quỹ"),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

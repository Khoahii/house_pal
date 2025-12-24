import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/fund.dart';
class FundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Tạo quỹ mới + tạo luôn fund_members cho tất cả thành viên được chọn
  Future<Fund> createFund({
    required String name,
    required String iconId,
    required String iconEmoji,
    required DocumentReference roomRef,
    required List<DocumentReference> memberRefs, // đã chọn
  }) async {
    final creatorRef = _firestore.collection('users').doc(currentUserId);
    final fundRef = _firestore.collection('funds').doc();

    final Fund newFund = Fund(
      id: fundRef.id,
      name: name,
      iconId: iconId,
      iconEmoji: iconEmoji,
      roomId: roomRef,
      creatorId: creatorRef,
      members: memberRefs,
      totalSpent: 0,
      createdAt: DateTime.now(),
    );

    // Batch write: tạo fund + tạo fund_members cho từng người
    final batch = _firestore.batch();

    // 1. Tạo document fund
    batch.set(fundRef, newFund.toFirestore());

    // 2. Tạo fund_members cho từng thành viên
    for (final memberRef in memberRefs) {
      final memberDoc = await memberRef.get();
      final userData = memberDoc.data() as Map<String, dynamic>;

      final docId = "${fundRef.id}_${memberRef.id}";
      final fundMemberRef = _firestore.collection('fund_members').doc(docId);

      batch.set(fundMemberRef, {
        'fundId': fundRef.id,
        'fundName': name,
        'userId': memberRef.id,
        'userName': userData['name'] ?? 'Unknown',
        'userAvatar': userData['avatarUrl'],
        'totalPaid': 0,
        'totalOwed': 0,
        'balance': 0,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // Trả về fund đã tạo (có id thật)
    final doc = await fundRef.get();
    return Fund.fromFirestore(doc);
  }

  //- Cập nhật quỹ
  Future<void> updateFund({
    required String fundId,
    required String name,
    required String iconId,
    required String iconEmoji,
    required List<DocumentReference> members,
  }) async {
    final batch = _firestore.batch();
    final fundRef = _firestore.collection('funds').doc(fundId);

    // 1. Lấy dữ liệu cũ để so sánh thành viên
    final oldDoc = await fundRef.get();
    final List<DocumentReference> oldMembers = List<DocumentReference>.from(
      oldDoc['members'] ?? [],
    );

    // 2. Cập nhật thông tin cơ bản của quỹ
    batch.update(fundRef, {
      'name': name,
      'iconId': iconId,
      'iconEmoji': iconEmoji,
      'members': members,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Xử lý các thành viên MỚI thêm vào (chưa có trong oldMembers)
    final newAdditions = members
        .where((m) => !oldMembers.any((old) => old.id == m.id))
        .toList();

    for (final memberRef in newAdditions) {
      final memberDoc = await memberRef.get();
      final userData = memberDoc.data() as Map<String, dynamic>;
      final docId = "${fundId}_${memberRef.id}";
      final fundMemberRef = _firestore.collection('fund_members').doc(docId);

      batch.set(fundMemberRef, {
        'fundId': fundId,
        'fundName': name,
        'userId': memberRef.id,
        'userName': userData['name'] ?? 'Unknown',
        'userAvatar': userData['avatarUrl'],
        'totalPaid': 0,
        'totalOwed': 0,
        'balance': 0,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    // 4. (Tùy chọn) Xóa các thành viên bị LOẠI khỏi quỹ
    final removals = oldMembers
        .where((old) => !members.any((m) => m.id == old.id))
        .toList();
    for (final memberRef in removals) {
      final docId = "${fundId}_${memberRef.id}";
      batch.delete(_firestore.collection('fund_members').doc(docId));
    }

    // 5. Cập nhật lại fundName cho tất cả fund_members hiện tại (nếu tên quỹ đổi)
    if (oldDoc['name'] != name) {
      final membersSnap = await _firestore
          .collection('fund_members')
          .where('fundId', isEqualTo: fundId)
          .get();
      for (var doc in membersSnap.docs) {
        batch.update(doc.reference, {'fundName': name});
      }
    }

    await batch.commit();
  }

  // Lấy stream tất cả quỹ mà user hiện tại đang tham gia (dùng trong MainFundScreen)
  Stream<List<Fund>> getMyFundsStream() {
    final userRef = _firestore.collection('users').doc(currentUserId);

    return _firestore
        .collection('funds')
        .where('members', arrayContains: userRef)
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          var funds = snapshot.docs.map(Fund.fromFirestore).toList();

          // --- Bổ sung việc sắp xếp thủ công bằng Dart ---
          // Sắp xếp giảm dần theo thời gian tạo (createdAt)
          funds.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return funds;
        });
  }

  // Lấy tổng dư, cần thu, cần trả từ fund_members (siêu nhanh, realtime)
  Stream<Map<String, int>> getFundSummaryStream() {
    return _firestore
        .collection('fund_members')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          int totalBalance = 0;
          int totalToCollect = 0;
          int totalToPay = 0;

          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;

            // Lấy balance an toàn, chuyển về int
            final dynamic raw = data['balance'];
            int balance;
            if (raw is int) {
              balance = raw;
            } else if (raw is double) {
              balance = raw.toInt();
            } else if (raw is num) {
              balance = raw.toInt();
            } else {
              // nếu là String hoặc null -> thử parse, fallback 0
              balance = int.tryParse(raw?.toString() ?? '') ?? 0;
            }

            totalBalance += balance;
            if (balance > 0) {
              totalToCollect += balance; // mình được nhận lại
            } else if (balance < 0) {
              totalToPay += balance.abs(); // mình phải trả
            }
          }

          return {
            'totalBalance': totalBalance,
            'totalToCollect': totalToCollect,
            'totalToPay': totalToPay,
          };
        });
  }

  // Lấy thông tin tài chính cá nhân trong 1 quỹ cụ thể
  Stream<Map<String, dynamic>?> getMyStatusInFund(String fundId) {
    return _firestore
        .collection('fund_members')
        .doc("${fundId}_$currentUserId")
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  // Xóa quỹ (chỉ creator hoặc admin/room_leader mới được)
  Future<void> deleteFund(String fundId, String creatorId) async {
    final userDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    final userRole = userDoc['role'] as String;

    final isAdminOrLeader = userRole == 'admin' || userRole == 'room_leader';
    final isCreator = creatorId == currentUserId;

    if (!isAdminOrLeader && !isCreator) {
      throw "Bạn không có quyền xóa quỹ này";
    }

    final batch = _firestore.batch();

    // Xóa document fund
    final fundRef = _firestore.collection('funds').doc(fundId);
    batch.delete(fundRef);

    // Xóa hết fund_members liên quan
    final membersSnap = await _firestore
        .collection('fund_members')
        .where('fundId', isEqualTo: fundId)
        .get();

    for (final doc in membersSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Xác nhận thanh toán giữa 2 người
  Future<void> settleDebt({
    required String fundId,
    required String fromUserId, // Người nợ
    required String toUserId, // Người nhận
    required int amount,
  }) async {
    final fromMemberRef = _firestore
        .collection('fund_members')
        .doc("${fundId}_$fromUserId");
    final toMemberRef = _firestore
        .collection('fund_members')
        .doc("${fundId}_$toUserId");

    await _firestore.runTransaction((transaction) async {
      final fromSnap = await transaction.get(fromMemberRef);
      final toSnap = await transaction.get(toMemberRef);

      if (!fromSnap.exists || !toSnap.exists) return;

      // Tính toán lại balance mới
      // Người nợ: Tăng totalPaid lên (xem như họ vừa chi một khoản bằng khoản nợ)
      int currentFromPaid = (fromSnap.data()?['totalPaid'] ?? 0).toInt();
      int currentFromBalance = (fromSnap.data()?['balance'] ?? 0).toInt();

      // Người nhận: Giảm totalPaid xuống (vì họ đã nhận lại tiền mặt)
      // Hoặc đơn giản là điều chỉnh trực tiếp vào balance
      int currentToBalance = (toSnap.data()?['balance'] ?? 0).toInt();

      //- tăng totalPaid (xem như họ vừa chi một khoản bằng khoản nợ) và tăng balance (hiện đang âm sao cho về 0)
      transaction.update(fromMemberRef, {
        'totalPaid': currentFromPaid + amount,
        'balance': currentFromBalance + amount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      transaction.update(toMemberRef, {
        // Giảm balance của người nhận vì họ đã thu tiền về tay
        'balance': currentToBalance - amount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }
}

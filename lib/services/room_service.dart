import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // 1. Tạo phòng mới (chỉ leader hoặc admin mới được)
  Future<Room> createRoom(String roomName) async {
    final roomRef = _firestore.collection('rooms').doc();
    final userRef = _firestore.collection('users').doc(currentUserId);

    await roomRef.set({
      'name': roomName,
      'code': _generateRoomCode(),
      'members': [userRef],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await userRef.update({
      'role': 'room_leader',
      'roomId': roomRef,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final doc = await roomRef.get();
    return Room.fromFirestore(doc);
  }

  // Sinh mã code ngẫu nhiên 8 ký tự (A-Z0-9)
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      8,
      (i) => chars[(random + i * 31) % chars.length],
    ).join();
  }

  // 2. Join phòng bằng mã code
  Future<Room?> joinRoomByCode(String code) async {
    code = code.trim().toUpperCase();

    final query = await _firestore
        .collection('rooms')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw "Mã phòng không tồn tại!";
    }

    final roomRef = query.docs.first.reference;
    final members = List<DocumentReference>.from(query.docs.first['members']);
    final userRef = _firestore.collection('users').doc(currentUserId);

    if (members.contains(userRef)) {
      throw "Bạn đã ở trong phòng này rồi!";
    }

    await roomRef.update({
      'members': FieldValue.arrayUnion([userRef]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await userRef.update({
      'roomId': roomRef,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final doc = await roomRef.get();
    return Room.fromFirestore(doc);
  }

  // 3. Rời phòng - ✅ SỬ DỤNG BATCH ĐỂ ĐẢM BẢO ATOMIC
  Future<void> leaveRoom() async {
    final userDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    final roomRef = userDoc['roomId'] as DocumentReference?;

    if (roomRef == null) {
      throw "Bạn chưa tham gia phòng nào!";
    }

    final userRef = _firestore.collection('users').doc(currentUserId);
    final batch = _firestore.batch();

    // ✅ BƯỚC 1: Core Logic (2 cập nhật Atomic)
    batch.update(roomRef, {
      'members': FieldValue.arrayRemove([userRef]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {
      'roomId': null,
      if (userDoc['role'] == 'room_leader') 'role': 'member',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ✅ BƯỚC 2: Xử lý Tasks - xóa khỏi rotationOrder
    await _cleanupTasksOnLeave(batch, roomRef);

    // ✅ BƯỚC 3: Xử lý Funds - soft delete từ fund.members
    await _cleanupFundsOnLeave(batch, roomRef);

    // ✅ Commit tất cả cùng một lúc (ATOMIC)
    await batch.commit();
  }

  // ✅ Helper: Xử lý tasks khi user rời phòng
  Future<void> _cleanupTasksOnLeave(
    WriteBatch batch,
    DocumentReference roomRef,
  ) async {
    final tasksQs = await _firestore
        .collection('rooms')
        .doc(roomRef.id)
        .collection('tasks')
        .get();

    final leavingUserRef = _firestore.collection('users').doc(currentUserId);

    for (final taskDoc in tasksQs.docs) {
      final data = taskDoc.data();
      final assignMode = data['assignMode'] as String? ?? 'auto';
      final oldRotation = List<DocumentReference>.from(data['rotationOrder'] ?? []);
      final newRotation = oldRotation.where((ref) => ref.id != currentUserId).toList();
      final manualAssignedTo = data['manualAssignedTo'] is DocumentReference
          ? data['manualAssignedTo'] as DocumentReference
          : null;
      final rotationIndex = data['rotationIndex'] is int
          ? data['rotationIndex'] as int
          : null;

      final update = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};

      // Luôn xóa user khỏi rotationOrder nếu có
      if (newRotation.length != oldRotation.length) {
        update['rotationOrder'] = newRotation;
      }

      if (assignMode == 'auto') {
        _handleAutoTaskUpdate(update, newRotation, manualAssignedTo, rotationIndex, leavingUserRef);
      } else if (manualAssignedTo?.id == leavingUserRef.id) {
        // assignMode == 'manual' && người rời đang được giao → XÓA TASK
        batch.delete(taskDoc.reference);
        continue;
      }

      // Chỉ update nếu có thay đổi (ngoài updatedAt)
      if (update.length > 1) {
        batch.update(taskDoc.reference, update);
      }
    }
  }

  // ✅ Helper: Xử lý auto task update logic
  void _handleAutoTaskUpdate(
    Map<String, dynamic> update,
    List<DocumentReference> newRotation,
    DocumentReference? manualAssignedTo,
    int? rotationIndex,
    DocumentReference leavingUserRef,
  ) {
    final isLeavingAssigned = manualAssignedTo?.id == leavingUserRef.id;

    if (newRotation.isEmpty) {
      update['rotationIndex'] = null;
      update['manualAssignedTo'] = null;
    } else if (isLeavingAssigned) {
      // Giao lại cho người tiếp theo
      final newIndex = (rotationIndex ?? 0) % newRotation.length;
      update['rotationIndex'] = newIndex;
      update['manualAssignedTo'] = newRotation[newIndex];
    } else {
      // Cap index nếu cần
      if (rotationIndex != null && newRotation.isNotEmpty) {
        final cappedIndex = rotationIndex % newRotation.length;
        if (cappedIndex != rotationIndex) {
          update['rotationIndex'] = cappedIndex;
        }
      }
      if (newRotation.isEmpty) {
        update['rotationIndex'] = null;
        update['manualAssignedTo'] = null;
      }
    }
  }

  // ✅ Helper: Xóa user khỏi members của tất cả funds
  Future<void> _cleanupFundsOnLeave(
    WriteBatch batch,
    DocumentReference roomRef,
  ) async {
    final fundsQs = await _firestore
        .collection('funds')
        .where('roomId', isEqualTo: roomRef)
        .get();

    for (final fundDoc in fundsQs.docs) {
      final members = List<DocumentReference>.from(fundDoc['members'] ?? []);
      final newMembers =
          members.where((ref) => ref.id != currentUserId).toList();

      if (newMembers.length != members.length) {
        batch.update(fundDoc.reference, {
          'members': newMembers,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final fundMemberRef = _firestore.collection('fund_members')
            .doc('${fundDoc.id}_$currentUserId');

        batch.update(fundMemberRef, {
          'status': 'left',
          'leftAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // 4. Lấy phòng hiện tại của user
  Stream<Room?> get currentRoomStream {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((userDoc) async {
          final roomRef = userDoc['roomId'] as DocumentReference?;
          if (roomRef == null) return null;
          final roomSnap = await roomRef.get();
          return roomSnap.exists ? Room.fromFirestore(roomSnap) : null;
        });
  }

  // 5. Lấy danh sách tất cả phòng
  Stream<List<Room>> get allRoomsStream {
    return _firestore.collection('rooms').snapshots().map(
        (snapshot) => snapshot.docs.map(Room.fromFirestore).toList());
  }
}

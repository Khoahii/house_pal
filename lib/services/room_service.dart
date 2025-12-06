import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // 1. Tạo phòng mới (chỉ leader hoặc admin mới được)
  Future<Room> createRoom(String roomName) async {
    final roomRef = _firestore.collection('rooms').doc();

    final String code = _generateRoomCode();

    await roomRef.set({
      'name': roomName,
      'code': code,
      'members': [_firestore.collection('users').doc(currentUserId)],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Tự động gán mình làm room_leader
    await _firestore.collection('users').doc(currentUserId).update({
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
    final code = List.generate(
      8,
      (i) => chars[(random + i * 31) % chars.length],
    ).join();
    return code;
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

    final roomDoc = query.docs.first; //- lấy ra phòng để check 
    final roomRef = roomDoc.reference;
    final members = List<DocumentReference>.from(roomDoc['members']);

    // Kiểm tra đã ở trong phòng chưa
    final userRef = _firestore.collection('users').doc(currentUserId);
    if (members.contains(userRef)) {
      throw "Bạn đã ở trong phòng này rồi!";
    }

    // Thêm thành viên vào phòng
    await roomRef.update({
      'members': FieldValue.arrayUnion([userRef]),
    });

    // Cập nhật user: gán roomId + role member (nếu chưa phải leader/admin)
    await _firestore.collection('users').doc(currentUserId).update({
      'roomId': roomRef,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return Room.fromFirestore(roomDoc);
  }

  // 3. Rời phòng
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

    // Xóa user khỏi mảng members
    await roomRef.update({
      'members': FieldValue.arrayRemove([userRef]),
    });

    // Cập nhật lại user
    await userRef.update({
      'roomId': null,
      // Nếu là room_leader → đổi về member (trừ admin)
      if (userDoc['role'] == 'room_leader') 'role': 'member',
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  // 5. Lấy danh sách tất cả phòng (nếu cần quản lý admin)
  Stream<List<Room>> get allRoomsStream {
    return _firestore.collection('rooms').snapshots().map((snapshot) {
      return snapshot.docs.map(Room.fromFirestore).toList();
    });
  }
}

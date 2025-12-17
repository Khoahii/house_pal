import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class RoleManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ADMIN: lấy tất cả users
  Stream<List<AppUser>> getAllUsers() {
    return _firestore.collection('users').snapshots().map(
          (snapshot) =>
              snapshot.docs.map(AppUser.fromFirestore).toList(),
        );
  }

  /// ROOM LEADER: lấy users trong phòng (trừ admin)
  Stream<List<AppUser>> getUsersInRoom(DocumentReference roomRef) {
    return _firestore
        .collection('users')
        .where('roomId', isEqualTo: roomRef)
        .where('role', isNotEqualTo: 'admin')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AppUser.fromFirestore).toList(),
        );
  }
}

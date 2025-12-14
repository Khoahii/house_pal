import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final String role; // member, room_leader, admin
  final DocumentReference? roomId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    required this.role,
    this.roomId,
    required this.createdAt,
    required this.updatedAt,
  });
  bool get canCreateTask {
  return role == 'admin' || role == 'room_leader';
}
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'],
      phone: data['phone'],
      role: data['role'] ?? 'member',
      roomId: data['roomId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (phone != null) 'phone': phone,
      'role': role,
      if (roomId != null) 'roomId': roomId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }


}

// lib/models/fund.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Fund {
  final String id;
  final String name;
  final String iconId; // ví dụ: "travel"
  final String iconEmoji; // lưu luôn emoji để hiển thị nhanh
  final DocumentReference roomId;
  final DocumentReference creatorId;
  final List<DocumentReference> members;
  final int totalSpent;
  final DateTime createdAt;

  Fund({
    required this.id,
    required this.name,
    required this.iconId,
    required this.iconEmoji,
    required this.roomId,
    required this.creatorId,
    required this.members,
    this.totalSpent = 0,
    required this.createdAt,
  });

  factory Fund.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Fund(
      id: doc.id,
      name: data['name'] ?? '',
      iconId: data['iconId'] ?? 'other',
      iconEmoji: data['iconEmoji'] ?? 'Package',
      roomId: data['roomId'],
      creatorId: data['creatorId'],
      members: List<DocumentReference>.from(data['members'] ?? []),
      totalSpent: data['totalSpent'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'iconId': iconId,
      'iconEmoji': iconEmoji,
      'roomId': roomId,
      'creatorId': creatorId,
      'members': members,
      'totalSpent': totalSpent,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

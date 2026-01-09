import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id;
  final String title;
  final String? note;

  final String fundId;
  final String fundName;

  final String? linkedExpenseId;

  final DocumentReference createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingItem({
    required this.id,
    required this.title,
    this.note,
    required this.fundId,
    required this.fundName,
    this.linkedExpenseId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Timestamp? ca = data['createdAt'];
    Timestamp? ua = data['updatedAt'];

    return ShoppingItem(
      id: doc.id,
      title: data['title'] ?? '',
      note: data['note'],
      fundId: data['fundId'] ?? '',
      fundName: data['fundName'] ?? '',
      linkedExpenseId: data['linkedExpenseId'],
      createdBy: data['createdBy'],
      createdAt: (ca ?? Timestamp.now()).toDate(),
      updatedAt: (ua ?? Timestamp.now()).toDate(),
    );
  }
}

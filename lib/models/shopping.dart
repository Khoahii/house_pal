import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id;
  final String name;
  final bool purchased;
  final String assignedName;
  final DateTime createdAt;
  final DateTime? purchasedAt;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.purchased,
    required this.assignedName,
    required this.createdAt,
    this.purchasedAt,
  });

  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id,
      name: data['name'],
      purchased: data['purchased'] ?? false,
      assignedName: data['assignedTo']?['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      purchasedAt: data['purchasedAt'] != null
          ? (data['purchasedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

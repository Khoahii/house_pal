import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String title;
  final int amount;
  final DocumentReference paidBy;
  final DateTime date;
  final String iconId;
  final String iconEmoji;
  final String splitType;
  final Map<String, int> splitDetail; // 🔥 userId -> amount
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.date,
    required this.iconId,
    required this.iconEmoji,
    required this.splitType,
    required this.splitDetail,
    required this.createdAt,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Expense(
      id: doc.id,
      title: data['title'],
      amount: data['amount'],
      paidBy: data['paidBy'],
      date: (data['date'] as Timestamp).toDate(),
      iconId: data['iconId'],
      iconEmoji: data['iconEmoji'],
      splitType: data['splitType'],
      splitDetail: Map<String, int>.from(data['splitDetail'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> createExpense({
    required String fundId,
    required String title,
    required int amount,
    required DocumentReference paidBy,
    required DateTime date,
    required String iconId,
    required String iconEmoji,
    required String splitType,
    required Map<DocumentReference, int> splitDetail,
  }) async {
    final ref = _firestore
        .collection('funds')
        .doc(fundId)
        .collection('expenses')
        .doc();

    await ref.set({
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'date': Timestamp.fromDate(date),
      'iconId': iconId,
      'iconEmoji': iconEmoji,
      'splitType': splitType,
      'splitDetail': splitDetail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateExpense({
    required String fundId,
    required String expenseId,
    required String title,
    required int amount,
    required DocumentReference paidBy,
    required DateTime date,
    required String iconId,
    required String iconEmoji,
    required String splitType,
    required Map<DocumentReference, int> splitDetail,
  }) async {
    final ref = _firestore
        .collection('funds')
        .doc(fundId)
        .collection('expenses')
        .doc(expenseId);

    await ref.update({
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'date': Timestamp.fromDate(date),
      'iconId': iconId,
      'iconEmoji': iconEmoji,
      'splitType': splitType,
      'splitDetail': splitDetail,
    });
  }
}

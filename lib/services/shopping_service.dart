import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shopping_item.dart';

class ShoppingService {
  final _firestore = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<ShoppingItem>> shoppingStream(DocumentReference roomRef) {
    return roomRef
        .collection('shopping_items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ShoppingItem.fromFirestore(d)).toList());
  }

  Future<void> addItem({
    required DocumentReference roomRef,
    required String title,
    String? note,
    required String fundId,
    required String fundName,
  }) {
    return roomRef.collection('shopping_items').add({
      'title': title,
      'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      'fundId': fundId,
      'fundName': fundName,
      'linkedExpenseId': null,
      'createdBy': _firestore.collection('users').doc(_uid),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> linkExpense({
    required DocumentReference roomRef,
    required String itemId,
    required String expenseId,
  }) {
    return roomRef.collection('shopping_items').doc(itemId).update({
      'linkedExpenseId': expenseId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

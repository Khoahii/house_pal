import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping.dart';

class ShoppingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =======================
  /// STREAM LIST BY ROOM
  /// =======================
  Stream<QuerySnapshot<Map<String, dynamic>>> getByRoom() {
    return FirebaseFirestore.instance
      .collection('shoppings')
      // .where('roomId', isEqualTo: roomRef)
      // .orderBy('createdAt', descending: true) // ✅ CHỈ 1 orderBy
      .snapshots();
  }

  /// =======================
  /// ADD ITEM
  /// =======================
  Future<void> addItem({
    // required DocumentReference roomRef,
    required String name,
    required String assignedName,
  }) async {
    await _firestore.collection('shoppings').add({
      // 'roomId': roomRef,
      'name': name,
      'assignedTo': {
        'name': assignedName,
      },
      'purchased': false,
      'createdAt': FieldValue.serverTimestamp(),
      'purchasedAt': null,
    });
  }

  /// =======================
  /// TOGGLE PURCHASED
  /// =======================
  Future<void> togglePurchased(String itemId, bool purchased) async {
    await _firestore.collection('shoppings').doc(itemId).update({
      'purchased': purchased,
      'purchasedAt': purchased ? FieldValue.serverTimestamp() : null,
    });
  }

  /// =======================
  /// DELETE ITEM
  /// =======================
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('shoppings').doc(itemId).delete();
  }

  /// =======================
  /// UPDATE ITEM
  /// =======================
  Future<void> updateItem({
    required String itemId,
    required String name,
    required String assignedName,
  }) async {
    await _firestore.collection('shoppings').doc(itemId).update({
      'name': name,
      'assignedTo': {
        'name': assignedName,
      },
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bulletin.dart';

class BulletinService {
  final _firestore = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Bulletin>> bulletinsStream(DocumentReference roomRef) {
    return roomRef
        .collection('bulletins')
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Bulletin.fromFirestore(d)).toList());
  }

  Future<void> createBulletin({
    required DocumentReference roomRef,
    required String title,
    required String content,
    required String type,
    required String creatorName,
    String? creatorAvatar,
    bool isPinned = false,
  }) {
    return roomRef.collection('bulletins').add({
      'title': title,
      'content': content,
      'type': type,
      'isPinned': isPinned,
      'createdBy': _firestore.collection('users').doc(_uid),
      'creatorName': creatorName,
      'creatorAvatar': creatorAvatar,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> togglePin(DocumentReference bulletinRef, bool value) {
    return bulletinRef.update({
      'isPinned': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBulletin(DocumentReference bulletinRef) {
    return bulletinRef.delete();
  }
}

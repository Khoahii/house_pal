import 'package:cloud_firestore/cloud_firestore.dart';

class NoteService {
  // =======================
  // STREAM NOTE THEO PHÒNG
  // =======================
 Stream<QuerySnapshot<Map<String, dynamic>>> getNotes(
  DocumentReference<Map<String, dynamic>> roomRef,
  ) {
  return FirebaseFirestore.instance
      .collection('notes')
      // .where('roomId', isEqualTo: roomRef)
      .orderBy('createdAt', descending: true) // ✅ CHỈ 1 orderBy
      .snapshots();
  }



  // =======================
  // THÊM NOTE
  // =======================
  Future<void> addNote({
  required DocumentReference<Map<String, dynamic>> roomRef,
  required String title,
  required String content,
  required bool pinned,
}) async {
  await FirebaseFirestore.instance.collection('notes').add({
    'title': title,
    'content': content,
    'pinned': pinned,
    'roomId': roomRef, // 🔥 QUAN TRỌNG
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}


  // =======================
  // SỬA / GHIM NOTE
  // =======================
  Future<void> updateNote({
  required DocumentReference<Map<String, dynamic>> roomRef,
  required String noteId,
  required String title,
  required String content,
  required bool pinned,
}) async {
  await FirebaseFirestore.instance
      .collection('notes')
      .doc(noteId)
      .update({
    'title': title,
    'content': content,
    'pinned': pinned,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}


  // =======================
  // XOÁ NOTE
  // =======================
 Future<void> deleteNote({
  required DocumentReference<Map<String, dynamic>> roomRef,
  required String noteId,
}) async {
  await FirebaseFirestore.instance
      .collection('notes')
      .doc(noteId)
      .delete();
}
}

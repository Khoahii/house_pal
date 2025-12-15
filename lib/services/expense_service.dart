import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Thêm để sử dụng debugPrint (hoặc chỉ in ra console nếu bạn muốn)

class ExpenseService {
  final _firestore = FirebaseFirestore.instance;

  Future<String> createExpense({
    required String fundId,
    required String title,
    required int amount,
    required DocumentReference paidBy,
    required DateTime date,
    required String iconId,
    required String iconEmoji,
    required String splitType,
    required Map<String, int> splitDetail,
  }) async {
    //

    try {
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

      final snap = await ref.get();
      if (!snap.exists) {
        // Đây là kiểm tra bổ sung, nếu không thành công thì sẽ throw Exception.
        throw Exception(
          "Tạo expense thất bại: Document không tồn tại sau khi set.",
        );
      }

      return ref.id;
    } on FirebaseException catch (e) {
      // Bắt các lỗi cụ thể của Firebase
      debugPrint('Lỗi Firebase khi tạo expense: $e');
      throw Exception(
        "Lỗi dịch vụ: Không thể tạo chi phí. Vui lòng thử lại. (${e.code})",
      );
    } catch (e) {
      // Bắt các lỗi chung khác, bao gồm cả Exception đã throw ở trên
      debugPrint('Lỗi chung khi tạo expense: $e');
      // Tùy chọn: Log lỗi để debug
      if (e is Exception && e.toString().contains("Tạo expense thất bại")) {
        rethrow; // Ném lại Exception đã throw ở trên
      }
      throw Exception("Lỗi không xác định khi tạo chi phí.");
    }
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
    required Map<String, int> splitDetail,
  }) async {
    try {
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
    } on FirebaseException catch (e) {
      // Bắt các lỗi cụ thể của Firebase (ví dụ: PERMISSION_DENIED, NOT_FOUND)
      debugPrint('Lỗi Firebase khi cập nhật expense: $e');
      throw Exception(
        "Lỗi dịch vụ: Không thể cập nhật chi phí. Vui lòng thử lại. (${e.code})",
      );
    } catch (e) {
      // Bắt các lỗi chung khác
      debugPrint('Lỗi chung khi cập nhật expense: $e');
      throw Exception("Lỗi không xác định khi cập nhật chi phí.");
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:house_pal/models/expense.dart';
import 'package:house_pal/models/fund.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================
  // CREATE EXPENSE
  // =========================
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
    final fundRef = _firestore.collection('funds').doc(fundId);
    final expenseRef = fundRef.collection('expenses').doc();

    bool hasError = false;
    String? errorMessage;

    try {
      await _firestore.runTransaction((transaction) async {
        try {
          final Map<String, DocumentSnapshot<Map<String, dynamic>>>
          memberSnaps = {};

          for (final userId in splitDetail.keys) {
            final ref = _firestore
                .collection('fund_members')
                .doc('${fundId}_$userId');

            memberSnaps[userId] = await transaction.get(ref);
          }

          // 2.1 Create expense
          transaction.set(expenseRef, {
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

          // 2.2 Update fund
          transaction.update(fundRef, {
            'totalSpent': FieldValue.increment(amount),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // 2.3 Update fund members
          for (final entry in splitDetail.entries) {
            final userId = entry.key;
            final owed = entry.value;
            final snap = memberSnaps[userId]!;

            int totalPaid = 0;
            int totalOwed = 0;

            if (snap.exists) {
              final data = snap.data()!;
              totalPaid = (data['totalPaid'] as num?)?.toInt() ?? 0;
              totalOwed = (data['totalOwed'] as num?)?.toInt() ?? 0;
            }

            if (paidBy.id == userId) {
              totalPaid += amount;
            }
            totalOwed += owed;

            final ref = _firestore
                .collection('fund_members')
                .doc('${fundId}_$userId');

            final payload = {
              'fundId': fundId,
              'userId': userId,
              'totalPaid': totalPaid,
              'totalOwed': totalOwed,
              'balance': totalPaid - totalOwed,
              'lastUpdated': FieldValue.serverTimestamp(),
            };

            if (snap.exists) {
              transaction.update(ref, payload);
            } else {
              transaction.set(ref, {
                ...payload,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          }
        } catch (e, stack) {
          debugPrint('🔥 createExpense TRANSACTION ERROR: $e');
          debugPrint(stack.toString());
          hasError = true;
          errorMessage = 'Lỗi xử lý transaction';
          return;
        }
      });

      if (hasError) {
        throw Exception(errorMessage);
      }

      return expenseRef.id;
    } catch (e, stack) {
      debugPrint('🔥 createExpense FAILED: $e');
      debugPrint(stack.toString());
      throw Exception('Đã xảy ra lỗi khi tạo chi phí');
    }
  }


  // =========================
  // UPDATE EXPENSE
  // =========================
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
    final fundRef = _firestore.collection('funds').doc(fundId);
    final expenseRef = fundRef.collection('expenses').doc(expenseId);

    bool hasError = false;
    String? errorMessage;

    try {
      await _firestore.runTransaction((transaction) async {
        try {
          final oldSnap = await transaction.get(expenseRef);

          if (!oldSnap.exists) {
            hasError = true;
            errorMessage = 'Chi phí không tồn tại';
            return;
          }

          final oldData = oldSnap.data()!;
          final int oldAmount = oldData['amount'];
          final DocumentReference oldPaidBy = oldData['paidBy'];
          final Map<String, int> oldSplit = Map<String, int>.from(
            oldData['splitDetail'] ?? {},
          );

          // Rollback công nợ cũ
          for (final entry in oldSplit.entries) {
            final userId = entry.key;
            final owed = entry.value;

            final fundMemberRef = _firestore
                .collection('fund_members')
                .doc('${fundId}_$userId');

            final snap = await transaction.get(fundMemberRef);
            if (!snap.exists) {
              hasError = true;
              errorMessage = 'Fund member $userId không tồn tại';
              return;
            }

            final data = snap.data()!;
            int totalPaid = (data['totalPaid'] ?? 0);
            int totalOwed = (data['totalOwed'] ?? 0);

            if (oldPaidBy.id == userId) {
              totalPaid -= oldAmount;
            }
            totalOwed -= owed;

            transaction.update(fundMemberRef, {
              'totalPaid': totalPaid,
              'totalOwed': totalOwed,
              'balance': totalPaid - totalOwed,
            });
          }

          // Apply công nợ mới
          for (final entry in splitDetail.entries) {
            final userId = entry.key;
            final owed = entry.value;

            final fundMemberRef = _firestore
                .collection('fund_members')
                .doc('${fundId}_$userId');

            final snap = await transaction.get(fundMemberRef);
            if (!snap.exists) {
              hasError = true;
              errorMessage = 'Fund member $userId không tồn tại';
              return;
            }

            final data = snap.data()!;
            int totalPaid = (data['totalPaid'] ?? 0);
            int totalOwed = (data['totalOwed'] ?? 0);

            if (paidBy.id == userId) {
              totalPaid += amount;
            }
            totalOwed += owed;

            transaction.update(fundMemberRef, {
              'totalPaid': totalPaid,
              'totalOwed': totalOwed,
              'balance': totalPaid - totalOwed,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }

          final diff = amount - oldAmount;
          transaction.update(fundRef, {
            'totalSpent': FieldValue.increment(diff),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          transaction.update(expenseRef, {
            'title': title,
            'amount': amount,
            'paidBy': paidBy,
            'date': Timestamp.fromDate(date),
            'iconId': iconId,
            'iconEmoji': iconEmoji,
            'splitType': splitType,
            'splitDetail': splitDetail,
          });
        } catch (e, stack) {
          debugPrint('🔥 updateExpense TRANSACTION ERROR: $e');
          debugPrint(stack.toString());
          hasError = true;
          errorMessage = 'Lỗi xử lý cập nhật chi phí';
          return;
        }
      });

      if (hasError) {
        throw Exception(errorMessage);
      }
    } catch (e, stack) {
      debugPrint('🔥 updateExpense FAILED: $e');
      debugPrint(stack.toString());
      throw Exception('Không thể cập nhật chi phí. Vui lòng thử lại.');
    }
  }


  // =========================
  // GET EXPENSES
  // =========================
  Stream<List<Expense>> getFundExpenses(String fundId) {
    return _firestore
        .collection('funds')
        .doc(fundId)
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
          // Lấy danh sách Expense từ các document
          var expenses = snapshot.docs.map((doc) {
            return Expense.fromFirestore(doc);
          }).toList();

          // Sắp xếp bằng Dart: theo createdAt giảm dần (mới nhất trước)
          expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return expenses;
        });
  }

  // =========================
  // GET FUND DATA (để lắng nghe cập nhật totalSpent)
  // =========================
  Stream<Fund> getFundStream(String fundId) {
    return _firestore.collection('funds').doc(fundId).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('Fund not found');
      }
      // Giả định bạn đã có Fund.fromFirestore trong file model/fund.dart
      return Fund.fromFirestore(doc);
    });
  }
}

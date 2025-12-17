import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:house_pal/models/app_user.dart';
import 'package:house_pal/models/expense.dart';
import 'package:house_pal/models/fund.dart';
import 'package:house_pal/services/user_service.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // =========================
  // CHECK PERMISSION
  // =========================
  Future<bool> _canModifyExpense(Expense expense) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Người tạo
    if (expense.createdBy == uid) return true;

    // Admin / room_leader
    final AppUser? user = await _userService.getUserById(uid);
    if (user == null) return false;

    return user.role == 'admin' || user.role == 'room_leader';
  }

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
    final uid = FirebaseAuth.instance.currentUser!.uid;

    bool hasError = false;
    String? errorMessage;

    try {
      await _firestore.runTransaction((transaction) async {
        try {
          final Map<String, DocumentSnapshot<Map<String, dynamic>>>
          memberSnaps = {};

          // 🔹 READ ALL
          for (final userId in splitDetail.keys) {
            final ref = _firestore
                .collection('fund_members')
                .doc('${fundId}_$userId');
            memberSnaps[userId] = await transaction.get(ref);
          }

          // 🔹 CREATE EXPENSE
          transaction.set(expenseRef, {
            'title': title,
            'amount': amount,
            'paidBy': paidBy,
            'date': Timestamp.fromDate(date),
            'iconId': iconId,
            'iconEmoji': iconEmoji,
            'splitType': splitType,
            'splitDetail': splitDetail,
            'createdBy': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // 🔹 UPDATE FUND
          transaction.update(fundRef, {
            'totalSpent': FieldValue.increment(amount),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // 🔹 UPDATE FUND MEMBERS
          for (final entry in splitDetail.entries) {
            final userId = entry.key;
            final owed = entry.value;
            final snap = memberSnaps[userId]!;

            int totalPaid = 0;
            int totalOwed = 0;

            if (snap.exists) {
              final data = snap.data()!;
              totalPaid = (data['totalPaid'] ?? 0);
              totalOwed = (data['totalOwed'] ?? 0);
            }

            if (paidBy.id == userId) {
              totalPaid += amount;
            }
            totalOwed += owed;

            final ref = _firestore
                .collection('fund_members')
                .doc('${fundId}_$userId');

            transaction.update(ref, {
              'totalPaid': totalPaid,
              'totalOwed': totalOwed,
              'balance': totalPaid - totalOwed,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        } catch (e, stack) {
          debugPrint('🔥 createExpense TRANSACTION ERROR: $e');
          debugPrint(stack.toString());
          hasError = true;
          errorMessage = 'Lỗi xử lý tạo chi tiêu';
          return;
        }
      });

      if (hasError) throw Exception(errorMessage);
      return expenseRef.id;
    } catch (e, stack) {
      debugPrint('🔥 createExpense FAILED: $e');
      debugPrint(stack.toString());
      throw Exception('Không thể tạo chi tiêu');
    }
  }

  // =========================
  // UPDATE EXPENSE
  // =========================
  Future<void> updateExpense({
    required String fundId,
    required Expense expense,
    required String title,
    required int amount,
    required DocumentReference paidBy,
    required DateTime date,
    required String iconId,
    required String iconEmoji,
    required String splitType,
    required Map<String, int> splitDetail,
  }) async {
    if (!await _canModifyExpense(expense)) {
      throw Exception('NO_PERMISSION');
    }

    final fundRef = _firestore.collection('funds').doc(fundId);
    final expenseRef = fundRef.collection('expenses').doc(expense.id);

    try {
      await _firestore.runTransaction((transaction) async {

        /// gom toàn bộ userId liên quan (old + new)
        final Set<String> affectedUserIds = {
          ...expense.splitDetail.keys,
          ...splitDetail.keys,
        };

        final Map<String, DocumentSnapshot> memberSnaps = {};

        for (final userId in affectedUserIds) {
          final ref = _firestore
              .collection('fund_members')
              .doc('${fundId}_$userId');

          final snap = await transaction.get(ref);

          if (!snap.exists) {
            throw Exception('Fund member không tồn tại');
          }

          memberSnaps[userId] = snap;
        }

        final Map<DocumentReference, Map<String, dynamic>> updates = {};

        /// 🔹 ROLLBACK OLD EXPENSE
        for (final entry in expense.splitDetail.entries) {
          final userId = entry.key;
          final owed = entry.value;

          final snap = memberSnaps[userId]!;

          int totalPaid = (snap['totalPaid'] ?? 0);
          int totalOwed = (snap['totalOwed'] ?? 0);

          if (expense.paidBy.id == userId) {
            totalPaid -= expense.amount;
          }

          totalOwed -= owed;

          updates[snap.reference] = {
            'totalPaid': totalPaid,
            'totalOwed': totalOwed,
            'balance': totalPaid - totalOwed,
          };
        }

        /// 🔹 APPLY NEW EXPENSE
        for (final entry in splitDetail.entries) {
          final userId = entry.key;
          final owed = entry.value;

          final snap = memberSnaps[userId]!;

          int totalPaid =
              updates[snap.reference]?['totalPaid'] ?? (snap['totalPaid'] ?? 0);

          int totalOwed =
              updates[snap.reference]?['totalOwed'] ?? (snap['totalOwed'] ?? 0);

          if (paidBy.id == userId) {
            totalPaid += amount;
          }

          totalOwed += owed;

          updates[snap.reference] = {
            'totalPaid': totalPaid,
            'totalOwed': totalOwed,
            'balance': totalPaid - totalOwed,
            'lastUpdated': FieldValue.serverTimestamp(),
          };
        }

        for (final entry in updates.entries) {
          transaction.update(entry.key, entry.value);
        }

        transaction.update(fundRef, {
          'totalSpent': FieldValue.increment(amount - expense.amount),
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
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('🔥 updateExpense ERROR: $e');
      throw Exception('Không thể cập nhật chi tiêu');
    }
  }


  // =========================
  // DELETE EXPENSE
  // =========================
  Future<void> deleteExpense({
    required String fundId,
    required Expense expense,
  }) async {
    if (!await _canModifyExpense(expense)) {
      throw Exception('NO_PERMISSION');
    }

    final fundRef = _firestore.collection('funds').doc(fundId);
    final expenseRef = fundRef.collection('expenses').doc(expense.id);

    try {
      await _firestore.runTransaction((transaction) async {
        final Map<String, DocumentSnapshot> memberSnaps = {};

        for (final entry in expense.splitDetail.entries) {
          final userId = entry.key;

          final ref = _firestore
              .collection('fund_members')
              .doc('${fundId}_$userId');

          memberSnaps[userId] = await transaction.get(ref);
        }

        final Map<DocumentReference, Map<String, dynamic>> memberUpdates = {};

        for (final entry in expense.splitDetail.entries) {
          final userId = entry.key;
          final owed = entry.value;

          final snap = memberSnaps[userId]!;

          int totalPaid = (snap['totalPaid'] ?? 0);
          int totalOwed = (snap['totalOwed'] ?? 0);

          if (expense.paidBy.id == userId) {
            totalPaid -= expense.amount;
          }

          totalOwed -= owed;

          final ref = snap.reference;

          memberUpdates[ref] = {
            'totalPaid': totalPaid,
            'totalOwed': totalOwed,
            'balance': totalPaid - totalOwed,
          };
        }

        for (final entry in memberUpdates.entries) {
          transaction.update(entry.key, entry.value);
        }

        transaction.update(fundRef, {
          'totalSpent': FieldValue.increment(-expense.amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.delete(expenseRef);
      });
    } catch (e) {
      throw Exception('Không thể xóa chi tiêu');
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
  // FUND STREAM
  // =========================
  Stream<Fund> getFundStream(String fundId) {
    return _firestore.collection('funds').doc(fundId).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Fund not found');
      return Fund.fromFirestore(doc);
    });
  }
}

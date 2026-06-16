import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class FinanceProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  // Real-time calculation of totals for the UI cards
  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpenses => _transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get netProfit => totalIncome - totalExpenses;

  Future<void> fetchTransactions() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      _transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = await _db
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add(transaction.toMap());

      // Insert locally for instant UI feedback
      final newEntry = TransactionModel(
        id: docRef.id,
        category: transaction.category,
        amount: transaction.amount,
        date: transaction.date,
        note: transaction.note,
        isIncome: transaction.isIncome,
      );

      _transactions.insert(0, newEntry);
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding transaction: $e");
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toMap());

      int index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating transaction: $e");
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transactionId)
          .delete();

      _transactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting transaction: $e");
      rethrow;
    }
  }
}
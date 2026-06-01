import 'dart:async';
import 'package:flutter/material.dart';
import 'expense_model.dart';
import 'expense_service.dart';
import 'budget_service.dart';
import 'hive_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _service      = ExpenseService();
  final BudgetService  _budgetService = BudgetService();
  final HiveService    _hive         = HiveService();

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => _expenses;

  bool _loading = false;
  bool get loading => _loading;

  StreamSubscription? _subscription;

  // ─────────────────────────────────────────────────────────────────────────
  // LISTEN EXPENSES  (Hive-first → Firestore stream keeps it in sync)
  // ─────────────────────────────────────────────────────────────────────────
  void listenToExpenses(String userId) {
    _loading = true;
    notifyListeners();

    // 1️⃣  Load from Hive immediately (fast / works offline)
    final cached = _hive.getExpenses();
    if (cached.isNotEmpty) {
      _expenses = cached;
      _loading  = false;
      notifyListeners();
    }

    // 2️⃣  Subscribe to Firestore — keeps Hive in sync in the background
    _subscription?.cancel();
    _subscription = _service.getExpenses(userId).listen((data) async {
      _expenses = data;
      _loading  = false;
      notifyListeners();

      // Keep local cache up to date
      await _hive.saveAllExpenses(data);

      // Auto-update budget spent
      final totalSpent = _calculateTotalSpent();
      await _budgetService.updateSpent(userId, totalSpent);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADD  (dual-write: Hive + Firestore)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> addExpense(String userId, ExpenseModel expense) async {
    await _service.addExpense(userId, expense);
    // Hive cache is refreshed by the Firestore stream listener above
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE  (dual-write)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> deleteExpense(String userId, String expenseId) async {
    await _service.deleteExpense(userId, expenseId);
    await _hive.deleteExpense(expenseId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE  (dual-write)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> updateExpense(
    String userId,
    String expenseId,
    ExpenseModel expense,
  ) async {
    await _service.updateExpense(userId, expenseId, expense);
    await _hive.saveExpense(expense);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLEAR LOCAL CACHE  (called on logout)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> clearCache() async {
    await _hive.clearExpenses();
    _expenses = [];
    notifyListeners();
  }

  double _calculateTotalSpent() =>
      _expenses.fold(0.0, (sum, item) => sum + item.amount);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

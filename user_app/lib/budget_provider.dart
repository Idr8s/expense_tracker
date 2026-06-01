import 'package:flutter/material.dart';
import 'budget_model.dart';
import 'budget_service.dart';
import 'hive_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _service = BudgetService();
  final HiveService   _hive    = HiveService();

  BudgetModel? _budget;
  BudgetModel? get budget => _budget;

  // ─────────────────────────────────────────────────────────────────────────
  // LISTEN BUDGET  (Hive-first → Firestore keeps in sync)
  // ─────────────────────────────────────────────────────────────────────────
  void listenBudget(String userId) {
    // 1️⃣  Serve cached budget instantly
    final cached = _hive.getBudget();
    if (cached != null) {
      _budget = cached;
      notifyListeners();
    }

    // 2️⃣  Firestore stream keeps Hive in sync
    _service.getBudget(userId).listen((data) async {
      _budget = data;
      notifyListeners();
      if (data != null) await _hive.saveBudget(data);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE LIMIT  (called from dashboard "Edit Budget" dialog)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> updateLimit(String userId, double newLimit) async {
    await _service.updateLimit(userId, newLimit);
    // Hive is refreshed by the Firestore stream listener above
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLEAR LOCAL CACHE  (called on logout)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> clearCache() async {
    await _hive.clearBudget();
    _budget = null;
    notifyListeners();
  }
}

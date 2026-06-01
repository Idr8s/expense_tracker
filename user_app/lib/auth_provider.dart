import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'user_model.dart';
import 'budget_service.dart';
import 'budget_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService   _authService   = AuthService();
  final BudgetService _budgetService = BudgetService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? get currentUser => _authService.getCurrentUser();

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN UP  (now accepts budgetLimit from the signup screen)
  // ─────────────────────────────────────────────────────────────────────────
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
    required double budgetLimit,   // ← user sets this on signup
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userModel = await _authService.signup(
        name:     name,
        email:    email,
        password: password,
      );

      if (userModel != null) {
        await _initBudget(userModel.uid, budgetLimit);
      }

      return userModel;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────────────────────────────────
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final user = await _authService.login(email: email, password: password);

    if (user != null) {
      // Only create budget doc if it doesn't exist yet (safe default)
      await _initBudgetIfNeeded(user.uid);
    }

    _isLoading = false;
    notifyListeners();

    return user;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Called on signup — always creates a fresh budget with the user's limit.
  Future<void> _initBudget(String userId, double budgetLimit) async {
    await _budgetService.setBudget(
      userId,
      BudgetModel(
        id:       'current',
        category: 'Monthly',
        limit:    budgetLimit,
        spent:    0,
      ),
    );
  }

  /// Called on login — only creates a budget doc if one doesn't exist.
  Future<void> _initBudgetIfNeeded(String userId) async {
    final doc = await _budgetService.getBudgetDoc(userId);
    if (!doc.exists) {
      await _budgetService.setBudget(
        userId,
        BudgetModel(
          id:       'current',
          category: 'Monthly',
          limit:    50000,   // safe default for existing users without a doc
          spent:    0,
        ),
      );
    }
  }
}

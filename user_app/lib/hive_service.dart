import 'package:hive_flutter/hive_flutter.dart';
import 'expense_model.dart';
import 'budget_model.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// HiveService — local offline database (no code-gen required)
///
/// Architecture (dual-write):
///   • Every write goes to BOTH Hive (local) AND Firestore (cloud).
///   • On app start, Hive is read instantly for a fast first render.
///   • The Firestore real-time stream then keeps Hive in sync in the background.
///   • Result: the UI loads immediately even offline, and stays live when online.
/// ─────────────────────────────────────────────────────────────────────────────

class HiveService {
  static const String _expenseBoxName = 'expenses_box';
  static const String _budgetBoxName  = 'budget_box';

  // ── Initialise ──────────────────────────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_expenseBoxName);
    await Hive.openBox(_budgetBoxName);
  }

  // ── Lazy box accessors ───────────────────────────────────────────────────────
  Box get _expenseBox => Hive.box(_expenseBoxName);
  Box get _budgetBox  => Hive.box(_budgetBoxName);

  // ════════════════════════════════════════════════════════════════════════════
  // EXPENSE OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  /// Save (insert or overwrite) a single expense using its Firestore id as key.
  Future<void> saveExpense(ExpenseModel expense) async {
    await _expenseBox.put(expense.id, {
      'id':       expense.id,
      'title':    expense.title,
      'amount':   expense.amount,
      'category': expense.category,
      'date':     expense.date.millisecondsSinceEpoch,
      'note':     expense.note,
    });
  }

  /// Save a full list (replaces everything — used when Firestore stream fires).
  Future<void> saveAllExpenses(List<ExpenseModel> expenses) async {
    await _expenseBox.clear();
    final entries = {
      for (final e in expenses)
        e.id: {
          'id':       e.id,
          'title':    e.title,
          'amount':   e.amount,
          'category': e.category,
          'date':     e.date.millisecondsSinceEpoch,
          'note':     e.note,
        }
    };
    await _expenseBox.putAll(entries);
  }

  /// Read all locally-cached expenses, sorted newest-first.
  List<ExpenseModel> getExpenses() {
    return _expenseBox.values
        .map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          return ExpenseModel(
            id:       m['id']       as String,
            title:    m['title']    as String,
            amount:   (m['amount']  as num).toDouble(),
            category: m['category'] as String,
            date:     DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
            note:     m['note']     as String,
          );
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Delete a single expense by id.
  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
  }

  /// Wipe all locally-cached expenses (e.g. on logout).
  Future<void> clearExpenses() async {
    await _expenseBox.clear();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUDGET OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  static const String _budgetKey = 'current';

  /// Persist the budget locally.
  Future<void> saveBudget(BudgetModel budget) async {
    await _budgetBox.put(_budgetKey, {
      'id':       budget.id,
      'category': budget.category,
      'limit':    budget.limit,
      'spent':    budget.spent,
    });
  }

  /// Read the locally-cached budget (returns null if never saved).
  BudgetModel? getBudget() {
    final raw = _budgetBox.get(_budgetKey);
    if (raw == null) return null;
    final m = Map<String, dynamic>.from(raw as Map);
    return BudgetModel(
      id:       m['id']       as String,
      category: m['category'] as String,
      limit:    (m['limit']   as num).toDouble(),
      spent:    (m['spent']   as num).toDouble(),
    );
  }

  /// Wipe locally-cached budget (e.g. on logout).
  Future<void> clearBudget() async {
    await _budgetBox.delete(_budgetKey);
  }
}

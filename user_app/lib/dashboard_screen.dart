import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'expense_model.dart';
import 'expense_provider.dart';
import 'budget_provider.dart';
import 'app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = context.read<AuthProvider>().currentUser?.uid;
      if (userId == null) return;
      context.read<ExpenseProvider>().listenToExpenses(userId);
      context.read<BudgetProvider>().listenBudget(userId);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EDIT BUDGET LIMIT DIALOG
  // ─────────────────────────────────────────────────────────────────────────
  void _showEditBudgetDialog(BuildContext context, double currentLimit) {
    final controller =
        TextEditingController(text: currentLimit.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: const Text(
          "Edit Budget Limit",
          style: TextStyle(
            color:      AppColors.textPrimary,
            fontSize:   18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: appInputDecoration(
              label: "New monthly limit (Rs)",
              prefixIcon: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return "Enter an amount";
              final val = double.tryParse(v);
              if (val == null || val <= 0) return "Enter a valid amount";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newLimit =
                  double.parse(controller.text.trim());
              final userId =
                  context.read<AuthProvider>().currentUser?.uid;
              if (userId == null) return;
              await context
                  .read<BudgetProvider>()
                  .updateLimit(userId, newLimit);
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget limit updated!')),
              );
            },
            child: const Text(
              "Save",
              style: TextStyle(
                color:      AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider  = context.watch<BudgetProvider>();

    final budget   = budgetProvider.budget;
    final expenses = expenseProvider.expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          if (budget != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () =>
                    _showEditBudgetDialog(context, budget.limit),
                icon: const Icon(
                  Icons.edit_outlined,
                  size:  16,
                  color: AppColors.primary,
                ),
                label: const Text(
                  "Edit Limit",
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: budget == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── BUDGET CARD ────────────────────────────────────────────
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + Edit button row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Monthly Budget",
                                style: TextStyle(
                                  fontSize:   18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _showEditBudgetDialog(context, budget.limit),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical:   6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          size: 14, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        "Edit",
                                        style: TextStyle(
                                          color:      AppColors.primary,
                                          fontSize:   12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Budget numbers
                          _budgetRow("Limit",
                              "Rs ${budget.limit.toStringAsFixed(0)}",
                              AppColors.textPrimary),
                          const SizedBox(height: 6),
                          _budgetRow("Spent",
                              "Rs ${budget.spent.toStringAsFixed(0)}",
                              AppColors.error),
                          const SizedBox(height: 6),
                          _budgetRow("Remaining",
                              "Rs ${budget.remaining.toStringAsFixed(0)}",
                              AppColors.success),

                          const SizedBox(height: 16),

                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value:           budget.percentUsed / 100,
                              minHeight:       12,
                              backgroundColor: AppColors.border,
                              color: budget.percentUsed > 80
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "${budget.percentUsed.toStringAsFixed(1)}% used",
                            style: const TextStyle(
                              color:    AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── QUICK STATS ────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _statBox(
                          "Total Expenses",
                          expenses.length.toString(),
                          Icons.list_alt_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statBox(
                          "Today",
                          "Rs ${_todaySpent(expenses).toStringAsFixed(0)}",
                          Icons.today_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── RECENT EXPENSES ────────────────────────────────────────
                  const Text(
                    "Recent Expenses",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  if (expenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          "No expenses yet",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...expenses.take(5).map((e) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  categoryColor(e.category).withOpacity(0.15),
                              child: Icon(
                                categoryIcon(e.category),
                                color: categoryColor(e.category),
                                size:  18,
                              ),
                            ),
                            title:    Text(e.title),
                            subtitle: Text(e.category),
                            trailing: Text(
                              "Rs ${e.amount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color:      AppColors.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  Widget _budgetRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statBox(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title,
                style: const TextStyle(
                  color:    AppColors.textSecondary,
                  fontSize: 12,
                )),
          ],
        ),
      ),
    );
  }

  double _todaySpent(List<ExpenseModel> expenses) {
    final today = DateTime.now();
    return expenses
        .where((e) =>
            e.date.day   == today.day &&
            e.date.month == today.month &&
            e.date.year  == today.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }
}

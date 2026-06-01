import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/admin_provider.dart';
import '../../models/expense_model.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Expenses'),
        actions: [
          if (_selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                });
              },
            ),
        ],
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: adminProvider.expensesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allExpenses = snapshot.data ?? [];

          if (allExpenses.isEmpty) {
            return const Center(child: Text('No expenses found.'));
          }

          // Unique categories only
          final categories = allExpenses
              .map((e) => e.category)
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();

          // Filter
          final filteredExpenses = allExpenses.where((expense) {
            final matchCategory = _selectedCategory == null
                ? true
                : expense.category == _selectedCategory;

            return matchCategory;
          }).toList();

          return Column(
            children: [
              // FILTER
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All'),
                    ),
                    ...categories.map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  },
                ),
              ),

              // LIST
              Expanded(
                child: ListView.builder(
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = filteredExpenses[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        expense.title.isNotEmpty
                            ? expense.title
                            : 'No Title',
                      ),
                      subtitle: Text(
                        '${DateFormat('yMMMd').format(expense.date)}\n${expense.note}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        '\$${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
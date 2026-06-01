import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'expense_model.dart';

class ChartsScreen extends StatelessWidget {
  final List<ExpenseModel> expenses;

  const ChartsScreen({
    super.key,
    required this.expenses,
  });

  // Fixed: colour palette for pie slices
  static const _palette = [
    Color(0xFF6C63FF),
    Color(0xFFFFB347),
    Color(0xFF4CAF50),
    Color(0xFFE57373),
    Color(0xFF29B6F6),
    Color(0xFFFF8A65),
    Color(0xFFAB47BC),
  ];

  @override
  Widget build(BuildContext context) {
    // Fixed: guard against empty expense list
    final hasData = expenses.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
      ),
      body: !hasData
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No expense data yet",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Add some expenses to see your analytics",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── PIE CHART ──────────────────────────────────────────────
                  const Text(
                    "Category Breakdown",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        // Fixed: colors are now assigned
                        sections: _getPieSections(expenses),
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── BAR CHART ──────────────────────────────────────────────
                  const Text(
                    "Weekly Spending",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        barGroups: _getBarGroups(expenses),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'Mon', 'Tue', 'Wed',
                                  'Thu', 'Fri', 'Sat', 'Sun'
                                ];
                                return Text(
                                  days[value.toInt()],
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Fixed: assign a colour from palette to each slice
  List<PieChartSectionData> _getPieSections(List<ExpenseModel> expenses) {
    final Map<String, double> data = {};
    for (var e in expenses) {
      data[e.category] = (data[e.category] ?? 0) + e.amount;
    }
    int i = 0;
    return data.entries.map((entry) {
      final color = _palette[i++ % _palette.length];
      return PieChartSectionData(
        value: entry.value,
        title: entry.key,
        color: color,       // Fixed: was missing
        radius: 60,
      );
    }).toList();
  }

  List<BarChartGroupData> _getBarGroups(List<ExpenseModel> expenses) {
    List<double> weekly = List.filled(7, 0);
    for (var e in expenses) {
      int day = e.date.weekday - 1;
      weekly[day] += e.amount;
    }
    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: weekly[i],
            width: 15,
            color: _palette[i % _palette.length], // Fixed: coloured bars
          ),
        ],
      );
    });
  }
}

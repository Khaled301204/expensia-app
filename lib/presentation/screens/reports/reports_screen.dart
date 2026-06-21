import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../../routes/app_router.dart';
import '../../providers/expense_provider.dart';
import '../../../data/models/expense.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedPieIndex = -1;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            tooltip: 'AI Insights',
            onPressed: () => Navigator.pushNamed(context, AppRouter.insights),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'By Category'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = _expensesForMonth(provider.expenses);
          final byCategory = _groupByCategory(expenses);

          return Column(
            children: [
              _MonthPicker(
                selectedMonth: _selectedMonth,
                onPrev: () => setState(() => _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
                onNext: _canGoNext()
                    ? () => setState(() => _selectedMonth = DateTime(
                        _selectedMonth.year, _selectedMonth.month + 1))
                    : null,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CategoryTab(
                      byCategory: byCategory,
                      total: expenses.fold(0.0, (s, e) => s + e.amount),
                      touchedIndex: _touchedPieIndex,
                      onTouch: (i) => setState(() => _touchedPieIndex = i),
                    ),
                    _TrendsTab(expenses: provider.expenses),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _canGoNext() {
    final now = DateTime.now();
    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year &&
            _selectedMonth.month < now.month);
  }

  List<Expense> _expensesForMonth(List<Expense> all) {
    return all.where((e) =>
        e.date.year == _selectedMonth.year &&
        e.date.month == _selectedMonth.month).toList();
  }

  Map<String, double> _groupByCategory(List<Expense> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.categoryName] = (map[e.categoryName] ?? 0) + e.amount;
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }
}

class _MonthPicker extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _MonthPicker({
    required this.selectedMonth,
    required this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontSize: 16),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(Icons.chevron_right,
                color: onNext == null ? Colors.grey : null),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Category Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CategoryTab extends StatelessWidget {
  final Map<String, double> byCategory;
  final double total;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _CategoryTab({
    required this.byCategory,
    required this.total,
    required this.touchedIndex,
    required this.onTouch,
  });

  static const _colors = [
    Color(0xFF6C63FF),
    Color(0xFF4CAF50),
    Color(0xFFFF7043),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
    Color(0xFFEC407A),
    Color(0xFF42A5F5),
    Color(0xFF8D6E63),
    Color(0xFFAB47BC),
    Color(0xFF78909C),
  ];

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No expenses this month'),
          ],
        ),
      );
    }

    final entries = byCategory.entries.toList();
    final sections = List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final pct = total > 0 ? entries[i].value / total * 100 : 0;
      return PieChartSectionData(
        color: _colors[i % _colors.length],
        value: entries[i].value,
        title: '${pct.toStringAsFixed(1)}%',
        radius: isTouched ? 70 : 56,
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        badgeWidget: null,
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 48,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (response?.touchedSection != null) {
                        onTouch(response!
                            .touchedSection!.touchedSectionIndex);
                      } else {
                        onTouch(-1);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Total: EGP ${total.toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Text('Breakdown',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...List.generate(entries.length, (i) {
            final pct = total > 0 ? entries[i].value / total : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _colors[i % _colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(entries[i].key,
                              style: Theme.of(context).textTheme.bodyLarge)),
                      Text(
                        'EGP ${entries[i].value.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.toDouble(),
                      backgroundColor:
                          _colors[i % _colors.length].withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(
                          _colors[i % _colors.length]),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// â”€â”€ Trends Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TrendsTab extends StatelessWidget {
  final List<Expense> expenses;

  const _TrendsTab({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final monthlyTotals = _computeMonthlyTotals();
    if (monthlyTotals.isEmpty) {
      return const Center(child: Text('No expense data available'));
    }

    final maxY = monthlyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2;
    final spots = monthlyTotals.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final labels = monthlyTotals.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Spending Trend',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      getTitlesWidget: (value, _) => Text(
                        'EGP ${value.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Transform.rotate(
                          angle: -0.5,
                          child: Text(labels[idx],
                              style: const TextStyle(fontSize: 9)),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Monthly Summary',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...monthlyTotals.entries.map((entry) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(entry.key),
                  trailing: Text(
                    'EGP ${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorColor),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Map<String, double> _computeMonthlyTotals() {
    final map = <String, double>{};
    for (final e in expenses) {
      final key = DateFormat('MMM yyyy').format(e.date);
      map[key] = (map[key] ?? 0) + e.amount;
    }
    // Sort chronologically
    final sorted = map.entries.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMM yyyy').parse(a.key);
        final dateB = DateFormat('MMM yyyy').parse(b.key);
        return dateA.compareTo(dateB);
      });
    // Return last 6 months
    final last6 = sorted.length > 6
        ? sorted.sublist(sorted.length - 6)
        : sorted;
    return Map.fromEntries(last6);
  }
}

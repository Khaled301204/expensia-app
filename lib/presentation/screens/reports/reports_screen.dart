import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/file_download.dart';
import '../../../data/services/api_service.dart';
import '../../../routes/app_router.dart';
import '../../providers/expense_provider.dart';
import '../../providers/reports_provider.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/monthly_report.dart';

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
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
      context.read<ReportsProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _export(String endpoint, String filename, String mimeType) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await ApiService().fetchBytes(endpoint);
      final savedPath = await downloadFile(bytes, filename, mimeType);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(savedPath != null ? 'Saved to $savedPath' : '$filename downloaded'),
        backgroundColor: AppTheme.successColor,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: AppTheme.errorColor,
      ));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: AppTheme.darkTextPri,
        surfaceTintColor: Colors.transparent,
        title: Text('Reports & Analytics',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            tooltip: 'AI Insights',
            onPressed: () => Navigator.pushNamed(context, AppRouter.insights),
          ),
          if (_exporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Export',
              color: AppTheme.darkElevated,
              onSelected: (v) {
                if (v == 'csv') {
                  _export(AppConfig.exportCsvEndpoint, 'expense-report.csv', 'text/csv');
                } else {
                  _export(AppConfig.exportPdfEndpoint, 'expense-report.pdf', 'application/pdf');
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'csv',
                  child: Row(children: [
                    const Icon(Icons.table_chart_outlined, size: 18, color: AppTheme.secondaryColor),
                    const SizedBox(width: 10),
                    Text('Export CSV', style: GoogleFonts.inter(color: AppTheme.darkTextPri)),
                  ])),
                PopupMenuItem(value: 'pdf',
                  child: Row(children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppTheme.errorColor),
                    const SizedBox(width: 10),
                    Text('Export PDF', style: GoogleFonts.inter(color: AppTheme.darkTextPri)),
                  ])),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.darkTextSec,
          tabs: const [
            Tab(text: 'By Category'),
            Tab(text: 'Monthly'),
            Tab(text: 'AI Tips'),
          ],
        ),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expProvider, _) {
          if (expProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(
                color: AppTheme.primaryColor));
          }
          final expenses = _expensesForMonth(expProvider.expenses);
          final byCategory = _groupByCategory(expenses);

          return Column(children: [
            // Month picker only visible on first tab
            AnimatedBuilder(
              animation: _tabController,
              builder: (_, __) => _tabController.index == 0
                ? _MonthPicker(
                    selectedMonth: _selectedMonth,
                    onPrev: () => setState(() => _selectedMonth =
                        DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
                    onNext: _canGoNext()
                        ? () => setState(() => _selectedMonth =
                            DateTime(_selectedMonth.year, _selectedMonth.month + 1))
                        : null,
                  )
                : const SizedBox.shrink(),
            ),
            Expanded(child: TabBarView(
              controller: _tabController,
              children: [
                _CategoryTab(
                  byCategory: byCategory,
                  total: expenses.fold(0.0, (s, e) => s + e.amount),
                  touchedIndex: _touchedPieIndex,
                  onTouch: (i) => setState(() => _touchedPieIndex = i),
                ),
                _MonthlyTab(),
                _RecommendationsTab(),
              ],
            )),
          ]);
        },
      ),
    );
  }

  bool _canGoNext() {
    final now = DateTime.now();
    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
  }

  List<Expense> _expensesForMonth(List<Expense> all) => all.where((e) =>
      e.date.year == _selectedMonth.year &&
      e.date.month == _selectedMonth.month).toList();

  Map<String, double> _groupByCategory(List<Expense> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.categoryName] = (map[e.categoryName] ?? 0) + e.amount;
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }
}

// ── Month Picker ───────────────────────────────────────────────────────────────

class _MonthPicker extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  const _MonthPicker({required this.selectedMonth, required this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
      Text(DateFormat('MMMM yyyy').format(selectedMonth),
          style: GoogleFonts.inter(
            color: AppTheme.darkTextPri, fontSize: 16, fontWeight: FontWeight.w600)),
      IconButton(
        onPressed: onNext,
        icon: Icon(Icons.chevron_right,
            color: onNext == null ? AppTheme.darkTextMuted : AppTheme.darkTextPri),
      ),
    ]),
  );
}

// ── Category Tab (pie chart) ───────────────────────────────────────────────────

class _CategoryTab extends StatelessWidget {
  final Map<String, double> byCategory;
  final double total;
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  const _CategoryTab({
    required this.byCategory, required this.total,
    required this.touchedIndex, required this.onTouch,
  });

  static const _colors = [
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFF97316),
    Color(0xFF8B5CF6), Color(0xFFF59E0B), Color(0xFFEC4899),
    Color(0xFF38BDF8), Color(0xFF6EE7B7), Color(0xFFFCA5A5),
    Color(0xFF78909C),
  ];

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.bar_chart, size: 64, color: AppTheme.darkTextMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text('No expenses this month',
            style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 16)),
      ]));
    }

    final entries = byCategory.entries.toList();
    final sections = List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final pct = total > 0 ? entries[i].value / total * 100 : 0.0;
      return PieChartSectionData(
        color: _colors[i % _colors.length],
        value: entries[i].value,
        title: '${pct.toStringAsFixed(1)}%',
        radius: isTouched ? 72 : 58,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: SizedBox(
          height: 220,
          child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 48,
            pieTouchData: PieTouchData(touchCallback: (_, response) {
              onTouch(response?.touchedSection?.touchedSectionIndex ?? -1);
            }),
          )),
        )),
        const SizedBox(height: 8),
        Center(child: Text('Total: EGP ${total.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              color: AppTheme.darkTextPri, fontSize: 18, fontWeight: FontWeight.w800))),
        const SizedBox(height: 20),
        Text('Breakdown', style: GoogleFonts.inter(
            color: AppTheme.darkTextPri, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...List.generate(entries.length, (i) {
          final pct = total > 0 ? entries[i].value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: _colors[i % _colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(entries[i].key,
                    style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14))),
                Text('EGP ${entries[i].value.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        color: AppTheme.darkTextPri, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: _colors[i % _colors.length].withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(_colors[i % _colors.length]),
                  minHeight: 5,
                )),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── Monthly Tab (real API) ─────────────────────────────────────────────────────

class _MonthlyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(builder: (_, provider, __) {
      if (provider.isLoading) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
      }
      if (provider.error != null) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
          const SizedBox(height: 12),
          Text(provider.error!, textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<ReportsProvider>().loadMonthly(),
            child: const Text('Retry')),
        ]));
      }
      final r = provider.monthly;
      if (r == null || (r.totalExpenses == 0 && r.totalIncome == 0)) {
        return Center(child: Text('No monthly data available',
            style: GoogleFonts.inter(color: AppTheme.darkTextSec)));
      }
      return RefreshIndicator(
        onRefresh: () => context.read<ReportsProvider>().loadMonthly(),
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.darkCard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Summary cards row
            Row(children: [
              Expanded(child: _StatCard('Income', r.totalIncome, AppTheme.secondaryColor,
                  Icons.arrow_downward_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Expenses', r.totalExpenses, AppTheme.errorColor,
                  Icons.arrow_upward_rounded)),
            ]),
            const SizedBox(height: 12),
            _StatCard('Net Savings', r.netSavings,
                r.netSavings >= 0 ? AppTheme.secondaryColor : AppTheme.errorColor,
                Icons.savings_outlined, fullWidth: true),
            const SizedBox(height: 24),
            if (r.categoryBreakdown.isNotEmpty) ...[
              Text('Category Breakdown', style: GoogleFonts.inter(
                  color: AppTheme.darkTextPri, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...r.categoryBreakdown.map((c) => _CategoryRow(c)),
            ],
          ]),
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool fullWidth;
  const _StatCard(this.label, this.value, this.color, this.icon, {this.fullWidth = false});

  @override
  Widget build(BuildContext context) => Container(
    width: fullWidth ? double.infinity : null,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 12)),
        Text('EGP ${value.toStringAsFixed(2)}',
            style: GoogleFonts.inter(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
    ]),
  );
}

class _CategoryRow extends StatelessWidget {
  final CategoryBreakdown c;
  const _CategoryRow(this.c);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.darkBorder),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c.category, style: GoogleFonts.inter(
            color: AppTheme.darkTextPri, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (c.percentage / 100).clamp(0.0, 1.0),
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            minHeight: 4,
          )),
      ])),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('EGP ${c.amount.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
                color: AppTheme.darkTextPri, fontSize: 13, fontWeight: FontWeight.w700)),
        Text('${c.percentage.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 11)),
      ]),
    ]),
  );
}

// ── AI Tips Tab (recommendations) ─────────────────────────────────────────────

class _RecommendationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(builder: (_, provider, __) {
      if (provider.isLoading) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
      }
      if (provider.recommendations.isEmpty) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lightbulb_outline,
              size: 64, color: AppTheme.darkTextMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No recommendations yet',
              style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Keep tracking expenses to get AI tips',
              style: GoogleFonts.inter(color: AppTheme.darkTextMuted, fontSize: 13)),
        ]));
      }

      final colors = [
        AppTheme.primaryColor, AppTheme.secondaryColor, AppTheme.accentOrange,
        AppTheme.accentPurple, AppTheme.accentGold,
      ];

      return RefreshIndicator(
        onRefresh: () => context.read<ReportsProvider>().loadRecommendations(),
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.darkCard,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.recommendations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final color = colors[i % colors.length];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Center(child: Text('${i + 1}',
                      style: GoogleFonts.inter(
                          color: color, fontWeight: FontWeight.w700, fontSize: 13)))),
                const SizedBox(width: 12),
                Expanded(child: Text(provider.recommendations[i],
                    style: GoogleFonts.inter(
                        color: AppTheme.darkTextPri, fontSize: 14, height: 1.5))),
              ]),
            );
          },
        ),
      );
    });
  }
}

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
import '../../../data/models/insights.dart';

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

  Future<void> _showExportDialog(String format) async {
    DateTime? start;
    DateTime? end;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDlgState) {
          final rangeValid = start != null && end != null && !end!.isBefore(start!);
          return AlertDialog(
            backgroundColor: AppTheme.darkElevated,
            title: Text('Export ${format.toUpperCase()}',
                style: GoogleFonts.inter(
                    color: AppTheme.darkTextPri, fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pick a date range or export all-time data.',
                    style: GoogleFonts.inter(
                        color: AppTheme.darkTextSec, fontSize: 13)),
                const SizedBox(height: 20),
                _DateTile(
                  label: 'Start Date',
                  date: start,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: start ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDlgState(() => start = picked);
                  },
                ),
                const SizedBox(height: 10),
                _DateTile(
                  label: 'End Date',
                  date: end,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: end ?? start ?? DateTime.now(),
                      firstDate: start ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDlgState(() => end = picked);
                  },
                ),
                if (start != null && end != null && end!.isBefore(start!)) ...[
                  const SizedBox(height: 8),
                  Text('End date must be after start date',
                      style: GoogleFonts.inter(
                          color: AppTheme.errorColor, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('All Time')),
              ElevatedButton(
                  onPressed: rangeValid
                      ? () => Navigator.pop(dialogCtx, true)
                      : null,
                  child: const Text('Export')),
            ],
          );
        },
      ),
    );

    if (!mounted || confirmed == null) return;

    final filename = format == 'csv' ? 'expense-report.csv' : 'expense-report.pdf';
    final mimeType = format == 'csv' ? 'text/csv' : 'application/pdf';
    final base = format == 'csv'
        ? AppConfig.exportCsvEndpoint
        : AppConfig.exportPdfEndpoint;

    String endpoint = base;
    if (confirmed && start != null && end != null) {
      final fmt = DateFormat('yyyy-MM-dd');
      endpoint =
          '$base?startDate=${fmt.format(start!)}&endDate=${fmt.format(end!)}';
    }

    _export(endpoint, filename, mimeType);
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
              onSelected: (v) => _showExportDialog(v),
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
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 48,
              pieTouchData: PieTouchData(touchCallback: (_, response) {
                onTouch(response?.touchedSection?.touchedSectionIndex ?? -1);
              }),
            ),
            swapAnimationDuration: const Duration(milliseconds: 750),
            swapAnimationCurve: Curves.easeInOut,
          ),
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

// ── Monthly Pie Chart ──────────────────────────────────────────────────────────

class _MonthlyPieChart extends StatefulWidget {
  final List<CategoryBreakdown> data;
  const _MonthlyPieChart({required this.data});

  @override
  State<_MonthlyPieChart> createState() => _MonthlyPieChartState();
}

class _MonthlyPieChartState extends State<_MonthlyPieChart> {
  int _touched = -1;
  bool _animated = false;

  static const _colors = [
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFF97316),
    Color(0xFF8B5CF6), Color(0xFFF59E0B), Color(0xFFEC4899),
    Color(0xFF38BDF8), Color(0xFF6EE7B7), Color(0xFFFCA5A5),
    Color(0xFF78909C),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) { if (mounted) setState(() => _animated = true); });
  }

  @override
  Widget build(BuildContext context) {
    final sections = List.generate(widget.data.length, (i) {
      final isTouched = i == _touched;
      final c = widget.data[i];
      return PieChartSectionData(
        color: _colors[i % _colors.length],
        value: _animated ? c.amount : 0.001,
        title: isTouched ? '${c.percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 74 : 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });

    return Column(children: [
      SizedBox(
        height: 210,
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 44,
            sectionsSpace: 2,
            pieTouchData: PieTouchData(
              touchCallback: (_, resp) => setState(() =>
                  _touched = resp?.touchedSection?.touchedSectionIndex ?? -1),
            ),
          ),
          swapAnimationDuration: const Duration(milliseconds: 800),
          swapAnimationCurve: Curves.easeOut,
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 14,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(widget.data.length, (i) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 9, height: 9,
                decoration: BoxDecoration(
                    color: _colors[i % _colors.length],
                    shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(widget.data[i].category,
                style: GoogleFonts.inter(
                    color: AppTheme.darkTextSec, fontSize: 11)),
          ],
        )),
      ),
    ]);
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
              Text('Spending by Category', style: GoogleFonts.inter(
                  color: AppTheme.darkTextPri, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _MonthlyPieChart(data: r.categoryBreakdown),
              const SizedBox(height: 24),
              Text('Breakdown', style: GoogleFonts.inter(
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

      final rec = provider.recommendations;
      if (rec == null) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lightbulb_outline,
              size: 64, color: AppTheme.darkTextMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No recommendations yet',
              style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Keep tracking expenses to get AI tips',
              style: GoogleFonts.inter(color: AppTheme.darkTextMuted, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.read<ReportsProvider>().loadRecommendations(),
            child: const Text('Try again'),
          ),
        ]));
      }

      return RefreshIndicator(
        onRefresh: () => context.read<ReportsProvider>().loadRecommendations(),
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.darkCard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (rec.spendingInsights.isNotEmpty) ...[
              const _TipSectionHeader('Spending Insights', Icons.trending_up),
              const SizedBox(height: 10),
              ...rec.spendingInsights.map((s) => _SpendingInsightCard(s)),
              const SizedBox(height: 20),
            ],
            if (rec.saving != null) ...[
              const _TipSectionHeader('Savings Plan', Icons.savings_outlined),
              const SizedBox(height: 10),
              _SavingsPlanCard(rec.saving!),
              const SizedBox(height: 20),
            ],
            if (rec.goalPlans.isNotEmpty) ...[
              const _TipSectionHeader('Goal Plans', Icons.flag_outlined),
              const SizedBox(height: 10),
              ...rec.goalPlans.map((g) => _GoalPlanCard(g)),
              const SizedBox(height: 20),
            ],
            if (rec.investments.isNotEmpty) ...[
              const _TipSectionHeader('Investment Ideas', Icons.show_chart),
              const SizedBox(height: 10),
              ...rec.investments.map((inv) => _InvestmentCard(inv)),
              const SizedBox(height: 20),
            ],
          ],
        ),
      );
    });
  }
}

class _TipSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _TipSectionHeader(this.title, this.icon);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: AppTheme.primaryColor),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.inter(
        color: AppTheme.darkTextPri, fontSize: 15, fontWeight: FontWeight.w700)),
  ]);
}

class _SpendingInsightCard extends StatelessWidget {
  final SpendingInsight s;
  const _SpendingInsightCard(this.s);

  @override
  Widget build(BuildContext context) {
    final isOver = s.percentageDiff > 0;
    final color = isOver ? AppTheme.errorColor : AppTheme.secondaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isOver ? Icons.trending_up : Icons.trending_down, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(s.category, style: GoogleFonts.inter(
              color: AppTheme.darkTextPri, fontSize: 14, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${isOver ? '+' : ''}${s.percentageDiff.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Current: EGP ${s.currentSpending.toStringAsFixed(0)}',
              style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 12)),
          Text('Avg: EGP ${s.averageSpending.toStringAsFixed(0)}',
              style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 12)),
        ]),
        if (s.recommendation.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(s.recommendation, style: GoogleFonts.inter(
              color: AppTheme.darkTextMuted, fontSize: 12, height: 1.4)),
        ],
      ]),
    );
  }
}

class _SavingsPlanCard extends StatelessWidget {
  final SavingRecommendations s;
  const _SavingsPlanCard(this.s);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Monthly Target',
            style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 12))),
        Text('EGP ${s.monthlyTarget.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
                color: AppTheme.secondaryColor, fontSize: 18, fontWeight: FontWeight.w800)),
      ]),
      if (s.emergencyFund > 0 || s.investments > 0 || s.goals > 0) ...[
        const SizedBox(height: 12),
        const Divider(color: AppTheme.darkBorder, height: 1),
        const SizedBox(height: 12),
        Row(children: [
          _BucketChip('Emergency', s.emergencyFund, AppTheme.errorColor),
          const SizedBox(width: 8),
          _BucketChip('Invest', s.investments, AppTheme.accentPurple),
          const SizedBox(width: 8),
          _BucketChip('Goals', s.goals, AppTheme.primaryColor),
        ]),
      ],
      if (s.recommendations.isNotEmpty) ...[
        const SizedBox(height: 12),
        ...s.recommendations.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.secondaryColor),
            const SizedBox(width: 6),
            Expanded(child: Text(r, style: GoogleFonts.inter(
                color: AppTheme.darkTextSec, fontSize: 12, height: 1.4))),
          ]),
        )),
      ],
    ]),
  );
}

class _BucketChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _BucketChip(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(children: [
      Text(label, style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 10)),
      const SizedBox(height: 2),
      Text('EGP ${amount.toStringAsFixed(0)}',
          style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    ]),
  ));
}

class _GoalPlanCard extends StatelessWidget {
  final GoalPlan g;
  const _GoalPlanCard(this.g);

  static Color _feasibilityColor(String f) {
    switch (f.toUpperCase()) {
      case 'EASY': return AppTheme.secondaryColor;
      case 'MODERATE': return AppTheme.accentGold;
      default: return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _feasibilityColor(g.feasibility);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(g.goalName, style: GoogleFonts.inter(
              color: AppTheme.darkTextPri, fontSize: 14, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(g.feasibility, style: GoogleFonts.inter(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: g.progress,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            minHeight: 5,
          )),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('EGP ${g.currentAmount.toStringAsFixed(0)} / ${g.targetAmount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 12)),
          Text('${g.monthsToGoal} mo · EGP ${g.monthlySavingRequired.toStringAsFixed(0)}/mo',
              style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 12)),
        ]),
        if (g.recommendation.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(g.recommendation, style: GoogleFonts.inter(
              color: AppTheme.darkTextMuted, fontSize: 12, height: 1.4)),
        ],
      ]),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  final InvestmentSuggestion inv;
  const _InvestmentCard(this.inv);

  static Color _riskColor(String r) {
    switch (r.toUpperCase()) {
      case 'LOW': return AppTheme.secondaryColor;
      case 'MODERATE': return AppTheme.accentGold;
      default: return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(inv.riskLevel);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(inv.type, style: GoogleFonts.inter(
              color: AppTheme.darkTextPri, fontSize: 14, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(inv.riskLevel, style: GoogleFonts.inter(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text('EGP ${inv.suggestedAmount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                  color: AppTheme.primaryColor, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Text('Return: ${inv.expectedReturn}',
              style: GoogleFonts.inter(color: AppTheme.secondaryColor, fontSize: 12)),
        ]),
        if (inv.recommendation.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(inv.recommendation, style: GoogleFonts.inter(
              color: AppTheme.darkTextMuted, fontSize: 12, height: 1.4)),
        ],
      ]),
    );
  }
}

// ── Export date range tile ─────────────────────────────────────────────────────

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateTile({required this.label, this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = date != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : AppTheme.darkBorder,
          ),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined,
              size: 16,
              color: selected ? AppTheme.primaryColor : AppTheme.darkTextMuted),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: AppTheme.darkTextMuted, fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              selected
                  ? DateFormat('MMM dd, yyyy').format(date!)
                  : 'Tap to select',
              style: GoogleFonts.inter(
                color: selected ? AppTheme.darkTextPri : AppTheme.darkTextSec,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ]),
          const Spacer(),
          const Icon(Icons.chevron_right,
              size: 16, color: AppTheme.darkTextMuted),
        ]),
      ),
    );
  }
}

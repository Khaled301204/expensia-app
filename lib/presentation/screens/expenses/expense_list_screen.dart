import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_router.dart';
import '../../../core/config/theme.dart';
import '../../providers/expense_provider.dart';
import '../../../data/models/expense.dart';
import 'edit_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _searchCtrl = TextEditingController();
  String    _searchQuery      = '';
  String?   _selectedCategory;
  String?   _selectedPayment;
  String    _sortOrder        = 'newest'; // newest|oldest|highest|lowest
  String    _dateFilter       = 'all';    // all|today|week|month|custom
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int n = 0;
    if (_selectedCategory != null) n++;
    if (_selectedPayment != null) n++;
    if (_dateFilter != 'all') n++;
    if (_sortOrder != 'newest') n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: AppTheme.darkTextPri,
        surfaceTintColor: Colors.transparent,
        title: Text('Expenses',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: _showFilterSheet,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: AppTheme.primaryColor, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$_activeFilterCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search merchant, description, category...',
                hintStyle:
                    GoogleFonts.inter(color: AppTheme.darkTextMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.darkTextMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.darkTextMuted, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.darkCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppTheme.darkBorder, width: 1)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 1.5)),
              ),
            ),
          ),

          // Active filter chips
          if (_activeFilterCount > 0)
            _ActiveFilterChips(
              dateFilter: _dateFilter,
              customFrom: _customFrom,
              customTo: _customTo,
              category: _selectedCategory,
              payment: _selectedPayment,
              sortOrder: _sortOrder,
              onRemoveDate: () => setState(() {
                _dateFilter = 'all';
                _customFrom = null;
                _customTo = null;
              }),
              onRemoveCategory: () =>
                  setState(() => _selectedCategory = null),
              onRemovePayment: () =>
                  setState(() => _selectedPayment = null),
              onRemoveSort: () => setState(() => _sortOrder = 'newest'),
              onClearAll: _clearAllFilters,
            ),

          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor));
                }
                if (provider.error != null) {
                  return _ErrorView(
                    message: provider.error!,
                    onRetry: provider.loadExpenses,
                  );
                }

                if (provider.expenses.isEmpty) {
                  return _EmptyExpenses(
                    onAdd: () =>
                        Navigator.pushNamed(context, AppRouter.addExpense)
                            .then((_) => provider.loadExpenses()),
                  );
                }

                final expenses = _filterExpenses(provider.expenses);

                if (expenses.isEmpty) {
                  return _NoResults(onClear: _clearAllFilters);
                }

                final total =
                    expenses.fold<double>(0, (s, e) => s + e.amount);

                return Column(
                  children: [
                    _TotalBanner(
                      total: total,
                      count: expenses.length,
                      totalCount: provider.expenses.length,
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: provider.loadExpenses,
                        color: AppTheme.primaryColor,
                        backgroundColor: AppTheme.darkCard,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: expenses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) => _ExpenseTile(
                            expense: expenses[i],
                            onEdit: () => _goEdit(expenses[i]),
                            onDelete: () => _confirmDelete(
                                context, provider, expenses[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRouter.addExpense)
                .then((_) => context.read<ExpenseProvider>().loadExpenses()),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Expense',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }

  List<Expense> _filterExpenses(List<Expense> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final q = _searchQuery.toLowerCase();

    return all.where((e) {
      final matchSearch = q.isEmpty ||
          (e.description?.toLowerCase().contains(q) ?? false) ||
          (e.merchant?.toLowerCase().contains(q) ?? false) ||
          e.categoryName.toLowerCase().contains(q);

      final matchCat =
          _selectedCategory == null || e.categoryName == _selectedCategory;

      final matchPayment =
          _selectedPayment == null || e.paymentMethod == _selectedPayment;

      bool matchDate = true;
      switch (_dateFilter) {
        case 'today':
          matchDate = !e.date.isBefore(today) &&
              e.date.isBefore(today.add(const Duration(days: 1)));
        case 'week':
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          matchDate = !e.date.isBefore(weekStart);
        case 'month':
          matchDate =
              e.date.year == now.year && e.date.month == now.month;
        case 'custom':
          if (_customFrom != null) {
            matchDate = !e.date.isBefore(_customFrom!);
            if (_customTo != null) {
              matchDate = matchDate &&
                  !e.date.isAfter(
                      _customTo!.add(const Duration(days: 1)));
            }
          }
      }

      return matchSearch && matchCat && matchPayment && matchDate;
    }).toList()
      ..sort((a, b) {
        switch (_sortOrder) {
          case 'oldest':  return a.date.compareTo(b.date);
          case 'highest': return b.amount.compareTo(a.amount);
          case 'lowest':  return a.amount.compareTo(b.amount);
          default:        return b.date.compareTo(a.date);
        }
      });
  }

  void _clearAllFilters() => setState(() {
        _selectedCategory = null;
        _selectedPayment = null;
        _sortOrder = 'newest';
        _dateFilter = 'all';
        _customFrom = null;
        _customTo = null;
      });

  void _showFilterSheet() {
    final provider = context.read<ExpenseProvider>();
    final categories =
        provider.expenses.map((e) => e.categoryName).toSet().toList()..sort();
    final payments = provider.expenses
        .map((e) => e.paymentMethod)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        categories: categories,
        payments: payments,
        selectedCategory: _selectedCategory,
        selectedPayment: _selectedPayment,
        sortOrder: _sortOrder,
        dateFilter: _dateFilter,
        customFrom: _customFrom,
        customTo: _customTo,
        onApply: (cat, pay, sort, date, from, to) {
          setState(() {
            _selectedCategory = cat;
            _selectedPayment = pay;
            _sortOrder = sort;
            _dateFilter = date;
            _customFrom = from;
            _customTo = to;
          });
        },
        onReset: _clearAllFilters,
      ),
    );
  }

  void _goEdit(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditExpenseScreen(expense: expense)),
    ).then((updated) {
      if (updated == true && mounted) {
        context.read<ExpenseProvider>().loadExpenses();
      }
    });
  }

  Future<void> _confirmDelete(
      BuildContext context, ExpenseProvider provider, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Delete Expense',
            style: GoogleFonts.inter(
                color: AppTheme.darkTextPri, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete EGP ${expense.amount.toStringAsFixed(2)} from ${expense.categoryName}?',
          style: GoogleFonts.inter(color: AppTheme.darkTextSec),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.darkTextSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await provider.deleteExpense(expense.id);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Delete failed')));
      }
    }
  }
}

// ─── Active filter chips ─────────────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  final String    dateFilter;
  final DateTime? customFrom, customTo;
  final String?   category, payment, sortOrder;
  final VoidCallback onRemoveDate, onRemoveCategory, onRemovePayment,
      onRemoveSort, onClearAll;

  const _ActiveFilterChips({
    required this.dateFilter,
    required this.customFrom,
    required this.customTo,
    required this.category,
    required this.payment,
    required this.sortOrder,
    required this.onRemoveDate,
    required this.onRemoveCategory,
    required this.onRemovePayment,
    required this.onRemoveSort,
    required this.onClearAll,
  });

  String _dateLabel() {
    switch (dateFilter) {
      case 'today': return 'Today';
      case 'week':  return 'This Week';
      case 'month': return 'This Month';
      case 'custom':
        final fmt = DateFormat('MMM dd');
        if (customFrom != null && customTo != null) {
          return '${fmt.format(customFrom!)} – ${fmt.format(customTo!)}';
        }
        if (customFrom != null) return 'From ${fmt.format(customFrom!)}';
        return 'Custom';
      default: return '';
    }
  }

  String _sortLabel() => const {
        'oldest':  'Oldest first',
        'highest': 'Highest first',
        'lowest':  'Lowest first',
      }[sortOrder] ?? '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (dateFilter != 'all')
            _Chip(label: _dateLabel(), onRemove: onRemoveDate),
          if (category != null)
            _Chip(label: category!, onRemove: onRemoveCategory),
          if (payment != null)
            _Chip(label: payment!, onRemove: onRemovePayment),
          if (sortOrder != null && sortOrder != 'newest')
            _Chip(label: _sortLabel(), onRemove: onRemoveSort),
          TextButton(
            onPressed: onClearAll,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Clear all',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _Chip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close,
              size: 14, color: AppTheme.primaryColor),
        ),
      ]),
    );
  }
}

// ─── Filter bottom sheet ─────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final List<String> categories;
  final List<String> payments;
  final String? selectedCategory;
  final String? selectedPayment;
  final String sortOrder;
  final String dateFilter;
  final DateTime? customFrom;
  final DateTime? customTo;
  final Function(String? cat, String? pay, String sort, String date,
      DateTime? from, DateTime? to) onApply;
  final VoidCallback onReset;

  const _FilterSheet({
    required this.categories,
    required this.payments,
    required this.selectedCategory,
    required this.selectedPayment,
    required this.sortOrder,
    required this.dateFilter,
    required this.customFrom,
    required this.customTo,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String?   _cat;
  late String?   _pay;
  late String    _sort;
  late String    _date;
  DateTime?      _from;
  DateTime?      _to;

  @override
  void initState() {
    super.initState();
    _cat  = widget.selectedCategory;
    _pay  = widget.selectedPayment;
    _sort = widget.sortOrder;
    _date = widget.dateFilter;
    _from = widget.customFrom;
    _to   = widget.customTo;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppTheme.darkBorder,
                borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filters & Sort',
                        style: GoogleFonts.inter(
                            color: AppTheme.darkTextPri,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onReset();
                      },
                      child: Text('Reset all',
                          style: GoogleFonts.inter(
                              color: AppTheme.errorColor, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sort
                const _SectionLabel('Sort by'),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final opt in [
                    ('newest', 'Newest first'),
                    ('oldest', 'Oldest first'),
                    ('highest', 'Highest amount'),
                    ('lowest', 'Lowest amount'),
                  ])
                    _OptionChip(
                      label: opt.$2,
                      selected: _sort == opt.$1,
                      onTap: () => setState(() => _sort = opt.$1),
                    ),
                ]),
                const SizedBox(height: 24),

                // Date range
                _SectionLabel('Date range'),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final opt in [
                    ('all', 'All time'),
                    ('today', 'Today'),
                    ('week', 'This week'),
                    ('month', 'This month'),
                    ('custom', 'Custom range'),
                  ])
                    _OptionChip(
                      label: opt.$2,
                      selected: _date == opt.$1,
                      onTap: () async {
                        if (opt.$1 == 'custom') {
                          await _pickCustomRange();
                        } else {
                          setState(() {
                            _date = opt.$1;
                            _from = null;
                            _to = null;
                          });
                        }
                      },
                    ),
                ]),
                if (_date == 'custom' && (_from != null || _to != null)) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_from != null ? DateFormat('MMM dd, yyyy').format(_from!) : '—'}'
                    '  →  '
                    '${_to != null ? DateFormat('MMM dd, yyyy').format(_to!) : '—'}',
                    style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(height: 24),

                // Category
                if (widget.categories.isNotEmpty) ...[
                  const _SectionLabel('Category'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _OptionChip(
                      label: 'All',
                      selected: _cat == null,
                      onTap: () => setState(() => _cat = null),
                    ),
                    for (final c in widget.categories)
                      _OptionChip(
                        label: c,
                        selected: _cat == c,
                        onTap: () => setState(() => _cat = c),
                      ),
                  ]),
                  const SizedBox(height: 24),
                ],

                // Payment method
                if (widget.payments.isNotEmpty) ...[
                  const _SectionLabel('Payment method'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _OptionChip(
                      label: 'All',
                      selected: _pay == null,
                      onTap: () => setState(() => _pay = null),
                    ),
                    for (final p in widget.payments)
                      _OptionChip(
                        label: p,
                        selected: _pay == p,
                        onTap: () => setState(() => _pay = p),
                      ),
                  ]),
                  const SizedBox(height: 24),
                ],

                // Apply
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onApply(_cat, _pay, _sort, _date, _from, _to);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Apply filters',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            surface: AppTheme.darkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;
    if (range != null) {
      setState(() {
        _date = 'custom';
        _from = range.start;
        _to   = range.end;
      });
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          color: AppTheme.darkTextSec,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5));
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : AppTheme.darkElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.darkBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : AppTheme.darkTextSec,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Total banner ─────────────────────────────────────────────────────────────

class _TotalBanner extends StatelessWidget {
  final double total;
  final int count;
  final int totalCount;
  const _TotalBanner(
      {required this.total,
      required this.count,
      required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final isFiltered = count < totalCount;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isFiltered ? '$count of $totalCount expenses' : '$count expenses',
            style: GoogleFonts.inter(
                color: AppTheme.darkTextSec, fontSize: 13),
          ),
          Text(
            'EGP ${total.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─── Expense tile ─────────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ExpenseTile(
      {required this.expense, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(children: [
        // Category circle
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              expense.categoryName.isNotEmpty
                  ? expense.categoryName[0].toUpperCase()
                  : '?',
              style: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Details
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.merchant ??
                      expense.description ??
                      expense.categoryName,
                  style: GoogleFonts.inter(
                      color: AppTheme.darkTextPri,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Text(expense.categoryName,
                      style: GoogleFonts.inter(
                          color: AppTheme.darkTextSec, fontSize: 12)),
                  const SizedBox(width: 6),
                  Text('·',
                      style: GoogleFonts.inter(
                          color: AppTheme.darkTextMuted, fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(DateFormat('MMM dd, yyyy').format(expense.date),
                      style: GoogleFonts.inter(
                          color: AppTheme.darkTextMuted, fontSize: 11)),
                ]),
              ]),
        ),

        // Amount + actions
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (expense.createdByVoice)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.mic, size: 11, color: AppTheme.primaryColor),
              ),
            Text(
              'EGP ${expense.amount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                  color: AppTheme.errorColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: onEdit,
              child: const Icon(Icons.edit_outlined,
                  color: AppTheme.darkTextMuted, size: 17),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline,
                  color: AppTheme.darkTextMuted, size: 17),
            ),
          ]),
        ]),
      ]),
    );
  }
}

// ─── Empty / no-results / error ───────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final VoidCallback onClear;
  const _NoResults({required this.onClear});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off_rounded,
              size: 64,
              color: AppTheme.darkTextMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No matching expenses',
              style: GoogleFonts.inter(
                  color: AppTheme.darkTextPri,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Try adjusting your filters or search',
              style: GoogleFonts.inter(
                  color: AppTheme.darkTextSec, fontSize: 13)),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor)),
            child: Text('Clear all filters',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ),
        ]),
      );
}

class _EmptyExpenses extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyExpenses({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long_outlined,
              size: 72,
              color: AppTheme.darkTextMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No expenses yet',
              style: GoogleFonts.inter(
                  color: AppTheme.darkTextPri,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Start tracking your spending',
              style:
                  GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Add Expense',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline,
              size: 56, color: AppTheme.errorColor),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppTheme.darkTextSec, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

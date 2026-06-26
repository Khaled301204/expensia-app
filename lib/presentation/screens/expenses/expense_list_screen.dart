import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return _ErrorView(
                    message: provider.error!,
                    onRetry: () => provider.loadExpenses(),
                  );
                }

                final expenses = _filterExpenses(provider.expenses);

                if (expenses.isEmpty) {
                  return _EmptyExpenses(
                    onAdd: () =>
                        Navigator.pushNamed(context, AppRouter.addExpense),
                  );
                }

                final totalShown = expenses.fold<double>(
                    0, (sum, e) => sum + e.amount);

                return Column(
                  children: [
                    _TotalBanner(total: totalShown, count: expenses.length),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => provider.loadExpenses(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: expenses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) => _ExpenseTile(
                            expense: expenses[i],
                            onEdit: () => _goEdit(expenses[i]),
                            onDelete: () =>
                                _confirmDelete(context, provider, expenses[i]),
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
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  List<Expense> _filterExpenses(List<Expense> all) {
    return all.where((e) {
      final matchSearch = _searchQuery.isEmpty ||
          (e.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (e.merchant?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          e.categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCategory =
          _selectedCategory == null || e.categoryName == _selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  void _showFilterSheet() {
    final categories = context
        .read<ExpenseProvider>()
        .expenses
        .map((e) => e.categoryName)
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet(
        categories: categories,
        selected: _selectedCategory,
        onSelect: (cat) {
          setState(() => _selectedCategory = cat);
          Navigator.pop(context);
        },
        onClear: () {
          setState(() => _selectedCategory = null);
          Navigator.pop(context);
        },
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
        title: const Text('Delete Expense'),
        content: Text(
            'Delete EGP ${expense.amount.toStringAsFixed(2)} from ${expense.categoryName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final success = await provider.deleteExpense(expense.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Delete failed')),
        );
      }
    }
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search expenses...',
          prefixIcon: const Icon(Icons.search),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          isDense: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          filled: true,
          fillColor:
              Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _TotalBanner extends StatelessWidget {
  final double total;
  final int count;
  const _TotalBanner({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$count expenses',
              style: Theme.of(context).textTheme.bodyMedium),
          Text(
            'Total: EGP ${total.toStringAsFixed(2)}',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTile({required this.expense, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          child: Text(
            expense.categoryName.isNotEmpty
                ? expense.categoryName[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          expense.merchant ?? expense.description ?? expense.categoryName,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.categoryName,
                style: Theme.of(context).textTheme.bodyMedium),
            Text(
              DateFormat('MMM dd, yyyy').format(expense.date),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'EGP ${expense.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorColor,
                      ),
                ),
                if (expense.createdByVoice)
                  const Icon(Icons.mic, size: 12, color: AppTheme.primaryColor),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter by Category',
                    style: Theme.of(context).textTheme.titleLarge),
                if (selected != null)
                  TextButton(onPressed: onClear, child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = cat == selected;
                return FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => onSelect(cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _EmptyExpenses extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyExpenses({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No expenses yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Start tracking your spending',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: AppTheme.errorColor),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

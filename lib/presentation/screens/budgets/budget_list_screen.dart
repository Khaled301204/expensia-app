import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_router.dart';
import '../../../core/config/theme.dart';
import '../../providers/budget_provider.dart';
import '../../../data/models/budget.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<BudgetProvider>().loadBudgets());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return _ErrorView(
                message: provider.error!,
                onRetry: () => provider.loadBudgets());
          }
          if (provider.budgets.isEmpty) {
            return _EmptyBudgets(
              onAdd: () => Navigator.pushNamed(context, AppRouter.addBudget)
                  .then((_) => provider.loadBudgets()),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadBudgets(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.budgets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _BudgetCard(
                budget: provider.budgets[i],
                onDelete: () =>
                    _confirmDelete(context, provider, provider.budgets[i]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRouter.addBudget)
            .then((_) => context.read<BudgetProvider>().loadBudgets()),
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, BudgetProvider provider, Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
            'Delete the ${budget.categoryName} budget of EGP ${budget.limitAmount.toStringAsFixed(0)}?'),
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
      await provider.deleteBudget(budget.id);
    }
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onDelete;

  const _BudgetCard({required this.budget, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final pct = (budget.spentAmount / budget.limitAmount).clamp(0.0, 1.0);
    final color = budget.isOverBudget
        ? AppTheme.errorColor
        : pct >= 0.8
            ? AppTheme.warningColor
            : AppTheme.secondaryColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_balance_wallet, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budget.categoryName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 16)),
                      Text(
                        '${DateFormat('MMM dd').format(budget.startDate)} â€“ ${DateFormat('MMM dd, yyyy').format(budget.endDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (budget.isOverBudget)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Over Budget',
                        style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AmountChip(
                    label: 'Spent', value: budget.spentAmount, color: color),
                _AmountChip(
                    label: 'Limit',
                    value: budget.limitAmount,
                    color: AppTheme.primaryColor),
                _AmountChip(
                    label: 'Remaining',
                    value: budget.remaining.abs(),
                    color: budget.remaining >= 0
                        ? AppTheme.secondaryColor
                        : AppTheme.errorColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _AmountChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 2),
        Text(
          'EGP ${value.toStringAsFixed(0)}',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 13),
        ),
      ],
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBudgets({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 72, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No budgets yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Set spending limits per category',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
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
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

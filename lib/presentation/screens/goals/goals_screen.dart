import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_router.dart';
import '../../../core/config/theme.dart';
import '../../providers/goal_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../../data/models/goal.dart';
import 'edit_goal_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<GoalProvider>().loadGoals());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      body: Consumer<GoalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return _ErrorView(
                message: provider.error!,
                onRetry: () => provider.loadGoals());
          }
          if (provider.goals.isEmpty) {
            return _EmptyGoals(
              onAdd: () => Navigator.pushNamed(context, AppRouter.addGoal)
                  .then((_) => provider.loadGoals()),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadGoals(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _GoalCard(
                goal: provider.goals[i],
                onEdit: () => _goEdit(provider.goals[i]),
                onAddSavings: () =>
                    _showAddSavingsDialog(provider, provider.goals[i]),
                onDelete: () =>
                    _confirmDelete(provider, provider.goals[i]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRouter.addGoal)
            .then((_) => context.read<GoalProvider>().loadGoals()),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  void _goEdit(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditGoalScreen(goal: goal)),
    ).then((updated) {
      if (updated == true && mounted) context.read<GoalProvider>().loadGoals();
    });
  }

  Future<void> _showAddSavingsDialog(GoalProvider provider, Goal goal) async {
    final walletProvider = context.read<WalletProvider>();
    await walletProvider.loadWallet();
    if (!mounted) return;

    final availableSavings = walletProvider.savings;
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Add to "${goal.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available in wallet: EGP ${availableSavings.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 13,
                  color: availableSavings > 0
                      ? AppTheme.primaryColor
                      : AppTheme.errorColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (EGP)',
                prefixText: 'EGP  ',
                helperText: availableSavings > 0
                    ? 'Max EGP ${availableSavings.toStringAsFixed(0)}'
                    : null,
              ),
              autofocus: true,
              enabled: availableSavings > 0,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: availableSavings > 0
                  ? () => Navigator.pop(dialogCtx, true)
                  : null,
              child: const Text('Add')),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final amount = double.tryParse(controller.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount greater than zero')),
      );
      return;
    }
    if (amount > availableSavings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "You don't have enough savings (max EGP ${availableSavings.toStringAsFixed(0)})")),
      );
      return;
    }

    final updatedGoal = await provider.addSavings(goal.id, amount);
    if (!mounted) return;

    if (updatedGoal != null) {
      walletProvider.loadWallet();
      final isCompleted = updatedGoal.status == 'COMPLETED';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCompleted
              ? '🎉 Goal "${goal.name}" achieved!'
              : 'EGP ${amount.toStringAsFixed(0)} added to ${goal.name}'),
          backgroundColor:
              isCompleted ? AppTheme.successColor : null,
          duration: Duration(seconds: isCompleted ? 4 : 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to add savings')),
      );
    }
  }

  Future<void> _confirmDelete(GoalProvider provider, Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete the goal "${goal.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await provider.deleteGoal(goal.id);
    }
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onAddSavings;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onAddSavings,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final isCompleted = goal.status == 'COMPLETED' || pct >= 1.0;
    final color = isCompleted
        ? AppTheme.successColor
        : pct >= 0.75
            ? AppTheme.primaryColor
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
                  child: Icon(
                      isCompleted ? Icons.check_circle : Icons.flag_outlined,
                      color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 16)),
                      Text(
                        isCompleted
                            ? 'Goal achieved!'
                            : 'Deadline: ${DateFormat('MMM dd, yyyy').format(goal.deadline)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isCompleted ? color : null,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Completed',
                        style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                  onPressed: onEdit,
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
                _StatChip(
                    label: 'Saved',
                    value: 'EGP ${goal.currentAmount.toStringAsFixed(0)}',
                    color: color),
                _StatChip(
                    label: 'Target',
                    value: 'EGP ${goal.targetAmount.toStringAsFixed(0)}',
                    color: AppTheme.primaryColor),
                _StatChip(
                    label: 'Remaining',
                    value: 'EGP ${goal.remaining.abs().toStringAsFixed(0)}',
                    color: goal.remaining <= 0
                        ? AppTheme.successColor
                        : Colors.grey),
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
            if (!isCompleted && goal.daysRemaining > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${goal.daysRemaining} days left',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      'EGP ${goal.monthlySavingRequired.toStringAsFixed(0)}/month needed',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            if (!isCompleted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAddSavings,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Savings'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ],
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGoals({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined,
              size: 72, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No goals yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Start saving toward something meaningful',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Create Goal'),
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

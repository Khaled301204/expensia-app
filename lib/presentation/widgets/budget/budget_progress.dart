import 'package:flutter/material.dart';
import '../../../data/models/budget.dart';
import '../../../core/utils/currency_formatter.dart';

class BudgetProgress extends StatelessWidget {
  final Budget budget;

  const BudgetProgress({
    super.key,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = budget.percentage / 100;
    final isOverBudget = budget.isOverBudget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              budget.categoryName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(budget.spentAmount),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  'of ${CurrencyFormatter.format(budget.limitAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage > 1 ? 1 : percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${budget.percentage.toStringAsFixed(1)}% used',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

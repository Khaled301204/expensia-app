import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../../routes/app_router.dart';
import '../../providers/income_provider.dart';
import '../../../data/models/income.dart';
import 'edit_income_screen.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});
  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncomeProvider>().loadIncomes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text('Income', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.darkBg,
        foregroundColor: AppTheme.darkTextPri,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<IncomeProvider>(builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor));
        }
        if (provider.error != null) {
          return _ErrorView(
            message: provider.error!,
            onRetry: provider.loadIncomes,
          );
        }
        if (provider.incomes.isEmpty) {
          return _EmptyView(onAdd: () =>
            Navigator.pushNamed(context, AppRouter.addIncome)
                .then((_) => provider.loadIncomes()));
        }

        return Column(children: [
          // Total banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${provider.incomes.length} entries',
                  style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 13)),
                Text(
                  'Total: EGP ${provider.totalIncome.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    color: AppTheme.secondaryColor, fontSize: 14, fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Expanded(child: RefreshIndicator(
            onRefresh: provider.loadIncomes,
            color: AppTheme.secondaryColor,
            backgroundColor: AppTheme.darkCard,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: provider.incomes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _IncomeTile(
                income: provider.incomes[i],
                onEdit: () => _goEdit(provider.incomes[i]),
                onDelete: () => _confirmDelete(context, provider, provider.incomes[i]),
              ),
            ),
          )),
        ]);
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRouter.addIncome)
            .then((_) => context.read<IncomeProvider>().loadIncomes()),
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Income', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _goEdit(Income income) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditIncomeScreen(income: income)),
    ).then((updated) {
      if (updated == true && mounted) context.read<IncomeProvider>().loadIncomes();
    });
  }

  Future<void> _confirmDelete(
      BuildContext context, IncomeProvider provider, Income income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Delete Income',
          style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete EGP ${income.amount.toStringAsFixed(2)} from ${income.source}?',
          style: GoogleFonts.inter(color: AppTheme.darkTextSec)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.darkTextSec))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await provider.deleteIncome(income.id);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Delete failed')));
      }
    }
  }
}

class _IncomeTile extends StatelessWidget {
  final Income income;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _IncomeTile({required this.income, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(children: [
        // Icon circle
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_downward_rounded,
            color: AppTheme.secondaryColor, size: 20),
        ),
        const SizedBox(width: 12),

        // Details
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(income.source, style: GoogleFonts.inter(
            color: AppTheme.darkTextPri, fontSize: 15, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 2),
          Row(children: [
            Text(DateFormat('MMM dd, yyyy').format(income.date),
              style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 12)),
            if (income.isRecurring && income.frequency != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (income.recurringActive
                      ? AppTheme.secondaryColor
                      : AppTheme.darkTextMuted).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_friendlyFrequency(income.frequency!),
                  style: GoogleFonts.inter(
                    color: income.recurringActive
                        ? AppTheme.secondaryColor
                        : AppTheme.darkTextMuted,
                    fontSize: 10, fontWeight: FontWeight.w600,
                  )),
              ),
              if (!income.recurringActive) ...[
                const SizedBox(width: 6),
                Text('· Paused',
                  style: GoogleFonts.inter(
                    color: AppTheme.darkTextMuted, fontSize: 11)),
              ] else if (income.nextOccurrence != null) ...[
                const SizedBox(width: 6),
                Text(
                  '· Next: ${DateFormat('MMM dd').format(income.nextOccurrence!)}',
                  style: GoogleFonts.inter(
                    color: AppTheme.darkTextMuted, fontSize: 11)),
              ],
            ],
          ]),
        ])),

        // Amount + delete
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+ EGP ${income.amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              color: AppTheme.secondaryColor, fontSize: 14, fontWeight: FontWeight.w700,
            )),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: onEdit,
              child: const Icon(Icons.edit_outlined, color: AppTheme.darkTextMuted, size: 18),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline, color: AppTheme.darkTextMuted, size: 18),
            ),
          ]),
        ]),
      ]),
    );
  }

  String _friendlyFrequency(String f) => switch (f) {
    'DAILY'    => 'Daily',
    'WEEKLY'   => 'Weekly',
    'MONTHLY'  => 'Monthly',
    'YEARLY'   => 'Yearly',
    _          => 'One-time',
  };
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.account_balance_wallet_outlined,
        size: 72, color: AppTheme.darkTextMuted.withValues(alpha: 0.5)),
      const SizedBox(height: 16),
      Text('No income recorded yet',
        style: GoogleFonts.inter(
          color: AppTheme.darkTextPri, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Add your first income entry',
        style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 14)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: onAdd,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Income', style: GoogleFonts.inter(
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
      const Icon(Icons.error_outline, size: 56, color: AppTheme.errorColor),
      const SizedBox(height: 12),
      Text(message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 14)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  );
}

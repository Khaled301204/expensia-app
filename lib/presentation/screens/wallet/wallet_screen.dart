import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() => Future.wait([
        context.read<WalletProvider>().loadWallet(),
        context.read<DashboardProvider>().loadDashboard(),
        context.read<ExpenseProvider>().loadExpenses(),
        context.read<IncomeProvider>().loadIncomes(),
      ]);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditDialog(double current) {
    final ctrl = TextEditingController(text: current.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Adjust Starting Balance',
            style: GoogleFonts.inter(
                color: AppTheme.darkTextPri, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Set how much you already had saved before using Expensia. '
            'This is added on top of your income/expense calculations.',
            style:
                GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: GoogleFonts.inter(
                color: AppTheme.darkTextPri,
                fontSize: 24,
                fontWeight: FontWeight.w700),
            decoration: const InputDecoration(prefixText: 'EGP  ', hintText: '0.00'),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.darkTextSec)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text.trim());
              if (amount == null || amount < 0) return;
              Navigator.pop(ctx);
              final ok =
                  await context.read<WalletProvider>().updateSavings(amount);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok
                    ? 'Starting balance updated'
                    : (context.read<WalletProvider>().error ??
                        'Update failed')),
                backgroundColor:
                    ok ? AppTheme.successColor : AppTheme.errorColor,
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: AppTheme.darkTextPri,
        surfaceTintColor: Colors.transparent,
        title: Text('My Wallet',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(children: [
        // ── Fixed header ──────────────────────────────────────────────────────
        Consumer2<WalletProvider, DashboardProvider>(
          builder: (_, wallet, dash, __) => Column(children: [
            _NetSavingsCard(
              savings: dash.data.currentSavings,
              isLoading: dash.isLoading,
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              income: dash.data.totalIncome,
              expenses: dash.data.totalExpenses,
              balance: dash.data.currentBalance,
              isLoading: dash.isLoading,
            ),
            const SizedBox(height: 12),
            _StartingBalanceCard(
              currentSavings: wallet.wallet?.currentSavings ?? 0,
              updatedAt: wallet.wallet?.updatedAt,
              isLoading: wallet.isLoading,
              onEdit: () =>
                  _showEditDialog(wallet.wallet?.currentSavings ?? 0),
            ),
            const SizedBox(height: 4),
          ]),
        ),

        // ── Tab bar (pinned) ──────────────────────────────────────────────────
        Container(
          color: AppTheme.darkBg,
          child: TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle:
                GoogleFonts.inter(fontSize: 13),
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.darkTextSec,
            tabs: const [
              Tab(text: 'Recent Expenses'),
              Tab(text: 'Recent Income'),
            ],
          ),
        ),

        // ── Tab content (scrollable) ──────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ExpensesTab(onRefresh: _loadAll),
              _IncomesTab(onRefresh: _loadAll),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Net Savings Hero Card ──────────────────────────────────────────────────────

class _NetSavingsCard extends StatelessWidget {
  final double savings;
  final bool isLoading;
  const _NetSavingsCard({required this.savings, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isPositive = savings >= 0;
    final color = isPositive ? AppTheme.accentGold : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.account_balance_wallet_outlined,
                color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Text('Net Savings',
              style: GoogleFonts.inter(
                  color: AppTheme.darkTextSec, fontSize: 14)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(isPositive ? 'Positive' : 'Negative',
                style: GoogleFonts.inter(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        isLoading
            ? Container(
                height: 44,
                width: 180,
                decoration: BoxDecoration(
                  color: AppTheme.darkElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
              )
            : Text(
                'EGP ${_fmt(savings.abs())}',
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
        if (!isLoading && !isPositive) ...[
          const SizedBox(height: 6),
          Text('You are spending more than you earn',
              style: GoogleFonts.inter(
                  color: AppTheme.errorColor, fontSize: 12)),
        ],
      ]),
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ── Summary Row ────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final double income, expenses, balance;
  final bool isLoading;
  const _SummaryRow({
    required this.income,
    required this.expenses,
    required this.balance,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
            child: _StatCard(
                label: 'Total Income',
                value: income,
                color: AppTheme.secondaryColor,
                icon: Icons.arrow_downward_rounded,
                isLoading: isLoading)),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(
                label: 'Total Spent',
                value: expenses,
                color: AppTheme.errorColor,
                icon: Icons.arrow_upward_rounded,
                isLoading: isLoading)),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(
                label: 'Balance',
                value: balance,
                color: AppTheme.primaryColor,
                icon: Icons.account_balance_outlined,
                isLoading: isLoading)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool isLoading;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.inter(
                      color: AppTheme.darkTextMuted, fontSize: 10)),
              const SizedBox(height: 2),
              isLoading
                  ? Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.darkElevated,
                        borderRadius: BorderRadius.circular(4),
                      ))
                  : Text(
                      'EGP ${value.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
            ]),
      );
}

// ── Starting Balance Card ──────────────────────────────────────────────────────

class _StartingBalanceCard extends StatelessWidget {
  final double currentSavings;
  final DateTime? updatedAt;
  final bool isLoading;
  final VoidCallback onEdit;
  const _StartingBalanceCard({
    required this.currentSavings,
    required this.updatedAt,
    required this.isLoading,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.darkElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(children: [
        const Icon(Icons.tune_outlined,
            color: AppTheme.darkTextSec, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Starting Balance Adjustment',
                    style: GoogleFonts.inter(
                        color: AppTheme.darkTextSec, fontSize: 11)),
                const SizedBox(height: 2),
                isLoading
                    ? Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(4),
                        ))
                    : Text(
                        'EGP ${currentSavings.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                            color: AppTheme.darkTextPri,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                if (updatedAt != null)
                  Text(
                    'Last updated ${DateFormat('MMM dd, yyyy').format(updatedAt!)}',
                    style: GoogleFonts.inter(
                        color: AppTheme.darkTextMuted, fontSize: 10),
                  ),
              ]),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text('Edit',
                style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ── Expenses Tab ───────────────────────────────────────────────────────────────

class _ExpensesTab extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _ExpensesTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(builder: (_, provider, __) {
      if (provider.isLoading) {
        return const Center(
            child: CircularProgressIndicator(
                color: AppTheme.primaryColor));
      }
      if (provider.error != null) {
        return _ErrorView(message: provider.error!, onRetry: onRefresh);
      }
      if (provider.expenses.isEmpty) {
        return const _EmptyView(
          icon: Icons.receipt_long_outlined,
          message: 'No expenses yet',
        );
      }

      final recent = provider.expenses.take(30).toList();
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.darkCard,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: recent.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final e = recent[i];
            return _TxRow(
              icon: Icons.arrow_upward_rounded,
              color: AppTheme.errorColor,
              title: e.merchant ?? e.description ?? e.categoryName,
              subtitle: e.categoryName,
              date: e.date,
              createdAt: e.createdAt,
              amount: -e.amount,
              trailing: e.createdByVoice
                  ? const Icon(Icons.mic,
                      size: 12, color: AppTheme.primaryColor)
                  : null,
            );
          },
        ),
      );
    });
  }
}

// ── Income Tab ─────────────────────────────────────────────────────────────────

class _IncomesTab extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _IncomesTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<IncomeProvider>(builder: (_, provider, __) {
      if (provider.isLoading) {
        return const Center(
            child: CircularProgressIndicator(
                color: AppTheme.secondaryColor));
      }
      if (provider.error != null) {
        return _ErrorView(message: provider.error!, onRetry: onRefresh);
      }
      if (provider.incomes.isEmpty) {
        return const _EmptyView(
          icon: Icons.account_balance_wallet_outlined,
          message: 'No income recorded yet',
        );
      }

      final recent = provider.incomes.take(30).toList();
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppTheme.secondaryColor,
        backgroundColor: AppTheme.darkCard,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: recent.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final inc = recent[i];
            return _TxRow(
              icon: Icons.arrow_downward_rounded,
              color: AppTheme.secondaryColor,
              title: inc.source,
              subtitle: inc.isRecurring && inc.frequency != null
                  ? inc.frequency!
                  : 'One-time',
              date: inc.date,
              amount: inc.amount,
            );
          },
        ),
      );
    });
  }
}

// ── Transaction Row ────────────────────────────────────────────────────────────

class _TxRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime date;
  final DateTime? createdAt;
  final double amount;
  final Widget? trailing;

  const _TxRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.date,
    this.createdAt,
    required this.amount,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: AppTheme.darkTextPri,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        color: AppTheme.darkTextSec, fontSize: 12)),
              ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
            Text(
              '${isPositive ? '+' : '-'} EGP ${amount.abs().toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ]),
          Text(
            createdAt != null
                ? DateFormat('MMM dd, h:mm a').format(createdAt!)
                : DateFormat('MMM dd').format(date),
            style: GoogleFonts.inter(
                color: AppTheme.darkTextMuted, fontSize: 11)),
        ]),
      ]),
    );
  }
}

// ── Empty / Error views ────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              size: 64,
              color: AppTheme.darkTextMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.inter(
                  color: AppTheme.darkTextSec, fontSize: 15)),
        ]),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline,
              size: 52, color: AppTheme.errorColor),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppTheme.darkTextSec, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

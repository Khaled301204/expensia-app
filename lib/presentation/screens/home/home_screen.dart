import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/app_router.dart';
import '../../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/notification_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() => Future.wait([
    context.read<DashboardProvider>().loadDashboard(),
    context.read<BudgetProvider>().loadBudgets(),
    context.read<GoalProvider>().loadGoals(),
    context.read<NotificationProvider>().loadNotifications(),
  ]);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.darkCard,
        child: CustomScrollView(slivers: [
          _buildAppBar(context, user?.name ?? 'User'),
          SliverToBoxAdapter(child: _BalanceHeroCard()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _SectionLabel('Quick Actions'),
              const SizedBox(height: 14),
              const _QuickActions(),
              const SizedBox(height: 32),
              _SectionLabel('Budgets',
                  onSeeAll: () => Navigator.pushNamed(context, AppRouter.budgetList)),
              const SizedBox(height: 14),
              const _BudgetPreview(),
              const SizedBox(height: 32),
              _SectionLabel('Savings Goals',
                  onSeeAll: () => Navigator.pushNamed(context, AppRouter.goals)),
              const SizedBox(height: 14),
              const _GoalsPreview(),
            ])),
          ),
        ]),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Morning' : hour < 17 ? 'Afternoon' : 'Evening';
    return SliverAppBar(
      backgroundColor: AppTheme.darkBg,
      surfaceTintColor: Colors.transparent,
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good $greeting', style: GoogleFonts.inter(
              color: AppTheme.darkTextSec, fontSize: 12, fontWeight: FontWeight.w400,
            )),
            Text(name, style: GoogleFonts.inter(
              color: AppTheme.darkTextPri, fontSize: 16, fontWeight: FontWeight.w700,
            )),
          ]),
          const Spacer(),
          Consumer<NotificationProvider>(builder: (_, p, __) =>
            Stack(clipBehavior: Clip.none, children: [
              _IconBtn(
                icon: Icons.notifications_outlined,
                onTap: () => Navigator.pushNamed(context, AppRouter.notifications),
              ),
              if (p.unreadCount > 0)
                Positioned(top: 0, right: 0, child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                  child: Center(child: Text(
                    '${p.unreadCount > 9 ? 9 : p.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  )),
                )),
            ]),
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.person_outline,
            onTap: () => Navigator.pushNamed(context, AppRouter.profile),
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.logout_outlined,
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, AppRouter.login);
            },
          ),
        ]),
      ),
    );
  }
}

// ── Balance Hero Card ──────────────────────────────────────────────────────────

class _BalanceHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(builder: (_, p, __) =>
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRouter.wallet),
        child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          boxShadow: [AppTheme.blueGlow],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total Balance', style: GoogleFonts.inter(
              color: AppTheme.darkTextSec, fontSize: 13,
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text('This Month', style: GoogleFonts.inter(
                color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.w500,
              )),
            ),
          ]),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: p.data.currentBalance),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, v, __) => Text(
              'EGP ${_fmt(v)}',
              style: GoogleFonts.inter(
                color: AppTheme.darkTextPri, fontSize: 34,
                fontWeight: FontWeight.w800, letterSpacing: -1.0,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _MiniStat(
              label: 'Income', value: p.data.totalIncome,
              icon: Icons.arrow_downward_rounded, color: AppTheme.secondaryColor,
            )),
            Container(width: 1, height: 36, color: AppTheme.darkBorder),
            Expanded(child: _MiniStat(
              label: 'Expenses', value: p.data.totalExpenses,
              icon: Icons.arrow_upward_rounded, color: AppTheme.errorColor,
            )),
            Container(width: 1, height: 36, color: AppTheme.darkBorder),
            Expanded(child: _MiniStat(
              label: 'Savings', value: p.data.currentSavings,
              icon: Icons.savings_outlined, color: AppTheme.accentGold,
            )),
          ]),
        ]),
      ),
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _MiniStat extends StatelessWidget {
  final String label; final double value; final IconData icon; final Color color;
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 11)),
    ]),
    const SizedBox(height: 4),
    TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (_, v, __) => Text(
        'EGP ${v.toStringAsFixed(0)}',
        style: GoogleFonts.inter(
          color: AppTheme.darkTextPri, fontSize: 13, fontWeight: FontWeight.w700,
        ),
      ),
    ),
  ]);
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title; final VoidCallback? onSeeAll;
  const _SectionLabel(this.title, {this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(title,
          style: GoogleFonts.inter(
            color: AppTheme.darkTextPri, fontSize: 17, fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (onSeeAll != null) ...[
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSeeAll,
          child: Text('See all', style: GoogleFonts.inter(
            color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w500,
          )),
        ),
      ],
    ],
  );
}

// ── Quick Actions ──────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _items = [
    _QA('Add Expense',  Icons.remove_circle_outline,           AppTheme.errorColor,     AppRouter.addExpense),
    _QA('Expenses',     Icons.receipt_long_outlined,           AppTheme.primaryColor,   AppRouter.expenseList),
    _QA('Add Income',   Icons.add_circle_outline,              AppTheme.secondaryColor, AppRouter.addIncome),
    _QA('Voice',        Icons.mic_outlined,                    Color(0xFF8B5CF6),        AppRouter.voiceExpense),
    _QA('Budgets',      Icons.account_balance_wallet_outlined, AppTheme.warningColor,   AppRouter.budgetList),
    _QA('Goals',        Icons.flag_outlined,                   AppTheme.accentPurple,   AppRouter.goals),
    _QA('Reports',      Icons.bar_chart_outlined,              Color(0xFF38BDF8),       AppRouter.reports),
    _QA('AI Insights',  Icons.psychology_outlined,             AppTheme.accentGold,     AppRouter.insights),
    _QA('Wallet',       Icons.account_balance_wallet_outlined, Color(0xFF06B6D4),        AppRouter.wallet),
  ];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: Row(children: _items.map((a) => Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, a.route),
        child: Container(
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(a.icon, color: a.color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(a.label, style: GoogleFonts.inter(
              color: AppTheme.darkTextPri, fontSize: 10, fontWeight: FontWeight.w500,
            ), textAlign: TextAlign.center, maxLines: 2),
          ]),
        ),
      ),
    )).toList()),
  );
}

class _QA {
  final String label; final IconData icon; final Color color; final String route;
  const _QA(this.label, this.icon, this.color, this.route);
}

// ── Budget Preview ─────────────────────────────────────────────────────────────

class _BudgetPreview extends StatelessWidget {
  const _BudgetPreview();

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(builder: (_, p, __) {
      if (p.isLoading) return const _Loader();
      if (p.budgets.isEmpty) return _EmptyHint('No budgets yet', 'Create Budget',
          () => Navigator.pushNamed(context, AppRouter.addBudget));
      final sorted = [...p.budgets]..sort((a, b) => b.id.compareTo(a.id));
      return Column(children: sorted.take(3).map((b) {
        final pct = (b.spentAmount / b.limitAmount).clamp(0.0, 1.0);
        final color = b.isOverBudget ? AppTheme.errorColor
            : pct >= b.alertThreshold ? AppTheme.warningColor : AppTheme.secondaryColor;
        return _DarkCard(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(b.categoryName, style: GoogleFonts.inter(
                color: AppTheme.darkTextPri, fontSize: 15, fontWeight: FontWeight.w600,
              )),
              Text('${(pct * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(
                color: color, fontSize: 13, fontWeight: FontWeight.w700,
              )),
            ]),
            const SizedBox(height: 4),
            Text('EGP ${b.spentAmount.toStringAsFixed(0)} of ${b.limitAmount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 12)),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ]),
        );
      }).toList());
    });
  }
}

// ── Goals Preview ──────────────────────────────────────────────────────────────

class _GoalsPreview extends StatelessWidget {
  const _GoalsPreview();

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalProvider>(builder: (_, p, __) {
      if (p.isLoading) return const _Loader();
      if (p.goals.isEmpty) return _EmptyHint('No goals yet', 'Create Goal',
          () => Navigator.pushNamed(context, AppRouter.addGoal));
      return Column(children: p.goals.take(2).map((g) {
        final pct = (g.currentAmount / g.targetAmount).clamp(0.0, 1.0);
        return _DarkCard(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(width: 54, height: 54, child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: pct, strokeWidth: 4.5,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
              ),
              Text('${(pct * 100).toInt()}%', style: GoogleFonts.inter(
                color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w700,
              )),
            ])),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.name, style: GoogleFonts.inter(
                color: AppTheme.darkTextPri, fontSize: 15, fontWeight: FontWeight.w600,
              ), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('EGP ${g.currentAmount.toStringAsFixed(0)} of ${g.targetAmount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 12)),
            ])),
          ]),
        );
      }).toList());
    });
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child; final EdgeInsets? margin;
  const _DarkCard({required this.child, this.margin});

  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.darkBorder),
    ),
    child: child,
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: AppTheme.darkElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Icon(icon, color: AppTheme.darkTextPri, size: 18),
    ),
  );
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Center(child: CircularProgressIndicator()),
  );
}

Widget _EmptyHint(String msg, String action, VoidCallback onTap) =>
  Builder(builder: (context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.darkBorder),
    ),
    child: Row(children: [
      Text(msg, style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 14)),
      const Spacer(),
      GestureDetector(
        onTap: onTap,
        child: Text('+ $action', style: GoogleFonts.inter(
          color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600,
        )),
      ),
    ]),
  ));

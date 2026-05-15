import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/goal_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final goalProvider = context.read<GoalProvider>();

    await Future.wait([
      expenseProvider.loadExpenses(),
      budgetProvider.loadBudgets(),
      goalProvider.loadGoals(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expensia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRouter.login);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                'Welcome, ${user?.name ?? "User"}!',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Here\'s your financial overview',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: 24),
              
              // Quick Stats
              Consumer<ExpenseProvider>(
                builder: (context, expenseProvider, child) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Expenses',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'EGP ${expenseProvider.totalExpenses.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildQuickActionCard(
                    context,
                    'Add Expense',
                    Icons.add_circle_outline,
                    () => Navigator.pushNamed(context, AppRouter.addExpense),
                  ),
                  _buildQuickActionCard(
                    context,
                    'Voice Expense',
                    Icons.mic_outlined,
                    () => Navigator.pushNamed(context, AppRouter.voiceExpense),
                  ),
                  _buildQuickActionCard(
                    context,
                    'Budgets',
                    Icons.account_balance_wallet_outlined,
                    () => Navigator.pushNamed(context, AppRouter.budgetList),
                  ),
                  _buildQuickActionCard(
                    context,
                    'Goals',
                    Icons.flag_outlined,
                    () => Navigator.pushNamed(context, AppRouter.goals),
                  ),
                  _buildQuickActionCard(
                    context,
                    'Reports',
                    Icons.bar_chart_outlined,
                    () => Navigator.pushNamed(context, AppRouter.reports),
                  ),
                  _buildQuickActionCard(
                    context,
                    'All Expenses',
                    Icons.list_alt_outlined,
                    () => Navigator.pushNamed(context, AppRouter.expenseList),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

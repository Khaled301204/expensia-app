class DashboardData {
  final double totalIncome;
  final double totalExpenses;
  final double currentBalance;
  final double currentSavings;
  final int totalBudgets;
  final int activeGoals;

  DashboardData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.currentBalance,
    required this.currentSavings,
    required this.totalBudgets,
    required this.activeGoals,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      currentSavings: (json['currentSavings'] as num?)?.toDouble() ?? 0.0,
      totalBudgets: (json['totalBudgets'] as num?)?.toInt() ?? 0,
      activeGoals: (json['activeGoals'] as num?)?.toInt() ?? 0,
    );
  }

  factory DashboardData.empty() => DashboardData(
        totalIncome: 0,
        totalExpenses: 0,
        currentBalance: 0,
        currentSavings: 0,
        totalBudgets: 0,
        activeGoals: 0,
      );
}

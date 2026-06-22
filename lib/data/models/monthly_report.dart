class MonthlyReport {
  final int? month;
  final int? year;
  final double totalExpenses;
  final double totalIncome;
  final double netSavings;
  final List<CategoryBreakdown> categoryBreakdown;

  MonthlyReport({
    this.month,
    this.year,
    required this.totalExpenses,
    required this.totalIncome,
    required this.netSavings,
    required this.categoryBreakdown,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    final List raw = json['categoryBreakdown'] as List? ?? [];
    return MonthlyReport(
      month: json['month'] as int?,
      year: json['year'] as int?,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      totalIncome:   (json['totalIncome']   as num?)?.toDouble() ?? 0.0,
      netSavings:    (json['netSavings']    as num?)?.toDouble() ?? 0.0,
      categoryBreakdown: raw.map((e) => CategoryBreakdown.fromJson(e)).toList(),
    );
  }

  factory MonthlyReport.empty() => MonthlyReport(
    totalExpenses: 0, totalIncome: 0, netSavings: 0, categoryBreakdown: [],
  );
}

class CategoryBreakdown {
  final String category;
  final double amount;
  final double percentage;

  CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      CategoryBreakdown(
        category:   json['category']?.toString()   ?? json['categoryName']?.toString() ?? '',
        amount:     (json['amount']     as num?)?.toDouble()     ?? 0.0,
        percentage: (json['percentage'] as num?)?.toDouble()     ?? 0.0,
      );
}

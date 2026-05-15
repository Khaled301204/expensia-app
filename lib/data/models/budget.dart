class Budget {
  final int id;
  final int userId;
  final int categoryId;
  final String categoryName;
  final double limitAmount;
  final double spentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final double alertThreshold;
  final bool isOverBudget;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.limitAmount,
    required this.spentAmount,
    required this.startDate,
    required this.endDate,
    this.alertThreshold = 0.80,
    this.isOverBudget = false,
  });

  double get remaining => limitAmount - spentAmount;
  double get percentage => (spentAmount / limitAmount) * 100;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] ?? json['budgetId'],
      userId: json['userId'],
      categoryId: json['categoryId'],
      categoryName: json['category'] ?? json['categoryName'] ?? 'Other',
      limitAmount: (json['limitAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 0.80,
      isOverBudget: json['isOverBudget'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'category': categoryName,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'alertThreshold': alertThreshold,
      'isOverBudget': isOverBudget,
    };
  }
}

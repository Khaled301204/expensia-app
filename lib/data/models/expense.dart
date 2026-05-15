class Expense {
  final int id;
  final int userId;
  final int categoryId;
  final String categoryName;
  final double amount;
  final DateTime date;
  final String? paymentMethod;
  final String? description;
  final String? merchant;
  final bool isRecurring;
  final bool createdByVoice;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.date,
    this.paymentMethod,
    this.description,
    this.merchant,
    this.isRecurring = false,
    this.createdByVoice = false,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? json['expenseId'],
      userId: json['userId'],
      categoryId: json['categoryId'],
      categoryName: json['category'] ?? json['categoryName'] ?? 'Other',
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      paymentMethod: json['paymentMethod'],
      description: json['description'],
      merchant: json['merchant'],
      isRecurring: json['isRecurring'] ?? false,
      createdByVoice: json['createdByVoice'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'category': categoryName,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'description': description,
      'merchant': merchant,
      'isRecurring': isRecurring,
      'createdByVoice': createdByVoice,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

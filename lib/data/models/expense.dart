class Expense {
  final int id;
  final int userId;
  final int? categoryId;
  final String categoryName;
  final double amount;
  final DateTime date;
  final String? paymentMethod;
  final String? description;
  final String? merchant;
  final bool isRecurring;
  final String? frequency;
  final DateTime? nextOccurrence;
  final bool recurringActive;
  final bool createdByVoice;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.date,
    this.paymentMethod,
    this.description,
    this.merchant,
    this.isRecurring = false,
    this.frequency,
    this.nextOccurrence,
    this.recurringActive = true,
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
      frequency: json['frequency'],
      nextOccurrence: json['nextOccurrence'] != null
          ? DateTime.parse(json['nextOccurrence'])
          : null,
      recurringActive: json['recurringActive'] ?? true,
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

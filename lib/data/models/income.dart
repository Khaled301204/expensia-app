class Income {
  final int id;
  final int userId;
  final double amount;
  final DateTime date;
  final String source;
  final String? frequency;
  final bool isRecurring;

  Income({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.source,
    this.frequency,
    this.isRecurring = false,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] ?? json['incomeId'],
      userId: json['userId'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      source: json['source'],
      frequency: json['frequency'],
      isRecurring: json['isRecurring'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'source': source,
      'frequency': frequency,
      'isRecurring': isRecurring,
    };
  }
}

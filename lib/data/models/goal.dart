class Goal {
  final int id;
  final int userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String status;
  final DateTime deadline;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
    required this.deadline,
    required this.createdAt,
  });

  double get remaining => targetAmount - currentAmount;
  double get progress => (currentAmount / targetAmount) * 100;
  
  int get daysRemaining {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }
  
  double get monthlySavingRequired {
    if (daysRemaining <= 0) return 0;
    final monthsRemaining = daysRemaining / 30;
    return remaining / monthsRemaining;
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] ?? json['goalId'],
      userId: json['userId'],
      name: json['name'],
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'ACTIVE',
      deadline: DateTime.parse(json['deadline']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'status': status,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

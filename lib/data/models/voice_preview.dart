class VoicePreview {
  final double amount;
  final String? merchant;
  final String? description;
  final DateTime date;
  final int? categoryId;
  final String? categoryName;
  final double? categoryConfidence;

  VoicePreview({
    required this.amount,
    this.merchant,
    this.description,
    required this.date,
    this.categoryId,
    this.categoryName,
    this.categoryConfidence,
  });

  factory VoicePreview.fromJson(Map<String, dynamic> json) {
    return VoicePreview(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      merchant: json['merchant'],
      description: json['description'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      categoryConfidence: (json['categoryConfidence'] as num?)?.toDouble(),
    );
  }

  VoicePreview copyWith({
    double? amount,
    String? merchant,
    String? description,
    DateTime? date,
    int? categoryId,
    String? categoryName,
  }) {
    return VoicePreview(
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryConfidence: categoryConfidence,
    );
  }

  Map<String, dynamic> toConfirmJson() {
    return {
      'amount': amount,
      if (merchant != null) 'merchant': merchant,
      if (description != null) 'description': description,
      'date': date.toIso8601String(),
      if (categoryId != null) 'categoryId': categoryId,
    };
  }
}

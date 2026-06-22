class Wallet {
  final int id;
  final double currentSavings;
  final DateTime? updatedAt;

  Wallet({required this.id, required this.currentSavings, this.updatedAt});

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    id:             json['walletId'] ?? json['id'] ?? 0,
    currentSavings: (json['currentSavings'] as num?)?.toDouble() ?? 0.0,
    updatedAt:      json['updatedAt'] != null
                      ? DateTime.tryParse(json['updatedAt'])
                      : null,
  );
}

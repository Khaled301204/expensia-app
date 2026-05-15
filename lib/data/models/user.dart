class User {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final String? riskPreference;
  final DateTime createdAt;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.riskPreference,
    required this.createdAt,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'] ?? json['userId'],
    email: json['email'],
    name: json['name'],
    phone: json['phone'],
    riskPreference: json['riskPreference'],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    isActive: json['isActive'] ?? true,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'riskPreference': riskPreference,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? name,
    String? phone,
    String? riskPreference,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      riskPreference: riskPreference ?? this.riskPreference,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? json['categoryId'],
      name: json['name'] ?? json['categoryName'] ?? '',
    );
  }
}

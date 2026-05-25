class Category {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final String color;
  final int order;
  final String? imageUrl; // 👈 ADDED

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.color,
    required this.order,
    this.imageUrl, // 👈 ADDED
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['_id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
      icon: map['icon'] ?? 'category',
      color: map['color'] ?? '#3B82F6',
      order: map['order'] ?? 0,
      imageUrl: map['imageUrl'], // 👈 ADDED
    );
  }
}

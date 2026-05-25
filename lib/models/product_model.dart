class Product {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final double price;
  final String imageUrl;
  final List<String>? images;
  final double? rating;
  final String category;
  final int? maxStock;
  final bool? isDeal; // 👈 ADDED
  final bool? isNewArrival; // 👈 ADDED

  Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.images,
    this.rating,
    required this.category,
    this.maxStock,
    this.isDeal, // 👈 ADDED
    this.isNewArrival, // 👈 ADDED
  });

  int get discountPercentage => 20 + (id.hashCode % 40);

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['image'] ?? map['imageUrl'] ?? '',
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      rating: map['rating']?.toDouble(),
      category: map['category'] ?? 'bike',
      maxStock: map['maxStock'],
      isDeal: map['isDeal'] ?? false, // 👈 ADDED
      isNewArrival: map['isNewArrival'] ?? false, // 👈 ADDED
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'images': images,
      'rating': rating,
      'category': category,
      'maxStock': maxStock,
      'isDeal': isDeal, // 👈 ADDED
      'isNewArrival': isNewArrival, // 👈 ADDED
    };
  }
}

// models/user_service.dart
class UserService {
  final int? id;
  final String userId; // Lien avec l'utilisateur
  final String title;
  final String description;
  final String category;
  final double price;
  final String priceType;
  final List<String> images;
  final String location;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserService({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.priceType,
    required this.images,
    required this.location,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Ajoutez cette méthode pour faciliter la création
  factory UserService.create({
    required String userId,
    required String title,
    required String description,
    required String category,
    required double price,
    required String priceType,
    required List<String> images,
    required String location,
  }) {
    final now = DateTime.now();
    return UserService(
      userId: userId,
      title: title,
      description: description,
      category: category,
      price: price,
      priceType: priceType,
      images: images,
      location: location,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Reste de votre code existant...
  String get formattedPrice {
    switch (priceType) {
      case 'hourly': return '${price.toStringAsFixed(2)} DT / h';
      case 'fixed': return '${price.toStringAsFixed(2)} DT';
      case 'negotiable': return 'Prix négociable';
      default: return '${price.toStringAsFixed(2)} DT';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'priceType': priceType,
      'images': images.join(','),
      'location': location,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserService.fromMap(Map<String, dynamic> map) {
    return UserService(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      priceType: map['priceType'] as String,
      images: (map['images'] as String).isEmpty ? [] : (map['images'] as String).split(','),
      location: map['location'] as String,
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
   UserService copyWith({
    int? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    double? price,
    String? priceType,
    List<String>? images,
    String? location,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserService(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      images: images ?? this.images,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

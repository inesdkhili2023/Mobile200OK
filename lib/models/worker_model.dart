import 'package:latlong2/latlong.dart';
import 'dart:math';

class WorkerModel {
  final int? id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String workType;
  final int yearsOfExperience;
  final double rating;
  final int price;
  final bool isSelected;
  final String? profileImage;
  final List<String>? portfolioImages;
  final int? totalReviews;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? address;

  const WorkerModel({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.workType,
    required this.yearsOfExperience,
    this.rating = 0.0,
    required this.price,
    this.isSelected = false,
    this.profileImage,
    this.portfolioImages,
    this.totalReviews,
    this.description,
    this.latitude,
    this.longitude,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'workType': workType,
      'yearsOfExperience': yearsOfExperience,
      'rating': rating,
      'price': price,
      'isSelected': isSelected ? 1 : 0,
      'profileImage': profileImage,
      'portfolioImages': portfolioImages?.join(','),
      'totalReviews': totalReviews,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory WorkerModel.fromMap(Map<String, dynamic> map) {
    return WorkerModel(
      id: map['id'],
      fullName: map['fullName'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      workType: map['workType'],
      yearsOfExperience: map['yearsOfExperience'],
      rating: map['rating']?.toDouble() ?? 0.0,
      price: map['price'],
      isSelected: map['isSelected'] == 1,
      profileImage: map['profileImage'],
      portfolioImages: map['portfolioImages'] != null && 
          map['portfolioImages'].toString().isNotEmpty
          ? (map['portfolioImages'] as String).split(',')
          : null,
      totalReviews: map['totalReviews'],
      description: map['description'],
      latitude: map['latitude'] != null ? double.parse(map['latitude'].toString()) : null,
      longitude: map['longitude'] != null ? double.parse(map['longitude'].toString()) : null,
      address: map['address'],
    );
  }

  WorkerModel copyWith({
    int? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? workType,
    int? yearsOfExperience,
    double? rating,
    int? price,
    bool? isSelected,
    String? profileImage,
    List<String>? portfolioImages,
    int? totalReviews,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      workType: workType ?? this.workType,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      isSelected: isSelected ?? this.isSelected,
      profileImage: profileImage ?? this.profileImage,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      totalReviews: totalReviews ?? this.totalReviews,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  // Méthodes utilitaires
  int get calculatedReviews => (rating * 20).toInt();

  bool get hasPortfolio => portfolioImages != null && portfolioImages!.isNotEmpty;

  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;

  bool get hasLocation => latitude != null && longitude != null;

  String get experienceText {
    if (yearsOfExperience == 1) {
      return '1 an d\'expérience';
    }
    return '$yearsOfExperience ans d\'expérience';
  }

  String get ratingText => rating.toStringAsFixed(1);

  String get priceText => '$price DT/heure';

  String get locationText {
    if (address != null && address!.isNotEmpty) {
      return address!;
    }
    if (hasLocation) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    return 'Localisation non spécifiée';
  }

  @override
  String toString() {
    return 'WorkerModel(id: $id, fullName: $fullName, workType: $workType, rating: $rating, price: $price, location: $locationText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkerModel &&
        other.id == id &&
        other.fullName == fullName &&
        other.phoneNumber == phoneNumber &&
        other.email == email &&
        other.workType == workType &&
        other.yearsOfExperience == yearsOfExperience &&
        other.rating == rating &&
        other.price == price &&
        other.isSelected == isSelected &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.address == address;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        fullName.hashCode ^
        phoneNumber.hashCode ^
        email.hashCode ^
        workType.hashCode ^
        yearsOfExperience.hashCode ^
        rating.hashCode ^
        price.hashCode ^
        isSelected.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        address.hashCode;
  }

  // Méthode pour valider les données
  bool isValid() {
    return fullName.isNotEmpty &&
        phoneNumber.isNotEmpty &&
        email.isNotEmpty &&
        email.contains('@') &&
        workType.isNotEmpty &&
        yearsOfExperience >= 0 &&
        rating >= 0 && rating <= 5 &&
        price > 0;
  }

  // Méthode pour valider avec localisation
  bool isValidWithLocation() {
    return isValid() && latitude != null && longitude != null;
  }

  // Méthode pour obtenir un objet JSON
  Map<String, dynamic> toJson() => toMap();

  // Méthode pour créer depuis JSON
  factory WorkerModel.fromJson(Map<String, dynamic> json) => WorkerModel.fromMap(json);

  // Méthode pour créer un LatLng à partir des coordonnées (pour OpenStreetMap)
  LatLng? get latLng {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }

  // Méthode pour calculer la distance entre deux workers (en km)
  double? distanceTo(WorkerModel other) {
    if (!hasLocation || !other.hasLocation) return null;
    
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    double lat1 = latitude! * (pi / 180);
    double lon1 = longitude! * (pi / 180);
    double lat2 = other.latitude! * (pi / 180);
    double lon2 = other.longitude! * (pi / 180);
    
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  // Méthode pour formater la distance
  String? formattedDistanceTo(WorkerModel other) {
    final distance = distanceTo(other);
    if (distance == null) return null;
    
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }
}
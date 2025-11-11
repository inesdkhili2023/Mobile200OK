class User {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String profilePhotoUrl;
  final String? password; // Store for login validation, but not in profile

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.profilePhotoUrl = '',
    this.password,
  });

  // Convert User to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'profilePhotoUrl': profilePhotoUrl,
      'password': password,
    };
  }

  // Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] ?? '',
      password: json['password'],
    );
  }
}
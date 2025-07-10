enum UserRole { user, driver }

class UserModel {
  final String? id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String? birthDate;
  final String? gender;
  final String? city;

  UserModel({
    this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.birthDate,
    this.gender,
    this.city,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'user',
      birthDate: json['birth_date'],
      gender: json['gender'],
      city: json['city'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'birth_date': birthDate,
      'gender': gender,
      'city': city,
    };
  }
}

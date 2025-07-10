import 'user_model.dart';

enum DriverStatus { pending, approved, rejected, online, offline }

class DriverModel extends UserModel {
  final String? carModel;
  final String? carNumber;
  final String? licenseNumber;
  final DriverStatus status;
  final String? passportUrl;
  final String? driverLicenseUrl;
  final bool documentsVerified;
  final String rating;

  DriverModel({
    required super.id,
    required super.email,
    String? firstName,
    String? lastName,
    super.phone,
    super.avatarUrl,
    DateTime? createdAt,
    this.carModel,
    this.carNumber,
    this.licenseNumber,
    this.status = DriverStatus.pending,
    this.passportUrl,
    this.driverLicenseUrl,
    this.documentsVerified = false,
    this.rating = '0.0',
    super.birthDate,
    super.gender,
    super.city,
  }) : super(
         fullName: [firstName ?? '', lastName ?? ''].join(' ').trim(),
         role: 'driver',
       );

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      carModel: json['car_model'],
      carNumber: json['car_number'],
      licenseNumber: json['license_number'],
      status: _parseDriverStatus(json['status']),
      passportUrl: json['passport_url'],
      driverLicenseUrl: json['driver_license_url'],
      documentsVerified: json['documents_verified'] ?? false,
      rating: json['rating']?.toString() ?? '0.0',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    final driverJson = {
      'car_model': carModel,
      'car_number': carNumber,
      'license_number': licenseNumber,
      'status': status.toString().split('.').last,
      'passport_url': passportUrl,
      'driver_license_url': driverLicenseUrl,
      'documents_verified': documentsVerified,
      'rating': rating,
    };
    return {...baseJson, ...driverJson};
  }

  static DriverStatus _parseDriverStatus(String? status) {
    if (status == null) return DriverStatus.pending;

    switch (status) {
      case 'approved':
        return DriverStatus.approved;
      case 'rejected':
        return DriverStatus.rejected;
      case 'online':
        return DriverStatus.online;
      case 'offline':
        return DriverStatus.offline;
      default:
        return DriverStatus.pending;
    }
  }
}

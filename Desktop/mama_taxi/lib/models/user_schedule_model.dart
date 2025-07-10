import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserScheduledRide {
  final String id;
  final String userId;
  final String? driverId;
  final String startAddress;
  final String endAddress;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double price;
  final DateTime scheduledDate;
  final String status; // scheduled, inProgress, completed, cancelled
  final String? childName;
  final int? childAge;
  final String? childPhotoUrl;
  final String? driverName;
  final String? driverPhotoUrl;
  final String? driverRating;

  const UserScheduledRide({
    required this.id,
    required this.userId,
    this.driverId,
    required this.startAddress,
    required this.endAddress,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.price,
    required this.scheduledDate,
    required this.status,
    this.childName,
    this.childAge,
    this.childPhotoUrl,
    this.driverName,
    this.driverPhotoUrl,
    this.driverRating,
  });

  // Получение отформатированного времени поездки
  String get formattedTime => DateFormat('HH:mm').format(scheduledDate);

  // Получение отформатированной даты поездки
  String get formattedDate => DateFormat('dd MMMM', 'ru').format(scheduledDate);

  // Получение строки "время • дата"
  String get formattedDateTime =>
      '$formattedTime • ${DateFormat('dd MMMM', 'ru').format(scheduledDate)}';

  // Преобразует объект в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'driver_id': driverId,
      'start_address': startAddress,
      'end_address': endAddress,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'price': price,
      'scheduled_date': scheduledDate.toIso8601String(),
      'status': status,
      'child_name': childName,
      'child_age': childAge,
      'child_photo_url': childPhotoUrl,
      'driver_name': driverName,
      'driver_photo_url': driverPhotoUrl,
      'driver_rating': driverRating,
    };
  }

  // Создает объект из JSON
  factory UserScheduledRide.fromJson(Map<String, dynamic> json) {
    return UserScheduledRide(
      id: json['id'],
      userId: json['user_id'],
      driverId: json['driver_id'],
      startAddress: json['start_address'],
      endAddress: json['end_address'],
      startLat: json['start_lat']?.toDouble() ?? 0.0,
      startLng: json['start_lng']?.toDouble() ?? 0.0,
      endLat: json['end_lat']?.toDouble() ?? 0.0,
      endLng: json['end_lng']?.toDouble() ?? 0.0,
      price: json['price']?.toDouble() ?? 0.0,
      scheduledDate: DateTime.parse(json['scheduled_date']),
      status: json['status'] ?? 'scheduled',
      childName: json['child_name'],
      childAge: json['child_age'],
      childPhotoUrl: json['child_photo_url'],
      driverName: json['driver_name'],
      driverPhotoUrl: json['driver_photo_url'],
      driverRating: json['driver_rating'],
    );
  }

  // Создает копию с новыми значениями
  UserScheduledRide copyWith({
    String? id,
    String? userId,
    String? driverId,
    String? startAddress,
    String? endAddress,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    double? price,
    DateTime? scheduledDate,
    String? status,
    String? childName,
    int? childAge,
    String? childPhotoUrl,
    String? driverName,
    String? driverPhotoUrl,
    String? driverRating,
  }) {
    return UserScheduledRide(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      startAddress: startAddress ?? this.startAddress,
      endAddress: endAddress ?? this.endAddress,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      price: price ?? this.price,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      childName: childName ?? this.childName,
      childAge: childAge ?? this.childAge,
      childPhotoUrl: childPhotoUrl ?? this.childPhotoUrl,
      driverName: driverName ?? this.driverName,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      driverRating: driverRating ?? this.driverRating,
    );
  }
}

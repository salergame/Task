import 'package:flutter/foundation.dart';

enum RideType { regular, childTaxi, premium, delivery }

class DriverScheduleItem {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final RideType rideType;
  final double fare;
  final String pickupAddress;
  final String dropoffAddress;
  final Map<String, dynamic>? specialRequirements;

  DriverScheduleItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.rideType,
    required this.fare,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.specialRequirements,
  });

  factory DriverScheduleItem.fromJson(Map<String, dynamic> json) {
    return DriverScheduleItem(
      id: json['id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      rideType: _parseRideType(json['ride_type']),
      fare: (json['fare'] as num).toDouble(),
      pickupAddress: json['pickup_address'],
      dropoffAddress: json['dropoff_address'],
      specialRequirements: json['special_requirements'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'ride_type': describeEnum(rideType),
      'fare': fare,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'special_requirements': specialRequirements,
    };
  }

  static RideType _parseRideType(String? type) {
    if (type == null) return RideType.regular;

    switch (type) {
      case 'childTaxi':
        return RideType.childTaxi;
      case 'premium':
        return RideType.premium;
      case 'delivery':
        return RideType.delivery;
      default:
        return RideType.regular;
    }
  }
}

class DriverSchedule {
  final List<DriverScheduleItem> items;
  final DateTime date;

  DriverSchedule({
    required this.items,
    required this.date,
  });

  factory DriverSchedule.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List)
        .map((item) => DriverScheduleItem.fromJson(item))
        .toList();

    return DriverSchedule(
      items: items,
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'date': date.toIso8601String(),
    };
  }
}

String describeEnum(Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}

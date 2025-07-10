import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class AppLatLong {
  final double lat;
  final double long;

  const AppLatLong({required this.lat, required this.long});
}

class LocationService {
  Future<bool> checkPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    await Permission.location.request();
    return checkPermission();
  }

  Future<AppLatLong?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return AppLatLong(lat: position.latitude, long: position.longitude);
    } catch (e) {
      debugPrint('Ошибка при получении местоположения: $e');
      return null;
    }
  }
}

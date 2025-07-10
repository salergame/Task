import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_schedule_model.dart';
import 'supabase_service.dart';

class DriverScheduleService {
  final SupabaseService _supabaseService;

  DriverScheduleService({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<DriverScheduleItem>> getDriverScheduleForDay(
      String driverId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await _client
          .from('driver_schedules')
          .select()
          .eq('driver_id', driverId)
          .gte('start_time', startOfDay.toIso8601String())
          .lte('start_time', endOfDay.toIso8601String())
          .order('start_time');

      if (response.isEmpty) {
        return [];
      }

      return response
          .map<DriverScheduleItem>((item) => DriverScheduleItem.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting driver schedule: $e');
      return [];
    }
  }

  Future<List<DriverScheduleItem>> getDriverScheduleForMonth(
      String driverId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final response = await _client
          .from('driver_schedules')
          .select()
          .eq('driver_id', driverId)
          .gte('start_time', startOfMonth.toIso8601String())
          .lte('start_time', endOfMonth.toIso8601String())
          .order('start_time');

      if (response.isEmpty) {
        return [];
      }

      return response
          .map<DriverScheduleItem>((item) => DriverScheduleItem.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting driver schedule: $e');
      return [];
    }
  }

  Future<List<DriverScheduleItem>> getDriverScheduleForWeek(
      String driverId, DateTime weekStartDate) async {
    try {
      final startOfWeek =
          DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day);
      final endOfWeek = startOfWeek
          .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final response = await _client
          .from('driver_schedules')
          .select()
          .eq('driver_id', driverId)
          .gte('start_time', startOfWeek.toIso8601String())
          .lte('start_time', endOfWeek.toIso8601String())
          .order('start_time');

      if (response.isEmpty) {
        return [];
      }

      return response
          .map<DriverScheduleItem>((item) => DriverScheduleItem.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting driver schedule: $e');
      return [];
    }
  }

  Future<bool> updateDriverStatus(String driverId, bool isAvailable) async {
    try {
      // Если это текущий пользователь, используем существующий метод в SupabaseService
      if (driverId == _supabaseService.currentUserId) {
        return await _supabaseService.updateDriverOnlineStatus(isAvailable);
      } else {
        // Для других водителей обновляем напрямую
        await _client.from('drivers').update({
          'status': isAvailable ? 'online' : 'offline',
        }).eq('user_id', driverId);
        return true;
      }
    } catch (e) {
      debugPrint('Error updating driver status: $e');
      return false;
    }
  }

  // Метод для тестовых данных, в реальном приложении данные будут из Supabase
  List<DriverScheduleItem> getMockSchedule() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      DriverScheduleItem(
        id: '1',
        startTime: DateTime(today.year, today.month, today.day, 9, 0),
        endTime: DateTime(today.year, today.month, today.day, 10, 30),
        rideType: RideType.regular,
        fare: 850,
        pickupAddress: 'ул. Ленина, 45',
        dropoffAddress: 'ул. Пушкина, 12',
        specialRequirements: null,
      ),
      DriverScheduleItem(
        id: '2',
        startTime: DateTime(today.year, today.month, today.day, 11, 0),
        endTime: DateTime(today.year, today.month, today.day, 12, 0),
        rideType: RideType.childTaxi,
        fare: 1200,
        pickupAddress: 'ул. Гагарина, 78',
        dropoffAddress: 'Садик №5',
        specialRequirements: {
          'childSeat': {'required': true, 'age': '7-12'}
        },
      ),
    ];
  }
}

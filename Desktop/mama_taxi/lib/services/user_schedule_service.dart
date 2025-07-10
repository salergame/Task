import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_schedule_model.dart';
import 'supabase_service.dart';

class UserScheduleService {
  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseService _supabaseService;

  // Стрим контроллер для списка запланированных поездок
  final StreamController<List<UserScheduledRide>> _scheduledRidesController =
      StreamController<List<UserScheduledRide>>.broadcast();

  // Стрим для подписки на изменения списка запланированных поездок
  Stream<List<UserScheduledRide>> get scheduledRidesStream =>
      _scheduledRidesController.stream;

  // Кэш запланированных поездок
  List<UserScheduledRide> _scheduledRides = [];

  UserScheduleService({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  // Получить все запланированные поездки пользователя
  Future<List<UserScheduledRide>> getScheduledRides() async {
    if (!_supabaseService.isAuthenticated) {
      return [];
    }

    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        return [];
      }

      final response = await _client
          .from('scheduled_rides')
          .select('*, profiles!driver_id(*)')
          .eq('user_id', userId)
          .order('scheduled_date', ascending: true);

      final rides = (response as List).map((data) {
        // Добавляем информацию о водителе из связанной таблицы
        final driverInfo = data['profiles'] as Map<String, dynamic>?;
        if (driverInfo != null) {
          data['driver_name'] = driverInfo['full_name'];
          data['driver_photo_url'] = driverInfo['profile_image_url'];
          data['driver_rating'] = driverInfo['rating']?.toString();
        }

        return UserScheduledRide.fromJson(data);
      }).toList();

      // Обновляем кэш и уведомляем подписчиков
      _scheduledRides = rides;
      _scheduledRidesController.add(_scheduledRides);

      return rides;
    } catch (e) {
      debugPrint('Ошибка получения запланированных поездок: $e');
      return [];
    }
  }

  // Получить запланированные поездки пользователя на определенную дату
  Future<List<UserScheduledRide>> getScheduledRidesForDate(
      DateTime date) async {
    if (!_supabaseService.isAuthenticated) {
      return [];
    }

    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        return [];
      }

      // Устанавливаем начало и конец дня
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await _client
          .from('scheduled_rides')
          .select('*, profiles!driver_id(*)')
          .eq('user_id', userId)
          .gte('scheduled_date', startOfDay.toIso8601String())
          .lte('scheduled_date', endOfDay.toIso8601String())
          .order('scheduled_date', ascending: true);

      return (response as List).map((data) {
        // Добавляем информацию о водителе из связанной таблицы
        final driverInfo = data['profiles'] as Map<String, dynamic>?;
        if (driverInfo != null) {
          data['driver_name'] = driverInfo['full_name'];
          data['driver_photo_url'] = driverInfo['profile_image_url'];
          data['driver_rating'] = driverInfo['rating']?.toString();
        }

        return UserScheduledRide.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Ошибка получения запланированных поездок на дату: $e');
      return [];
    }
  }

  // Создать новую запланированную поездку
  Future<UserScheduledRide?> createScheduledRide({
    required String startAddress,
    required String endAddress,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required double price,
    required DateTime scheduledDate,
    String? childName,
    int? childAge,
    String? childPhotoUrl,
  }) async {
    if (!_supabaseService.isAuthenticated) {
      return null;
    }

    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        return null;
      }

      final response = await _client
          .from('scheduled_rides')
          .insert({
            'user_id': userId,
            'start_address': startAddress,
            'end_address': endAddress,
            'start_lat': startLat,
            'start_lng': startLng,
            'end_lat': endLat,
            'end_lng': endLng,
            'price': price,
            'scheduled_date': scheduledDate.toIso8601String(),
            'status': 'scheduled',
            'child_name': childName,
            'child_age': childAge,
            'child_photo_url': childPhotoUrl,
          })
          .select()
          .single();

      if (response == null) {
        return null;
      }

      final newRide = UserScheduledRide.fromJson(response);

      // Обновляем кэш и уведомляем подписчиков
      await getScheduledRides();

      return newRide;
    } catch (e) {
      debugPrint('Ошибка создания запланированной поездки: $e');
      return null;
    }
  }

  // Обновить запланированную поездку
  Future<bool> updateScheduledRide(
      String rideId, Map<String, dynamic> updateData) async {
    if (!_supabaseService.isAuthenticated) {
      return false;
    }

    try {
      await _client.from('scheduled_rides').update(updateData).eq('id', rideId);

      // Обновляем кэш и уведомляем подписчиков
      await getScheduledRides();

      return true;
    } catch (e) {
      debugPrint('Ошибка обновления запланированной поездки: $e');
      return false;
    }
  }

  // Отменить запланированную поездку
  Future<bool> cancelScheduledRide(String rideId) async {
    return await updateScheduledRide(rideId, {'status': 'cancelled'});
  }

  // Метод для подписки на изменения запланированных поездок
  Future<void> subscribeToScheduledRides() async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) return;

      // Получаем начальные данные
      await getScheduledRides();

      // Подписываемся на изменения в таблице запланированных поездок через канал Supabase
      _client
          .channel('public:scheduled_rides')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'scheduled_rides',
            callback: (payload) async {
              // Проверяем, что изменение касается наших поездок
              final record = payload.newRecord ?? payload.oldRecord;
              if (record != null && record['user_id'] == userId) {
                // Обновляем список запланированных поездок
                await getScheduledRides();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Ошибка подписки на запланированные поездки: $e');
    }
  }

  // Получить демо-данные (для отладки)
  List<UserScheduledRide> getDemoScheduledRides() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      UserScheduledRide(
        id: '1',
        userId: 'user-1',
        startAddress: 'ул. Пушкина, 10',
        endAddress: 'Школа №5, ул. Ленина, 25',
        startLat: 55.751244,
        startLng: 37.618423,
        endLat: 55.755814,
        endLng: 37.617635,
        price: 450,
        scheduledDate: DateTime(today.year, today.month, today.day, 8, 0),
        status: 'scheduled',
        childName: 'Петя',
        childAge: 8,
        childPhotoUrl: 'https://example.com/child1.jpg',
      ),
      UserScheduledRide(
        id: '2',
        userId: 'user-1',
        startAddress: 'ул. Пушкина, 10',
        endAddress: 'Спорт комплекс, ул. Ленина, 15',
        startLat: 55.751244,
        startLng: 37.618423,
        endLat: 55.755814,
        endLng: 37.617635,
        price: 300,
        scheduledDate: DateTime(today.year, today.month, today.day, 12, 0),
        status: 'scheduled',
        childName: 'Петя',
        childAge: 8,
        childPhotoUrl: 'https://example.com/child1.jpg',
      ),
    ];
  }

  // Освобождаем ресурсы при завершении работы
  void dispose() {
    _scheduledRidesController.close();
  }
}

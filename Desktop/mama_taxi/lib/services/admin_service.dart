import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mama_taxi/services/supabase_service.dart';

/// Сервис для работы с админ-панелью, используя Supabase напрямую.
class AdminService {
  static final AdminService _instance = AdminService._internal();

  factory AdminService() {
    return _instance;
  }

  AdminService._internal();

  // Получение Supabase клиента
  SupabaseClient get _client => Supabase.instance.client;

  /// Проверка, является ли текущий пользователь администратором
  Future<bool> isAdmin() async {
    try {
      if (!SupabaseService().isAuthenticated) return false;

      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', SupabaseService().currentUserId as Object)
          .single();

      return response['role'] == 'admin';
    } catch (e) {
      debugPrint('Ошибка проверки прав администратора: $e');
      return false;
    }
  }

  /// Аутентификация администратора
  Future<bool> loginAdmin({
    required String email,
    required String password,
    required String authCode,
  }) async {
    try {
      // Проверка кода аутентификации (в реальном приложении должно быть более надежное решение)
      if (authCode != 'MAMA2023') {
        return false;
      }

      // Авторизация через Supabase
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return false;
      }

      // Проверка роли администратора
      return await isAdmin();
    } catch (e) {
      debugPrint('Ошибка входа администратора: $e');
      return false;
    }
  }

  /// Получение списка водителей, ожидающих верификации
  Future<List<Map<String, dynamic>>> getPendingDrivers() async {
    try {
      if (!await isAdmin()) {
        throw Exception('Недостаточно прав для выполнения операции');
      }

      final response = await _client
          .from('profiles')
          .select('*')
          .eq('role', 'driver')
          .eq('verification_status', 'pending');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Ошибка получения списка водителей: $e');
      return [];
    }
  }

  /// Получение документов водителя
  Future<List<Map<String, dynamic>>> getDriverDocuments(String driverId) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Недостаточно прав для выполнения операции');
      }

      final response = await _client
          .from('driver_documents')
          .select('*')
          .eq('driver_id', driverId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Ошибка получения документов водителя: $e');
      return [];
    }
  }

  /// Подтверждение документов водителя
  Future<bool> approveDriver(String driverId, String comment) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Недостаточно прав для выполнения операции');
      }

      // Обновление статуса верификации водителя
      await _client
          .from('profiles')
          .update({
            'verification_status': 'approved',
            'verification_comment': comment,
            'verified_at': DateTime.now().toIso8601String(),
            'verified_by': SupabaseService().currentUserId,
          })
          .eq('id', driverId)
          .eq('role', 'driver');

      // Запись действия в журнал
      await _client.from('admin_actions').insert({
        'admin_id': SupabaseService().currentUserId,
        'action_type': 'driver_verification_approved',
        'target_id': driverId,
        'details': {'comment': comment},
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Ошибка подтверждения документов водителя: $e');
      return false;
    }
  }

  /// Отклонение документов водителя
  Future<bool> rejectDriver(String driverId, String comment) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Недостаточно прав для выполнения операции');
      }

      if (comment.isEmpty) {
        throw Exception('Необходимо указать причину отклонения');
      }

      // Обновление статуса верификации водителя
      await _client
          .from('profiles')
          .update({
            'verification_status': 'rejected',
            'verification_comment': comment,
            'verified_at': DateTime.now().toIso8601String(),
            'verified_by': SupabaseService().currentUserId,
          })
          .eq('id', driverId)
          .eq('role', 'driver');

      // Запись действия в журнал
      await _client.from('admin_actions').insert({
        'admin_id': SupabaseService().currentUserId,
        'action_type': 'driver_verification_rejected',
        'target_id': driverId,
        'details': {'comment': comment},
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Ошибка отклонения документов водителя: $e');
      return false;
    }
  }

  /// Получение статистики для дашборда
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      if (!await isAdmin()) {
        throw Exception('Недостаточно прав для выполнения операции');
      }

      // Получение активных поездок
      final activeRidesResponse =
          await _client.from('rides').select('id').eq('status', 'active');

      final activeRidesCount = activeRidesResponse.length;

      // Получение водителей, ожидающих верификации
      final pendingDriversResponse = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'driver')
          .eq('verification_status', 'pending');

      final pendingDriversCount = pendingDriversResponse.length;

      // Получение завершенных поездок за сегодня
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final completedTodayResponse = await _client
          .from('rides')
          .select('id')
          .eq('status', 'completed')
          .gte('completed_at', startOfDay.toIso8601String());

      final completedTodayCount = completedTodayResponse.length;

      // Получение общей выручки за сегодня
      final revenueTodayResponse = await _client
          .from('rides')
          .select('amount')
          .eq('status', 'completed')
          .gte('completed_at', startOfDay.toIso8601String());

      double revenueTodaySum = 0;
      for (final ride in revenueTodayResponse) {
        revenueTodaySum += (ride['amount'] as num).toDouble();
      }

      return {
        'activeRides': activeRidesCount,
        'pendingDrivers': pendingDriversCount,
        'completedToday': completedTodayCount,
        'revenueToday': revenueTodaySum,
      };
    } catch (e) {
      debugPrint('Ошибка получения статистики: $e');
      return {
        'activeRides': 0,
        'pendingDrivers': 0,
        'completedToday': 0,
        'revenueToday': 0,
      };
    }
  }

  /// Получение списка активных поездок
  Future<List<Map<String, dynamic>>> getActiveRides() async {
    try {
      if (!await isAdmin()) {
        throw Exception('Недостаточно прав для выполнения операции');
      }

      final response = await _client
          .from('rides')
          .select('*, driver:driver_id(*), client:client_id(*)')
          .eq('status', 'active');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Ошибка получения активных поездок: $e');
      return [];
    }
  }

  /// Получение последних действий
  Future<List<Map<String, dynamic>>> getRecentActions(int limit) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Недостаточно прав для выполнения операции');
      }

      final response = await _client
          .from('admin_actions')
          .select('*, admin:admin_id(*)')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Ошибка получения последних действий: $e');
      return [];
    }
  }
}

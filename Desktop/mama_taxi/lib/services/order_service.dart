import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import 'supabase_service.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseService _supabaseService;

  // Стрим контроллер для активных заказов
  final StreamController<List<OrderModel>> _activeOrdersController =
      StreamController<List<OrderModel>>.broadcast();

  // Стрим для подписки на изменения активных заказов
  Stream<List<OrderModel>> get activeOrdersStream =>
      _activeOrdersController.stream;

  // Кэш активных заказов
  List<OrderModel> _activeOrders = [];
  List<OrderModel> get activeOrders => _activeOrders;

  OrderService({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  // Получить активные заказы водителя
  Future<List<OrderModel>> getActiveOrders() async {
    if (!_supabaseService.isAuthenticated) {
      return [];
    }

    try {
      final driverId = _supabaseService.currentUserId;
      if (driverId == null) {
        return [];
      }

      final response = await _client
          .from('orders_with_details')
          .select()
          .eq('driver_id', driverId)
          .or('status.eq.accepted,status.eq.inProgress')
          .order('created_at', ascending: false);

      final orders =
          (response as List).map((data) => OrderModel.fromJson(data)).toList();

      // Обновляем кэш и уведомляем подписчиков
      _activeOrders = orders;
      _activeOrdersController.add(_activeOrders);

      return orders;
    } catch (e) {
      debugPrint('Ошибка получения активных заказов: $e');
      return [];
    }
  }

  // Получить историю заказов водителя
  Future<List<OrderModel>> getOrderHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    if (!_supabaseService.isAuthenticated) {
      return [];
    }

    try {
      final driverId = _supabaseService.currentUserId;
      if (driverId == null) {
        return [];
      }

      // Создаем базовый запрос с использованием представления
      var query = _client
          .from('orders_with_details')
          .select()
          .eq('driver_id', driverId)
          .or('status.eq.completed,status.eq.cancelled')
          .order('created_at', ascending: false);

      // Добавляем фильтр по дате, если указаны даты
      String filterQuery = '';
      if (startDate != null) {
        filterQuery += ' and created_at.gte.${startDate.toIso8601String()}';
      }
      if (endDate != null) {
        // Устанавливаем конец дня для endDate
        final endOfDay =
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        filterQuery += ' and created_at.lte.${endOfDay.toIso8601String()}';
      }

      // Применяем дополнительные фильтры и диапазон
      final response = await query.range(offset, offset + limit - 1);

      return (response as List)
          .map((data) => OrderModel.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения истории заказов: $e');
      return [];
    }
  }

  // Принять заказ
  Future<bool> acceptOrder(String orderId) async {
    if (!_supabaseService.isAuthenticated) {
      return false;
    }

    try {
      final driverId = _supabaseService.currentUserId;
      if (driverId == null) {
        return false;
      }

      final now = DateTime.now();

      await _client.from('orders').update({
        'driver_id': driverId,
        'status': 'accepted',
        'accepted_at': now.toIso8601String(),
      }).eq('id', orderId);

      // Обновляем активные заказы
      await getActiveOrders();

      return true;
    } catch (e) {
      debugPrint('Ошибка принятия заказа: $e');
      return false;
    }
  }

  // Начать поездку
  Future<bool> startRide(String orderId) async {
    if (!_supabaseService.isAuthenticated) {
      return false;
    }

    try {
      await _client.from('orders').update({
        'status': 'inProgress',
      }).eq('id', orderId);

      // Обновляем активные заказы
      await getActiveOrders();

      return true;
    } catch (e) {
      debugPrint('Ошибка начала поездки: $e');
      return false;
    }
  }

  // Завершить заказ
  Future<bool> completeOrder(String orderId) async {
    if (!_supabaseService.isAuthenticated) {
      return false;
    }

    try {
      final now = DateTime.now();

      await _client.from('orders').update({
        'status': 'completed',
        'completed_at': now.toIso8601String(),
        'is_paid': true,
      }).eq('id', orderId);

      // Обновляем активные заказы
      await getActiveOrders();

      return true;
    } catch (e) {
      debugPrint('Ошибка завершения заказа: $e');
      return false;
    }
  }

  // Отменить заказ
  Future<bool> cancelOrder(String orderId, String reason) async {
    if (!_supabaseService.isAuthenticated) {
      return false;
    }

    try {
      await _client.from('orders').update({
        'status': 'cancelled',
        'cancel_reason': reason,
      }).eq('id', orderId);

      // Обновляем активные заказы
      await getActiveOrders();

      return true;
    } catch (e) {
      debugPrint('Ошибка отмены заказа: $e');
      return false;
    }
  }

  // Получить детали заказа
  Future<OrderModel?> getOrderDetails(String orderId) async {
    if (!_supabaseService.isAuthenticated) {
      return null;
    }

    try {
      final response = await _client
          .from('orders_with_details')
          .select()
          .eq('id', orderId)
          .single();

      if (response == null) {
        return null;
      }

      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('Ошибка получения деталей заказа: $e');
      return null;
    }
  }

  // Метод для подписки на изменения активных заказов
  Future<void> subscribeToActiveOrders() async {
    try {
      final driverId = _supabaseService.currentUserId;
      if (driverId == null) return;

      // Получаем начальные данные
      await getActiveOrders();

      // Подписываемся на изменения в таблице заказов через канал Supabase
      _client
          .channel('public:orders')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            callback: (payload) async {
              // Проверяем, что изменение касается наших заказов
              final newRecord = payload.newRecord;
              if (newRecord != null && newRecord['driver_id'] == driverId) {
                // Обновляем список активных заказов
                await getActiveOrders();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Ошибка подписки на активные заказы: $e');
    }
  }

  // Метод для получения демо-данных (для отладки)
  List<OrderModel> getDemoActiveOrders() {
    return [
      OrderModel(
        id: '1',
        clientId: 'client-1',
        driverId: _supabaseService.currentUserId,
        startAddress: 'ул. Ленина, 10',
        endAddress: 'ул. Пушкина, 15',
        startLat: 55.751244,
        startLng: 37.618423,
        endLat: 55.755814,
        endLng: 37.617635,
        price: 350.0,
        status: OrderStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        acceptedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        clientName: 'Анна',
        clientPhone: '+7 (999) 123-45-67',
        childCount: 1,
      ),
      OrderModel(
        id: '2',
        clientId: 'client-2',
        driverId: _supabaseService.currentUserId,
        startAddress: 'пр. Мира, 22',
        endAddress: 'ул. Гагарина, 8',
        startLat: 55.761244,
        startLng: 37.628423,
        endLat: 55.765814,
        endLng: 37.627635,
        price: 450.0,
        status: OrderStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        acceptedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        clientName: 'Иван',
        clientPhone: '+7 (999) 987-65-43',
        childCount: 0,
      ),
    ];
  }

  List<OrderModel> getDemoOrderHistory() {
    return [
      OrderModel(
        id: '3',
        clientId: 'client-3',
        driverId: _supabaseService.currentUserId,
        startAddress: 'ул. Тверская, 5',
        endAddress: 'ул. Новый Арбат, 10',
        startLat: 55.751244,
        startLng: 37.618423,
        endLat: 55.755814,
        endLng: 37.617635,
        price: 550.0,
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        acceptedAt: DateTime.now()
            .subtract(const Duration(days: 1, hours: 1, minutes: 55)),
        completedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        clientName: 'Мария',
        clientPhone: '+7 (999) 111-22-33',
        isPaid: true,
        paymentMethod: 'Наличные',
        childCount: 0,
      ),
      OrderModel(
        id: '4',
        clientId: 'client-4',
        driverId: _supabaseService.currentUserId,
        startAddress: 'Кутузовский пр., 12',
        endAddress: 'Ленинградское ш., 30',
        startLat: 55.741244,
        startLng: 37.608423,
        endLat: 55.745814,
        endLng: 37.607635,
        price: 750.0,
        status: OrderStatus.cancelled,
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
        acceptedAt: DateTime.now()
            .subtract(const Duration(days: 2, hours: 4, minutes: 55)),
        clientName: 'Петр',
        clientPhone: '+7 (999) 444-55-66',
        isPaid: false,
        childCount: 2,
      ),
      OrderModel(
        id: '5',
        clientId: 'client-5',
        driverId: _supabaseService.currentUserId,
        startAddress: 'Садовое кольцо, 2',
        endAddress: 'МКАД, 12 км',
        startLat: 55.731244,
        startLng: 37.628423,
        endLat: 55.735814,
        endLng: 37.627635,
        price: 950.0,
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
        acceptedAt: DateTime.now()
            .subtract(const Duration(days: 3, hours: 0, minutes: 55)),
        completedAt: DateTime.now().subtract(const Duration(days: 3)),
        clientName: 'Ольга',
        clientPhone: '+7 (999) 777-88-99',
        isPaid: true,
        paymentMethod: 'Карта',
        childCount: 1,
      ),
    ];
  }

  // Освобождаем ресурсы при завершении работы
  void dispose() {
    _activeOrdersController.close();
  }
}

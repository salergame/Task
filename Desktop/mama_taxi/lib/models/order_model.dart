import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum OrderStatus { created, accepted, inProgress, completed, cancelled }

class OrderModel {
  final String id;
  final String clientId;
  final String? driverId;
  final String startAddress;
  final String endAddress;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double price;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? clientName;
  final String? clientPhone;
  final String? clientRating;
  final String? clientAvatarUrl;
  final bool isPaid;
  final String? paymentMethod;
  final String? comment;
  final int? childCount;

  const OrderModel({
    required this.id,
    required this.clientId,
    this.driverId,
    required this.startAddress,
    required this.endAddress,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.price,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.clientName,
    this.clientPhone,
    this.clientRating,
    this.clientAvatarUrl,
    this.isPaid = false,
    this.paymentMethod,
    this.comment,
    this.childCount,
  });

  // Проверяет, активен ли заказ
  bool get isActive =>
      status == OrderStatus.accepted || status == OrderStatus.inProgress;

  // Проверяет, завершен ли заказ
  bool get isCompleted => status == OrderStatus.completed;

  // Проверяет, отменен ли заказ
  bool get isCancelled => status == OrderStatus.cancelled;

  // Возвращает форматированную дату создания
  String get formattedCreatedAt =>
      DateFormat('dd.MM.yyyy HH:mm').format(createdAt);

  // Возвращает форматированную дату завершения
  String? get formattedCompletedAt => completedAt != null
      ? DateFormat('dd.MM.yyyy HH:mm').format(completedAt!)
      : null;

  // Возвращает иконку статуса заказа
  IconData get statusIcon {
    switch (status) {
      case OrderStatus.created:
        return Icons.access_time;
      case OrderStatus.accepted:
        return Icons.directions_car;
      case OrderStatus.inProgress:
        return Icons.local_taxi;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  // Возвращает цвет статуса заказа
  Color get statusColor {
    switch (status) {
      case OrderStatus.created:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.deepPurple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // Возвращает текст статуса заказа
  String get statusText {
    switch (status) {
      case OrderStatus.created:
        return 'Создан';
      case OrderStatus.accepted:
        return 'Принят';
      case OrderStatus.inProgress:
        return 'В пути';
      case OrderStatus.completed:
        return 'Завершён';
      case OrderStatus.cancelled:
        return 'Отменён';
    }
  }

  // Создает экземпляр из JSON
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      clientId: json['client_id'],
      driverId: json['driver_id'],
      startAddress: json['start_address'],
      endAddress: json['end_address'],
      startLat: json['start_lat']?.toDouble() ?? 0.0,
      startLng: json['start_lng']?.toDouble() ?? 0.0,
      endLat: json['end_lat']?.toDouble() ?? 0.0,
      endLng: json['end_lng']?.toDouble() ?? 0.0,
      price: json['price']?.toDouble() ?? 0.0,
      status: _parseOrderStatus(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      clientRating: json['client_rating']?.toString() ?? json['client_rating'],
      clientAvatarUrl: json['client_avatar_url'],
      isPaid: json['is_paid'] ?? false,
      paymentMethod: json['payment_method'],
      comment: json['comment'],
      childCount: json['child_count'],
    );
  }

  // Преобразует в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'driver_id': driverId,
      'start_address': startAddress,
      'end_address': endAddress,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'price': price,
      'status': _orderStatusToString(status),
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'client_name': clientName,
      'client_phone': clientPhone,
      'client_rating': clientRating,
      'client_avatar_url': clientAvatarUrl,
      'is_paid': isPaid,
      'payment_method': paymentMethod,
      'comment': comment,
      'child_count': childCount,
    };
  }

  // Создает демо-заказ
  factory OrderModel.demo() {
    return OrderModel(
      id: 'demo-id',
      clientId: 'demo-client-id',
      startAddress: 'ул. Пушкина, 10',
      endAddress: 'ул. Ленина, 15',
      startLat: 55.751244,
      startLng: 37.618423,
      endLat: 55.755814,
      endLng: 37.617635,
      price: 350.0,
      status: OrderStatus.created,
      createdAt: DateTime.now(),
      clientName: 'Анна',
      clientPhone: '+7 (999) 123-45-67',
      childCount: 0,
    );
  }

  // Создает копию с изменениями
  OrderModel copyWith({
    String? id,
    String? clientId,
    String? driverId,
    String? startAddress,
    String? endAddress,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    double? price,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    String? clientName,
    String? clientPhone,
    String? clientRating,
    String? clientAvatarUrl,
    bool? isPaid,
    String? paymentMethod,
    String? comment,
    int? childCount,
  }) {
    return OrderModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      driverId: driverId ?? this.driverId,
      startAddress: startAddress ?? this.startAddress,
      endAddress: endAddress ?? this.endAddress,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientRating: clientRating ?? this.clientRating,
      clientAvatarUrl: clientAvatarUrl ?? this.clientAvatarUrl,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      comment: comment ?? this.comment,
      childCount: childCount ?? this.childCount,
    );
  }
}

// Преобразует строку статуса в enum
OrderStatus _parseOrderStatus(String? status) {
  if (status == null) return OrderStatus.created;

  switch (status) {
    case 'accepted':
      return OrderStatus.accepted;
    case 'inProgress':
      return OrderStatus.inProgress;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.created;
  }
}

// Преобразует enum статуса в строку
String _orderStatusToString(OrderStatus status) {
  switch (status) {
    case OrderStatus.created:
      return 'created';
    case OrderStatus.accepted:
      return 'accepted';
    case OrderStatus.inProgress:
      return 'inProgress';
    case OrderStatus.completed:
      return 'completed';
    case OrderStatus.cancelled:
      return 'cancelled';
  }
}

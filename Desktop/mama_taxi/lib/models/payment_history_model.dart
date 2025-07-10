import 'package:flutter/material.dart';

enum PaymentType {
  ride,
  specialRide,
  bonus,
  emergency,
  childCare,
  premium,
  other,
}

class PaymentHistoryItem {
  final String id;
  final String title;
  final DateTime date;
  final double amount;
  final PaymentType type;
  final String? details;

  const PaymentHistoryItem({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
    this.details,
  });

  // Получить иконку для типа платежа
  IconData getIcon() {
    switch (type) {
      case PaymentType.ride:
        return Icons.directions_car_outlined;
      case PaymentType.bonus:
        return Icons.card_giftcard;
      case PaymentType.emergency:
        return Icons.emergency;
      case PaymentType.childCare:
        return Icons.child_care;
      case PaymentType.premium:
        return Icons.star_outline;
      case PaymentType.specialRide:
        return Icons.local_taxi;
      case PaymentType.other:
        return Icons.attach_money;
    }
  }

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      amount: (json['amount'] as num).toDouble(),
      type: _parsePaymentType(json['type']),
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'amount': amount,
      'type': type.toString().split('.').last,
      'details': details,
    };
  }

  static PaymentType _parsePaymentType(String? type) {
    if (type == null) return PaymentType.other;

    switch (type) {
      case 'ride':
        return PaymentType.ride;
      case 'specialRide':
        return PaymentType.specialRide;
      case 'bonus':
        return PaymentType.bonus;
      case 'emergency':
        return PaymentType.emergency;
      case 'childCare':
        return PaymentType.childCare;
      case 'premium':
        return PaymentType.premium;
      default:
        return PaymentType.other;
    }
  }
}

class DriverEarnings {
  final double totalAmount;
  final DateTime month;
  final double rideEarnings;
  final double bonusEarnings;
  final List<PaymentHistoryItem> history;

  const DriverEarnings({
    required this.totalAmount,
    required this.month,
    required this.rideEarnings,
    required this.bonusEarnings,
    required this.history,
  });

  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    final history = (json['history'] as List)
        .map((item) => PaymentHistoryItem.fromJson(item))
        .toList();

    return DriverEarnings(
      totalAmount: (json['total_amount'] as num).toDouble(),
      month: DateTime.parse(json['month']),
      rideEarnings: (json['ride_earnings'] as num).toDouble(),
      bonusEarnings: (json['bonus_earnings'] as num).toDouble(),
      history: history,
    );
  }

  // Создать демо-данные для тестирования
  factory DriverEarnings.demo() {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month, 1);

    return DriverEarnings(
      totalAmount: 34500,
      month: month,
      rideEarnings: 30000,
      bonusEarnings: 2500,
      history: [
        PaymentHistoryItem(
          id: '1',
          title: 'Срочный вызов',
          date: DateTime(now.year, now.month, 14, 18, 30),
          amount: 1800,
          type: PaymentType.emergency,
        ),
        PaymentHistoryItem(
          id: '2',
          title: 'Поездка (Автоняня)',
          date: DateTime(now.year, now.month, 12, 10, 15),
          amount: 1200,
          type: PaymentType.childCare,
        ),
        PaymentHistoryItem(
          id: '3',
          title: 'Бонус за 50 поездок',
          date: DateTime(now.year, now.month, 10, 20, 45),
          amount: 500,
          type: PaymentType.bonus,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class PaymentMethod {
  final String id;
  final String type; // 'card', 'bank', etc.
  final String title;
  final String lastFourDigits;
  final bool isDefault;
  final String? cardType; // 'visa', 'mastercard', etc.
  final String? expiryDate;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.title,
    required this.lastFourDigits,
    this.isDefault = false,
    this.cardType,
    this.expiryDate,
  });
}

class Transaction {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionStatus status;
  final TransactionType type;
  final String? paymentMethodId;

  Transaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
    this.paymentMethodId,
  });
}

enum TransactionStatus { completed, pending, failed, refunded }

enum TransactionType { ride, subscription, loyaltyPurchase, refund }

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.completed:
        return 'Выполнено';
      case TransactionStatus.pending:
        return 'В обработке';
      case TransactionStatus.failed:
        return 'Ошибка';
      case TransactionStatus.refunded:
        return 'Возврат';
    }
  }

  Color get color {
    switch (this) {
      case TransactionStatus.completed:
        return const Color(0xFF10B981);
      case TransactionStatus.pending:
        return const Color(0xFFF59E0B);
      case TransactionStatus.failed:
        return const Color(0xFFEF4444);
      case TransactionStatus.refunded:
        return const Color(0xFF3B82F6);
    }
  }
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.ride:
        return 'Поездка';
      case TransactionType.subscription:
        return 'Подписка';
      case TransactionType.loyaltyPurchase:
        return 'Покупка за баллы';
      case TransactionType.refund:
        return 'Возврат';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.ride:
        return Icons.directions_car_outlined;
      case TransactionType.subscription:
        return Icons.repeat;
      case TransactionType.loyaltyPurchase:
        return Icons.card_giftcard;
      case TransactionType.refund:
        return Icons.replay;
    }
  }
}

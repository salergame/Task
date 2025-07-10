import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum TicketStatus {
  pending, // Ожидает рассмотрения
  inProgress, // В обработке
  resolved, // Решено
  closed // Закрыто
}

class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final DateTime createdAt;
  final TicketStatus status;
  final String? operatorResponse;
  final DateTime? respondedAt;
  final int estimatedResponseTime; // в минутах

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.createdAt,
    required this.status,
    this.operatorResponse,
    this.respondedAt,
    this.estimatedResponseTime = 30,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      subject: map['subject'] ?? '',
      description: map['description'] ?? '',
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      status: _parseStatus(map['status']),
      operatorResponse: map['operator_response'],
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'])
          : null,
      estimatedResponseTime: map['estimated_response_time'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'status': _statusToString(status),
      'operator_response': operatorResponse,
      'responded_at': respondedAt?.toIso8601String(),
      'estimated_response_time': estimatedResponseTime,
    };
  }

  static TicketStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return TicketStatus.pending;
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.pending;
    }
  }

  static String _statusToString(TicketStatus status) {
    switch (status) {
      case TicketStatus.pending:
        return 'pending';
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.closed:
        return 'closed';
    }
  }

  String getStatusText() {
    switch (status) {
      case TicketStatus.pending:
        return 'Ожидает рассмотрения';
      case TicketStatus.inProgress:
        return 'В обработке';
      case TicketStatus.resolved:
        return 'Решено';
      case TicketStatus.closed:
        return 'Закрыто';
    }
  }

  Color getStatusColor() {
    switch (status) {
      case TicketStatus.pending:
        return const Color(0xFFFEF3C7); // Желтый
      case TicketStatus.inProgress:
        return const Color(0xFFDBEAFE); // Синий
      case TicketStatus.resolved:
        return const Color(0xFFD1FAE5); // Зеленый
      case TicketStatus.closed:
        return const Color(0xFFE5E7EB); // Серый
    }
  }

  Color getStatusTextColor() {
    switch (status) {
      case TicketStatus.pending:
        return const Color(0xFFD97706); // Темно-желтый
      case TicketStatus.inProgress:
        return const Color(0xFF1D4ED8); // Темно-синий
      case TicketStatus.resolved:
        return const Color(0xFF047857); // Темно-зеленый
      case TicketStatus.closed:
        return const Color(0xFF6B7280); // Темно-серый
    }
  }
}

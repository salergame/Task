import 'package:flutter/material.dart';

enum VerificationStatus { notVerified, inProgress, verified, rejected }

enum DocumentStatus { notUploaded, uploaded, verified, rejected }

class VerificationDocument {
  final String id;
  final String title;
  final DocumentStatus status;
  final String? filePath;
  final String? comment;
  final DateTime? uploadDate;

  const VerificationDocument({
    required this.id,
    required this.title,
    required this.status,
    this.filePath,
    this.comment,
    this.uploadDate,
  });

  // Проверяет, загружен ли документ
  bool get isUploaded => status != DocumentStatus.notUploaded;

  // Проверяет, требуется ли загрузка документа
  bool get isRequired => true;

  // Возвращает значок, соответствующий типу документа
  IconData getIcon() {
    if (title.toLowerCase().contains('паспорт')) {
      return Icons.credit_card_outlined;
    } else if (title.toLowerCase().contains('удостоверение')) {
      return Icons.drive_eta_outlined;
    } else if (title.toLowerCase().contains('страхов')) {
      return Icons.health_and_safety_outlined;
    } else if (title.toLowerCase().contains('мед')) {
      return Icons.medical_services_outlined;
    } else {
      return Icons.description_outlined;
    }
  }
}

class DriverVerification {
  final String driverId;
  final VerificationStatus status;
  final List<VerificationDocument> documents;
  final int currentStep;
  final DateTime lastUpdate;

  const DriverVerification({
    required this.driverId,
    required this.status,
    required this.documents,
    required this.currentStep,
    required this.lastUpdate,
  });

  // Получить статус верификации в виде строки
  String getStatusText() {
    switch (status) {
      case VerificationStatus.notVerified:
        return 'Не верифицирован';
      case VerificationStatus.inProgress:
        return 'В процессе';
      case VerificationStatus.verified:
        return 'Верифицирован';
      case VerificationStatus.rejected:
        return 'Отклонено';
    }
  }

  // Получить цвет статуса верификации
  Color getStatusColor() {
    switch (status) {
      case VerificationStatus.notVerified:
        return const Color(0xFFB91C1C);
      case VerificationStatus.inProgress:
        return const Color(0xFF3B82F6);
      case VerificationStatus.verified:
        return const Color(0xFF10B981);
      case VerificationStatus.rejected:
        return const Color(0xFFB91C1C);
    }
  }

  // Создать демо-объект верификации
  factory DriverVerification.demo() {
    return DriverVerification(
      driverId: 'demo-driver-id',
      status: VerificationStatus.inProgress,
      currentStep: 1,
      lastUpdate: DateTime.now(),
      documents: [
        VerificationDocument(
          id: '1',
          title: 'Паспорт',
          status: DocumentStatus.notUploaded,
        ),
        VerificationDocument(
          id: '2',
          title: 'Водительское удостоверение',
          status: DocumentStatus.notUploaded,
        ),
        VerificationDocument(
          id: '3',
          title: 'Страховой полис',
          status: DocumentStatus.notUploaded,
        ),
        VerificationDocument(
          id: '4',
          title: 'Медицинская справка',
          status: DocumentStatus.notUploaded,
        ),
      ],
    );
  }
}

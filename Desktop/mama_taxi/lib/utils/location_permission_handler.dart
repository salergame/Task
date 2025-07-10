import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionHandler {
  static Future<bool> requestLocationPermission(BuildContext context) async {
    // Проверяем текущий статус разрешений
    PermissionStatus status = await Permission.location.status;

    // Если разрешение уже предоставлено, возвращаем true
    if (status.isGranted) {
      return true;
    }

    // Если разрешение еще не запрашивалось, запрашиваем его
    if (status.isDenied) {
      status = await Permission.location.request();
      return status.isGranted;
    }

    // Если разрешение было отклонено навсегда, предлагаем пользователю перейти в настройки
    if (status.isPermanentlyDenied) {
      // Показываем диалог только если есть действительный контекст
      if (context.mounted) {
        await showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('Требуется разрешение на местоположение'),
                content: const Text(
                  'Для работы карты необходим доступ к местоположению. Пожалуйста, предоставьте разрешение в настройках приложения.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      openAppSettings();
                    },
                    child: const Text('Открыть настройки'),
                  ),
                ],
              ),
        );
      }
      return false;
    }

    return false;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeYandexMap extends StatefulWidget {
  const NativeYandexMap({Key? key}) : super(key: key);

  @override
  State<NativeYandexMap> createState() => _NativeYandexMapState();
}

class _NativeYandexMapState extends State<NativeYandexMap> {
  // Контроллер для связи с нативной платформой
  final MethodChannel _methodChannel =
      const MethodChannel('yandex_mapkit/map_controller');

  @override
  void initState() {
    super.initState();
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMapReady':
          debugPrint('Карта готова к использованию');
          break;
        case 'onMapError':
          debugPrint('Ошибка карты: ${call.arguments}');
          break;
        default:
          debugPrint('Неизвестный метод: ${call.method}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Используем AndroidView для Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const AndroidView(
        viewType: 'yandex_mapkit/yandex_map',
        creationParams: {},
        creationParamsCodec: StandardMessageCodec(),
      );
    }

    // Для других платформ показываем заглушку
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Text(
          'Яндекс карты доступны только на Android',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

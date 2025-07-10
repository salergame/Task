import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class CustomYandexMap extends StatefulWidget {
  const CustomYandexMap({Key? key}) : super(key: key);

  @override
  State<CustomYandexMap> createState() => _CustomYandexMapState();
}

class _CustomYandexMapState extends State<CustomYandexMap>
    with WidgetsBindingObserver {
  YandexMapController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YandexMap(
      onMapCreated: (controller) {
        setState(() {
          _controller = controller;
        });

        // Установка начальной позиции (центр Москвы)
        _controller?.moveCamera(
          CameraUpdate.newCameraPosition(
            const CameraPosition(
              target: Point(latitude: 55.751244, longitude: 37.618423),
              zoom: 14.0,
            ),
          ),
        );
      },
    );
  }
}

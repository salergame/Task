import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mama_taxi/utils/constants.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:mama_taxi/models/app_lat_long.dart';

class WaitingForTaxiDialog extends StatefulWidget {
  final int initialWaitingTime;
  final int price;
  final String formattedPrice;
  final String startAddress;
  final String endAddress;
  final Function onCancel;
  final String weatherCondition;
  final bool highDemand;
  final Point? startPoint;
  final Point? endPoint;

  const WaitingForTaxiDialog({
    required this.initialWaitingTime,
    required this.price,
    required this.formattedPrice,
    required this.startAddress,
    required this.endAddress,
    required this.onCancel,
    required this.weatherCondition,
    required this.highDemand,
    this.startPoint,
    this.endPoint,
    Key? key,
  }) : super(key: key);

  @override
  _WaitingForTaxiDialogState createState() => _WaitingForTaxiDialogState();
}

class _WaitingForTaxiDialogState extends State<WaitingForTaxiDialog> with SingleTickerProviderStateMixin {
  late int _waitingTime;
  late Timer _timer;
  int _driversNearby = 0;
  bool _isSearchingDrivers = true;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  // Переменные для карты
  YandexMapController? _mapController;
  final List<MapObject> _mapObjects = [];
  Point? _driverPoint;
  Timer? _driverMovementTimer;
  bool _isMapReady = false;
  bool _showMap = false;
  
  // Информация о движении водителя
  double _distanceToClient = 0;
  String _estimatedArrival = '';

  @override
  void initState() {
    super.initState();
    _waitingTime = widget.initialWaitingTime;
    _driversNearby = _generateRandomDriversCount();
    
    // Анимация пульсации для индикатора ожидания
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Запускаем таймер для обновления времени ожидания
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Имитируем поиск водителей в течение 3-5 секунд
        if (_isSearchingDrivers && timer.tick > 3 + Random().nextInt(3)) {
          _isSearchingDrivers = false;
          
          // Генерируем случайное количество водителей поблизости
          _driversNearby = _generateRandomDriversCount();
          
          // Корректируем время ожидания в зависимости от количества водителей
          _adjustWaitingTimeBasedOnDrivers();
          
          // Показываем карту после нахождения водителя
          _showMap = true;
          
          // Инициализируем местоположение водителя
          _initDriverLocation();
        }
      });
    });
  }
  
  // Инициализация начального местоположения водителя
  void _initDriverLocation() {
    if (widget.startPoint != null) {
      // Создаем случайную начальную точку для водителя в радиусе 2-3 км от точки отправления
      final double radius = 0.02 + (Random().nextDouble() * 0.01); // примерно 2-3 км в градусах
      final double angle = Random().nextDouble() * 2 * pi;
      
      final double driverLat = widget.startPoint!.latitude + (radius * cos(angle));
      final double driverLng = widget.startPoint!.longitude + (radius * sin(angle));
      
      _driverPoint = Point(latitude: driverLat, longitude: driverLng);
      
      // Добавляем маркер водителя на карту
      _addDriverMarker();
      
      // Вычисляем расстояние и время прибытия
      _calculateDistanceAndTime();
      
      // Запускаем таймер для движения водителя
      _startDriverMovement();
    }
  }
  
  // Добавление маркера водителя на карту
  void _addDriverMarker() {
    if (_driverPoint != null) {
      // Удаляем старый маркер водителя, если он есть
      _mapObjects.removeWhere((obj) => obj.mapId.value == 'driver');
      
      // Создаем новый маркер водителя
      final driverPlacemark = PlacemarkMapObject(
        mapId: const MapObjectId('driver'),
        point: _driverPoint!,
        opacity: 1.0,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromBytes(_generatePlaceholderIcon(Colors.amber)),
            scale: 1.5,
          ),
        ),
      );
      
      // Добавляем маркеры начальной и конечной точек маршрута
      if (widget.startPoint != null) {
        _mapObjects.add(
          PlacemarkMapObject(
            mapId: const MapObjectId('start'),
            point: widget.startPoint!,
            opacity: 1.0,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                image: BitmapDescriptor.fromBytes(_generatePlaceholderIcon(Colors.green)),
                scale: 1.5,
              ),
            ),
          ),
        );
      }
      
      if (widget.endPoint != null) {
        _mapObjects.add(
          PlacemarkMapObject(
            mapId: const MapObjectId('end'),
            point: widget.endPoint!,
            opacity: 1.0,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                image: BitmapDescriptor.fromBytes(_generatePlaceholderIcon(Colors.red)),
                scale: 1.5,
              ),
            ),
          ),
        );
      }
      
      // Добавляем маркер водителя
      _mapObjects.add(driverPlacemark);
      
      // Обновляем карту
      setState(() {});
      
      // Центрируем карту на водителе
      _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _driverPoint!,
            zoom: 14.0,
          ),
        ),
        animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1),
      );
    }
  }
  
  // Генерация заполнителя для иконки
  Uint8List _generatePlaceholderIcon(Color color) {
    // Это просто заглушка, так как у нас нет реальных изображений
    // В реальном приложении здесь должна быть логика создания иконки
    return Uint8List(0);
  }
  
  // Запуск движения водителя к клиенту
  void _startDriverMovement() {
    // Отменяем предыдущий таймер, если он существует
    _driverMovementTimer?.cancel();
    
    // Создаем новый таймер для обновления позиции водителя каждые 2 секунды
    _driverMovementTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_driverPoint != null && widget.startPoint != null) {
        // Вычисляем направление движения к клиенту
        final double targetLat = widget.startPoint!.latitude;
        final double targetLng = widget.startPoint!.longitude;
        
        // Текущее положение водителя
        final double currentLat = _driverPoint!.latitude;
        final double currentLng = _driverPoint!.longitude;
        
        // Вычисляем вектор направления
        final double latDiff = targetLat - currentLat;
        final double lngDiff = targetLng - currentLng;
        
        // Нормализуем вектор и умножаем на скорость движения
        final double distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);
        
        // Если водитель достаточно близко к клиенту, останавливаем движение
        if (distance < 0.0005) { // примерно 50 метров
          _driverMovementTimer?.cancel();
          return;
        }
        
        // Скорость движения (в градусах за обновление)
        final double speed = 0.0005 + (Random().nextDouble() * 0.0003); // случайная скорость
        
        // Новая позиция водителя
        final double newLat = currentLat + (latDiff / distance * speed);
        final double newLng = currentLng + (lngDiff / distance * speed);
        
        // Обновляем позицию водителя
        setState(() {
          _driverPoint = Point(latitude: newLat, longitude: newLng);
          
          // Обновляем маркер водителя
          _addDriverMarker();
          
          // Пересчитываем расстояние и время
          _calculateDistanceAndTime();
        });
      }
    });
  }
  
  // Вычисление расстояния и времени прибытия
  void _calculateDistanceAndTime() {
    if (_driverPoint != null && widget.startPoint != null) {
      // Вычисляем расстояние между водителем и клиентом (приблизительно)
      final double lat1 = _driverPoint!.latitude;
      final double lon1 = _driverPoint!.longitude;
      final double lat2 = widget.startPoint!.latitude;
      final double lon2 = widget.startPoint!.longitude;
      
      // Формула гаверсинусов для вычисления расстояния
      final double p = 0.017453292519943295; // Math.PI / 180
      final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
          cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
      
      // Радиус Земли в км
      final double earthRadius = 6371.0;
      _distanceToClient = 2 * earthRadius * asin(sqrt(a));
      
      // Вычисляем примерное время прибытия (средняя скорость 30 км/ч)
      final double timeInHours = _distanceToClient / 30.0;
      final int timeInMinutes = (timeInHours * 60).round();
      
      // Форматируем расстояние и время
      if (_distanceToClient < 1.0) {
        _distanceToClient = _distanceToClient * 1000; // конвертируем в метры
        _estimatedArrival = '$timeInMinutes мин';
      } else {
        _estimatedArrival = '$timeInMinutes мин';
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _driverMovementTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Генерация случайного количества водителей поблизости
  int _generateRandomDriversCount() {
    // Базовое количество водителей
    int baseCount = 3 + Random().nextInt(8); // от 3 до 10
    
    // Корректировка в зависимости от высокого спроса
    if (widget.highDemand) {
      baseCount = max(1, baseCount - 3); // Уменьшаем при высоком спросе
    }
    
    // Корректировка в зависимости от плохой погоды
    if (widget.weatherCondition == 'Плохая погода') {
      baseCount = max(1, baseCount - 2); // Уменьшаем при плохой погоде
    }
    
    return baseCount;
  }

  // Корректировка времени ожидания в зависимости от количества водителей
  void _adjustWaitingTimeBasedOnDrivers() {
    if (_driversNearby >= 8) {
      // Много водителей - уменьшаем время
      _waitingTime = max(3, _waitingTime - 3);
    } else if (_driversNearby <= 2) {
      // Мало водителей - увеличиваем время
      _waitingTime += 4;
    } else if (_driversNearby <= 4) {
      // Среднее количество водителей - немного увеличиваем время
      _waitingTime += 1;
    }
    
    // Дополнительная корректировка при высоком спросе
    if (widget.highDemand) {
      _waitingTime += 2;
    }
    
    // Дополнительная корректировка при плохой погоде
    if (widget.weatherCondition == 'Плохая погода') {
      _waitingTime += 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Text(
              _isSearchingDrivers ? 'Поиск водителей' : 'Ожидание водителя',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                fontFamily: 'Rubik',
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 24),
            
            // Карта с местоположением водителя (показывается после нахождения водителя)
            if (_showMap && !_isSearchingDrivers) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      YandexMap(
                        mapObjects: _mapObjects,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          setState(() {
                            _isMapReady = true;
                          });
                          
                          // Если водитель уже найден, центрируем карту на нем
                          if (_driverPoint != null) {
                            controller.moveCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: _driverPoint!,
                                  zoom: 14.0,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      // Индикатор загрузки карты
                      if (!_isMapReady)
                        Container(
                          color: Colors.white.withOpacity(0.7),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      // Информация о расстоянии и времени прибытия
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: AppColors.primary, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    _distanceToClient < 1.0
                                        ? '${_distanceToClient.toStringAsFixed(0)} м'
                                        : '${_distanceToClient.toStringAsFixed(1)} км',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Manrope',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.access_time, color: AppColors.success, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    _estimatedArrival,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Manrope',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ] else if (!_showMap) 
              // Анимация поиска или ожидания (показывается, когда карта не отображается)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isSearchingDrivers ? 1.0 : _pulseAnimation.value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: _isSearchingDrivers ? Colors.transparent : AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isSearchingDrivers ? AppColors.primary : AppColors.success,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: _isSearchingDrivers
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              strokeWidth: 4,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time, 
                                  size: 48, 
                                  color: AppColors.success
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$_waitingTime мин',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Rubik',
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
                  );
                }
              ),
            
            // Информация о поездке
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.location_on, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.startAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Manrope',
                            color: Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 19),
                    child: Container(
                      height: 24,
                      width: 1,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.flag, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.endAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Manrope',
                            color: Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Информация о факторах, влияющих на время
            if (!_isSearchingDrivers) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Информация',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Rubik',
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Водителей поблизости: $_driversNearby',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Manrope',
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.weatherCondition == 'Плохая погода'
                                ? Icons.cloudy_snowing
                                : Icons.wb_sunny,
                            size: 18,
                            color: widget.weatherCondition == 'Плохая погода'
                                ? Colors.blue[700]
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.weatherCondition,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Manrope',
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                    if (widget.highDemand) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.trending_up,
                              size: 18,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Высокий спрос',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Manrope',
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Цена поездки
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Стоимость поездки: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Rubik',
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    widget.formattedPrice,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Rubik',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Кнопка отмены
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => widget.onCancel(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
                child: const Text(
                  'Отменить заказ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
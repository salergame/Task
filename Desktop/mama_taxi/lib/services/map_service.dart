import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geocoding/geocoding.dart';

class MapService {
  static final MapService _instance = MapService._internal();

  factory MapService() {
    return _instance;
  }

  MapService._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // API ключ Yandex MapKit
  static const String apiKey = '18fb32f9-5ace-46c2-a283-8c60c38131a0';

  // Обновленные границы Москвы (более точные)
  static const double MOSCOW_NORTH_LAT = 56.009657;
  static const double MOSCOW_EAST_LON = 37.945661;
  static const double MOSCOW_SOUTH_LAT = 55.489926;
  static const double MOSCOW_WEST_LON = 37.319328;
  
  // Центр Москвы
  static const Point MOSCOW_CENTER = Point(latitude: 55.751244, longitude: 37.618423);
  
  // Получить ограничивающий прямоугольник для Москвы
  static BoundingBox getMoscowBoundingBox() {
    return BoundingBox(
      northEast: const Point(latitude: MOSCOW_NORTH_LAT, longitude: MOSCOW_EAST_LON),
      southWest: const Point(latitude: MOSCOW_SOUTH_LAT, longitude: MOSCOW_WEST_LON),
    );
  }
  
  // Проверка, находится ли точка в пределах Москвы
  static bool isPointInMoscow(Point point) {
    return point.latitude <= MOSCOW_NORTH_LAT && 
           point.latitude >= MOSCOW_SOUTH_LAT && 
           point.longitude <= MOSCOW_EAST_LON && 
           point.longitude >= MOSCOW_WEST_LON;
  }

  // Улучшенный метод для поиска адреса по координатам с использованием Yandex Search
  static Future<String?> getAddressByPoint(Point point) async {
    try {
      // Проверяем, находится ли точка в пределах Москвы
      if (!isPointInMoscow(point)) {
        return 'Адрес за пределами Москвы';
      }
      
      final searchResult = await YandexSearch.searchByPoint(
        point: point,
        searchOptions: const SearchOptions(
          searchType: SearchType.geo,
          resultPageSize: 1,
        ),
      );
      
      final sessionResult = await searchResult.result;
      final items = sessionResult.items;
      
              if (items != null && items.isNotEmpty) {
          // Формируем читаемый адрес из доступных данных
          final item = items.first;
          String address = item.name;
          
          // Добавляем "Москва", если город не указан в адресе
          if (!address.toLowerCase().contains('москва')) {
            address += ', Москва';
          }
          
          return address;
        }
      
      // Если Yandex Search не дал результатов, используем geocoding пакет
      return getAddressByCoordinates(point.latitude, point.longitude);
    } catch (e) {
      debugPrint('Ошибка при получении адреса: $e');
      return getAddressByCoordinates(point.latitude, point.longitude);
    }
  }
  
  // Улучшенный метод для получения адреса по координатам с использованием geocoding пакета
  static Future<String?> getAddressByCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude, longitude,
        localeIdentifier: 'ru',
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        
        // Формируем полный адрес из компонентов
        List<String> addressComponents = [];
        
        // Добавляем улицу и номер дома
        if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
          String streetAddress = placemark.thoroughfare!;
          
          if (placemark.subThoroughfare != null && placemark.subThoroughfare!.isNotEmpty) {
            streetAddress += ', ${placemark.subThoroughfare}';
          }
          
          addressComponents.add(streetAddress);
        } else if (placemark.street != null && placemark.street!.isNotEmpty) {
          String streetAddress = placemark.street!;
          
          if (placemark.name != null && placemark.name!.isNotEmpty && 
              placemark.name != placemark.street) {
            streetAddress += ', ${placemark.name}';
          }
          
          addressComponents.add(streetAddress);
        }
        
        // Добавляем район
        if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
          addressComponents.add(placemark.subLocality!);
        }
        
        // Добавляем город
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          addressComponents.add(placemark.locality!);
        } else {
          // Если город не указан, добавляем "Москва"
          addressComponents.add('Москва');
        }
        
        // Собираем адрес
        String address = addressComponents.join(', ');
        
        // Если адрес пустой, используем запасной вариант
        if (address.isEmpty) {
          List<String> fallbackComponents = [];
          
          if (placemark.name != null && placemark.name!.isNotEmpty) {
            fallbackComponents.add(placemark.name!);
          }
          
          if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
            fallbackComponents.add(placemark.administrativeArea!);
          }
          
          if (fallbackComponents.isEmpty) {
            return 'Москва, координаты: $latitude, $longitude';
          } else {
            return fallbackComponents.join(', ') + ', Москва';
          }
        }
        
        return address;
      }
      
      return 'Москва, координаты: $latitude, $longitude';
    } catch (e) {
      debugPrint('Ошибка при получении адреса через geocoding: $e');
      return 'Москва, координаты: $latitude, $longitude';
    }
  }

  // Поиск адресов по запросу с ограничением по Москве
  static Future<List<SearchItem>> searchAddressByText(String query) async {
    try {
      // Добавляем "Москва" к запросу, если не указан город
      String searchQuery = query;
      if (!searchQuery.toLowerCase().contains('москва')) {
        searchQuery = '$searchQuery, Москва';
      }
      
      final searchResult = await YandexSearch.searchByText(
        searchText: searchQuery,
        geometry: Geometry.fromBoundingBox(getMoscowBoundingBox()),
        searchOptions: const SearchOptions(
          searchType: SearchType.geo,
          resultPageSize: 10,
        ),
      );

      final sessionResult = await searchResult.result;
      final items = sessionResult.items;
      
      if (items != null && items.isNotEmpty) {
        return items;
      }
      
      return [];
    } catch (e) {
      debugPrint('Ошибка при поиске адреса: $e');
      return [];
    }
  }

  // Получение подсказок по адресам с ограничением по Москве
  static Future<List<SuggestItem>> getSuggestions(String query) async {
    try {
      // Добавляем "Москва" к запросу, если не указан город
      String searchQuery = query;
      if (!searchQuery.toLowerCase().contains('москва')) {
        searchQuery = '$searchQuery, Москва';
      }
      
      final session = YandexSuggest.getSuggestions(
        text: searchQuery,
        boundingBox: getMoscowBoundingBox(),
        suggestOptions: const SuggestOptions(
          suggestType: SuggestType.geo,
          suggestWords: true,
        ),
      );
      
      final result = await session.result;
      final items = result.items ?? [];
      
      return items;
    } catch (e) {
      debugPrint('Ошибка при получении подсказок: $e');
      return [];
    }
  }

  // Инициализация Yandex MapKit после запроса разрешений
  Future<bool> initializeMapKit(BuildContext context) async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Сначала запрашиваем разрешения на местоположение
      final status = await Permission.location.request();

      if (status.isGranted) {
        // Карта уже инициализирована в нативном коде, просто устанавливаем флаг
        debugPrint('Yandex MapKit готов к использованию');
        _isInitialized = true;
        return true;
      } else if (status.isPermanentlyDenied) {
        // Если разрешение отклонено навсегда, показываем диалог с предложением перейти в настройки
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
      } else {
        // Если разрешение не получено по другим причинам
        debugPrint('Разрешение на местоположение не получено: $status');
        return false;
      }
    } catch (e) {
      debugPrint('Ошибка инициализации Yandex MapKit: $e');
      return false;
    }
  }
}

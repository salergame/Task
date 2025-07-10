import 'dart:math';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class PriceCalculatorService {
  // Базовые тарифы (в рублях)
  static const double _baseFareMamaTaxi = 150.0;
  static const double _baseFarePersonalDriver = 250.0;
  static const double _baseFareUrgent = 350.0;
  static const double _baseFareWomenTaxi = 200.0;

  // Стоимость за километр (в рублях)
  static const double _pricePerKmMamaTaxi = 30.0;
  static const double _pricePerKmPersonalDriver = 40.0;
  static const double _pricePerKmUrgent = 50.0;
  static const double _pricePerKmWomenTaxi = 35.0;

  // Минимальная стоимость поездки
  static const double _minFareMamaTaxi = 450.0;
  static const double _minFarePersonalDriver = 650.0;
  static const double _minFareUrgent = 850.0;
  static const double _minFareWomenTaxi = 550.0;

  // Коэффициенты для дополнительных услуг
  static const double _escortChildCoefficient = 1.15; // +15%
  static const double _meetChildCoefficient = 1.1;   // +10%
  static const double _childSeatCoefficient = 1.05;  // +5%
  static const double _specificGenderCoefficient = 1.05; // +5%

  // Коэффициенты времени суток
  static const double _peakHourCoefficient = 1.2;    // +20% в час пик
  static const double _nightTimeCoefficient = 1.3;   // +30% ночью

  // Коэффициент спроса (динамическое ценообразование)
  static const double _highDemandCoefficient = 1.25; // +25% при высоком спросе

  // Коэффициент погодных условий
  static const double _badWeatherCoefficient = 1.15; // +15% в плохую погоду

  // Расчет стоимости поездки
  static Map<String, dynamic> calculatePrice({
    required String tariffType,
    required double distanceInMeters,
    required List<int> selectedServices,
    DateTime? rideTime,
    bool isHighDemand = false,
    bool isBadWeather = false,
    int numberOfPassengers = 1,
  }) {
    // Проверяем входные данные
    if (distanceInMeters <= 0) {
      debugPrint('Ошибка: неверное расстояние');
      return _getDefaultPrice(tariffType);
    }

    // Конвертируем метры в километры для расчетов
    final double distanceInKm = distanceInMeters / 1000;
    
    // Определяем базовую стоимость и стоимость за километр в зависимости от тарифа
    double baseFare;
    double pricePerKm;
    double minFare;
    
    switch (tariffType) {
      case 'Мама такси':
        baseFare = _baseFareMamaTaxi;
        pricePerKm = _pricePerKmMamaTaxi;
        minFare = _minFareMamaTaxi;
        break;
      case 'Личный водитель':
        baseFare = _baseFarePersonalDriver;
        pricePerKm = _pricePerKmPersonalDriver;
        minFare = _minFarePersonalDriver;
        break;
      case 'Срочная поездка':
        baseFare = _baseFareUrgent;
        pricePerKm = _pricePerKmUrgent;
        minFare = _minFareUrgent;
        break;
      case 'Женское такси':
        baseFare = _baseFareWomenTaxi;
        pricePerKm = _pricePerKmWomenTaxi;
        minFare = _minFareWomenTaxi;
        break;
      default:
        baseFare = _baseFareMamaTaxi;
        pricePerKm = _pricePerKmMamaTaxi;
        minFare = _minFareMamaTaxi;
    }

    // Базовый расчет стоимости: базовый тариф + стоимость за километр * расстояние
    double totalPrice = baseFare + (pricePerKm * distanceInKm);
    
    // Применяем коэффициенты для дополнительных услуг
    double serviceMultiplier = 1.0;
    
    for (int serviceId in selectedServices) {
      switch (serviceId) {
        case 1: // Проводить до входа в квартиру / школу
          serviceMultiplier *= _escortChildCoefficient;
          break;
        case 2: // Встретить ребенка у квартиры / подъезда
          serviceMultiplier *= _meetChildCoefficient;
          break;
        case 3: // Водитель — мужчина
        case 4: // Водитель — женщина
          serviceMultiplier *= _specificGenderCoefficient;
          break;
        case 5: // Детское автокресло
          serviceMultiplier *= _childSeatCoefficient;
          break;
      }
    }
    
    totalPrice *= serviceMultiplier;
    
    // Применяем коэффициент времени суток
    if (rideTime != null) {
      final hour = rideTime.hour;
      
      // Час пик: утром с 7 до 10, вечером с 17 до 20
      if ((hour >= 7 && hour < 10) || (hour >= 17 && hour < 20)) {
        totalPrice *= _peakHourCoefficient;
      }
      
      // Ночное время: с 23 до 6 утра
      if (hour >= 23 || hour < 6) {
        totalPrice *= _nightTimeCoefficient;
      }
    }
    
    // Применяем коэффициент спроса
    if (isHighDemand) {
      totalPrice *= _highDemandCoefficient;
    }
    
    // Применяем коэффициент погодных условий
    if (isBadWeather) {
      totalPrice *= _badWeatherCoefficient;
    }
    
    // Учитываем количество пассажиров (если больше 1, добавляем 5% за каждого дополнительного)
    if (numberOfPassengers > 1) {
      totalPrice *= (1 + 0.05 * (numberOfPassengers - 1));
    }
    
    // Проверяем, что итоговая стоимость не меньше минимальной
    totalPrice = max(totalPrice, minFare);
    
    // Округляем до целых рублей
    totalPrice = (totalPrice / 10).round() * 10;
    
    // Рассчитываем примерное время поездки (в минутах)
    // Средняя скорость в городе ~30 км/ч = 0.5 км/мин
    int estimatedTimeInMinutes = (distanceInKm / 0.5).round();
    
    // Добавляем случайное отклонение ±5 минут для реалистичности
    final random = Random();
    final timeVariation = random.nextInt(11) - 5; // от -5 до +5
    estimatedTimeInMinutes = max(1, estimatedTimeInMinutes + timeVariation);
    
    // Формируем диапазон времени (±3 минуты)
    final minTime = max(1, estimatedTimeInMinutes - 3);
    final maxTime = estimatedTimeInMinutes + 3;
    
    // Формируем строку с временем
    final timeRange = '$minTime-$maxTime мин';
    
    return {
      'price': totalPrice.round(),
      'formattedPrice': '${totalPrice.round()}₽',
      'distance': distanceInKm,
      'timeRange': timeRange,
      'basePrice': baseFare,
      'priceDetails': {
        'baseFare': baseFare,
        'distanceCost': pricePerKm * distanceInKm,
        'serviceMultiplier': serviceMultiplier,
        'timeMultiplier': rideTime != null ? _getTimeMultiplier(rideTime) : 1.0,
        'demandMultiplier': isHighDemand ? _highDemandCoefficient : 1.0,
        'weatherMultiplier': isBadWeather ? _badWeatherCoefficient : 1.0,
      }
    };
  }
  
  // Получение коэффициента времени
  static double _getTimeMultiplier(DateTime time) {
    final hour = time.hour;
    
    if (hour >= 23 || hour < 6) {
      return _nightTimeCoefficient;
    } else if ((hour >= 7 && hour < 10) || (hour >= 17 && hour < 20)) {
      return _peakHourCoefficient;
    }
    
    return 1.0;
  }
  
  // Получение цены по умолчанию (если расчет невозможен)
  static Map<String, dynamic> _getDefaultPrice(String tariffType) {
    switch (tariffType) {
      case 'Мама такси':
        return {
          'price': _minFareMamaTaxi.round(),
          'formattedPrice': '${_minFareMamaTaxi.round()}₽',
          'timeRange': '10-15 мин',
        };
      case 'Личный водитель':
        return {
          'price': _minFarePersonalDriver.round(),
          'formattedPrice': '${_minFarePersonalDriver.round()}₽',
          'timeRange': '15-20 мин',
        };
      case 'Срочная поездка':
        return {
          'price': _minFareUrgent.round(),
          'formattedPrice': '${_minFareUrgent.round()}₽',
          'timeRange': '5-8 мин',
        };
      case 'Женское такси':
        return {
          'price': _minFareWomenTaxi.round(),
          'formattedPrice': '${_minFareWomenTaxi.round()}₽',
          'timeRange': '15-20 мин',
        };
      default:
        return {
          'price': _minFareMamaTaxi.round(),
          'formattedPrice': '${_minFareMamaTaxi.round()}₽',
          'timeRange': '10-15 мин',
        };
    }
  }
  
  // Получение примерного расстояния между двумя точками (в метрах)
  static double calculateDistance(Point start, Point end) {
    // Используем формулу гаверсинусов для расчета расстояния между точками на сфере
    const double earthRadius = 6371000; // Радиус Земли в метрах
    
    // Конвертируем градусы в радианы
    final double lat1 = start.latitude * pi / 180;
    final double lon1 = start.longitude * pi / 180;
    final double lat2 = end.latitude * pi / 180;
    final double lon2 = end.longitude * pi / 180;
    
    // Разница координат
    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;
    
    // Формула гаверсинусов
    final double a = sin(dLat / 2) * sin(dLat / 2) +
                     cos(lat1) * cos(lat2) *
                     sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    // Расстояние в метрах
    final double distance = earthRadius * c;
    
    return distance;
  }
} 
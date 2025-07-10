import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ru', 'RU');

  Locale get locale => _locale;

  // Инициализация провайдера
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('languageCode');
    final String? countryCode = prefs.getString('countryCode');

    if (languageCode != null) {
      _locale = Locale(languageCode, countryCode);
    }
    notifyListeners();
  }

  // Установка локали
  void setLocale(Locale locale) async {
    if (_locale != locale) {
      _locale = locale;

      // Сохраняем значение в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', locale.languageCode);
      await prefs.setString('countryCode', locale.countryCode ?? '');

      notifyListeners();
    }
  }

  // Получение текущего языка
  String get currentLanguage {
    switch (_locale.languageCode) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      case 'kk':
        return 'Қазақша';
      default:
        return 'Русский';
    }
  }

  // Список поддерживаемых локалей
  static const List<Locale> supportedLocales = [
    Locale('ru', 'RU'),
    Locale('en', 'US'),
    Locale('kk', 'KZ'),
  ];

  // Установка языка по коду
  void setLanguageByCode(String code) {
    switch (code) {
      case 'ru':
        setLocale(const Locale('ru', 'RU'));
        break;
      case 'en':
        setLocale(const Locale('en', 'US'));
        break;
      case 'kk':
        setLocale(const Locale('kk', 'KZ'));
        break;
      default:
        setLocale(const Locale('ru', 'RU'));
    }
  }
}

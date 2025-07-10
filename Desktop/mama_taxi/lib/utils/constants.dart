import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF5EC7C3);
  static const secondary = Color(0xFF91D6D3);
  static const white = Colors.white;
  static const black = Colors.black;
  static const background = Color(0xFFF9FAFB);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const lightGrey = Color(0xFFE5E7EB);
  static const grey = Color(0xFF9CA3AF);
  static const darkGrey = Color(0xFF6B7280);
  static const lighterGrey = Color(0xFFF3F4F6);
  static const text = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF4B5563);
  static const textTertiary = Color(0xFF6B7280);
  static const placeholderText = Color(0xFFADAEBC);
  static const border = Color(0xFFE5E7EB);
  static const gradientStart = Color(0xFFEDE9FE);
  static const gradientEnd = Color(0xFFFFFFFF);
  static const link = Color(0xFF025FFE);
  static const infoBackground = Color(0xFFEFF6FF);
  static const infoText = Color(0xFF1D4ED8);
  static const warningBackground = Color(0xFFFFFBEB);
  static const warningText = Color(0xFFB45309);
  static const modalBackground = Color(0xFFF9FAFB);
  static const modalDivider = Color(0xFFF3F4F6);
  static const inputBackground = Color(0xFFF9FAFB);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  static const TextStyle modalTitle = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Color(0xFF111827),
  );

  static const TextStyle formLabel = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF6B7280),
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static const TextStyle link = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.link,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle error = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );
}

class AppSizes {
  static const double borderRadius = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusExtraLarge = 32.0;
  static const double modalBorderRadius = 24.0;
  static const double padding = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;
  static const double buttonHeight = 56.0;
  static const double inputHeight = 50.0;
  static const double modalHeaderHeight = 80.0;
  static const double avatarSize = 80.0;
  static const double avatarEditButtonSize = 28.0;
}

class AppStrings {
  static const String appName = 'Мама Такси';
  static const String appTagline = 'Безопасные поездки для ваших детей';
  static const String login = 'Вход в систему';
  static const String phoneNumber = 'Номер телефона';
  static const String getCode = 'Получить код';
  static const String orLoginWith = 'или войти через';
  static const String registerAsDriver = 'Зарегестрироваться как водитель';
  static const String registerAsUser = 'Зарегистрироваться как пользователь';
  static const String driverRegistration = 'Регистрация водителя';
  static const String userRegistration = 'Регистрация пользователя';
  static const String phoneLogin = 'Вход по номеру телефона';
  static const String socialLogin = 'Вход через социальные сети';
  static const String photoControl = 'Фотоконтроль';
  static const String takeSelfie = 'Сделайте селфи';
  static const String goodLighting = 'Фото должно быть при хорошем освещении';
  static const String pendingVerification = 'Ожидает проверки';
  static const String uploadDocuments = 'Загрузка документов';
  static const String passport = 'Паспорт';
  static const String driverLicense = 'Водительское удостоверение';
  static const String continue_ = 'Продолжить';
  static const String appInfo =
      'Наше приложение помогает родителям организовать безопасную перевозку детей в школу и обратно';
  static const String driverVerification =
      'Все водители проходят тщательную проверку документов и личности';
  static const String alreadyHaveAccount = 'Уже есть аккаунт? Войти';
  static const String register = 'Зарегистрироваться';
  static const String noAccount = 'Нет аккаунта?';
  static const String signUp = 'Зарегистрироваться';

  // Строки для модального окна добавления ребенка
  static const String addChild = 'Добавить ребенка';
  static const String childName = 'Имя ребенка';
  static const String enterName = 'Введите имя';
  static const String age = 'Возраст';
  static const String cancel = 'Отмена';
  static const String add = 'Добавить';
}

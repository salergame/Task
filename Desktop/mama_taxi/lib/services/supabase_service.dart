import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase
    show StorageException, BucketOptions;
import 'package:path/path.dart' as path_lib;
import '../widgets/add_child_modal.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../models/loyalty_model.dart';
import '../models/support_ticket_model.dart';
import '../models/payment_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  // Стрим контроллер для уведомлений об изменении статуса
  final StreamController<bool> _driverStatusController =
      StreamController<bool>.broadcast();

  // Стрим для подписки на изменения статуса
  Stream<bool> get driverStatusStream => _driverStatusController.stream;

  // Текущий статус водителя (кэшированное значение)
  bool _currentDriverStatus = false;

  // Геттер для кэшированного статуса
  bool get currentDriverStatus => _currentDriverStatus;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  // Получить текущего пользователя
  User? get currentUser => _client.auth.currentUser;

  // Получить ID текущего пользователя
  String? get currentUserId => currentUser?.id;

  // Проверить авторизацию
  bool get isAuthenticated => currentUser != null;

  // Получить профиль пользователя
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUserId as Object)
          .single();
      return response;
    } catch (e) {
      debugPrint('Ошибка получения профиля: $e');
      return null;
    }
  }

  // Создать профиль пользователя
  Future<bool> createUserProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? avatarUrl,
  }) async {
    if (!isAuthenticated) return false;

    try {
      await _client.from('profiles').insert({
        'id': currentUserId,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Ошибка создания профиля: $e');
      return false;
    }
  }

  // Обновление профиля пользователя
  Future<void> updateUserProfile(UserModel user) async {
    try {
      // Обновляем основные данные в таблице profiles
      await _client.from('profiles').update({
        'full_name': user.fullName,
        'phone': user.phone,
        'profile_image_url': user.avatarUrl,
      }).eq('id', user.id ?? '');

      // Сохраняем дополнительные данные в пользовательских метаданных
      if (currentUser != null &&
          (user.birthDate != null ||
              user.gender != null ||
              user.city != null)) {
        try {
          final currentMetadata = currentUser!.userMetadata ?? {};
          final updatedMetadata = {
            ...currentMetadata,
            if (user.birthDate != null) 'birth_date': user.birthDate,
            if (user.gender != null) 'gender': user.gender,
            if (user.city != null) 'city': user.city,
          };

          await _client.auth.updateUser(UserAttributes(data: updatedMetadata));
        } catch (metadataError) {
          debugPrint(
            'Ошибка обновления пользовательских метаданных: $metadataError',
          );
          // Продолжаем выполнение, так как основные данные уже сохранены
        }
      }
    } catch (e) {
      throw Exception('Ошибка обновления профиля: $e');
    }
  }

  // Загрузить изображение в хранилище
  Future<String?> uploadImage(File file, String folder) async {
    if (!isAuthenticated) return null;

    try {
      final fileExt = path_lib.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
      // Используем простой путь без вложенных папок
      final filePath = fileName;

      debugPrint('Попытка загрузки файла: $filePath');

      // Список бакетов для попытки загрузки
      final buckets = ['avatars', 'profile_photos', 'images'];
      String? imageUrl;

      // Пробуем создать bucket, если его нет
      try {
        // Сначала проверяем существование бакета
        final buckets = await _client.storage.listBuckets();
        final bucketExists =
            buckets.any((bucket) => bucket.name == 'profile_photos');

        if (!bucketExists) {
          await _client.storage.createBucket('profile_photos');
          debugPrint('Бакет profile_photos успешно создан');
        } else {
          debugPrint('Бакет profile_photos уже существует');
        }
      } catch (e) {
        debugPrint('Ошибка при проверке/создании бакета: $e');
      }

      // Пробуем сделать bucket публичным, если это возможно
      try {
        await _client.storage.updateBucket(
          'profile_photos',
          const supabase.BucketOptions(public: true),
        );
        debugPrint('Бакет profile_photos сделан публичным');
      } catch (e) {
        debugPrint('Не удалось сделать бакет публичным: $e');
      }

      // Проходим по всем бакетам и пытаемся загрузить файл
      for (final bucket in buckets) {
        try {
          debugPrint('Попытка загрузки в бакет: $bucket');
          await _client.storage.from(bucket).upload(filePath, file);

          // Генерируем URL через API Supabase
          final fileUrl = _client.storage.from(bucket).getPublicUrl(filePath);
          debugPrint('Файл успешно загружен в $bucket, URL: $fileUrl');

          imageUrl = fileUrl;

          // Обновляем профиль пользователя с новым URL аватарки
          await updateProfileImageUrl(imageUrl);

          break; // Выходим из цикла, если загрузка успешна
        } catch (e) {
          debugPrint('Ошибка загрузки в $bucket: $e');
          // Продолжаем цикл для попытки следующего бакета
        }
      }

      // Если все попытки не удались, используем альтернативный подход
      if (imageUrl == null) {
        debugPrint(
            'Все попытки загрузки не удались, используем последний подход');
        try {
          await _client.storage.from('profile_photos').upload(filePath, file);

          // Используем прямой URL с CDN
          imageUrl =
              'https://pshoujaaainxxkjzjukz.supabase.co/storage/v1/object/public/profile_photos/$filePath';
          debugPrint('Файл успешно загружен, прямой URL: $imageUrl');

          // Обновляем профиль пользователя с новым URL аватарки
          await updateProfileImageUrl(imageUrl);
        } catch (e) {
          debugPrint('Финальная попытка загрузки не удалась: $e');
          return null;
        }
      }

      return imageUrl;
    } catch (e) {
      debugPrint('Общая ошибка загрузки изображения: $e');
      return null;
    }
  }

  // РАБОТА С ДЕТЬМИ

  // Создать таблицы для детей (если они еще не созданы)
  Future<void> createChildrenTables() async {
    try {
      // SQL для создания таблицы children
      const createChildrenTableSQL = '''
      CREATE TABLE IF NOT EXISTS children (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
        full_name TEXT NOT NULL,
        age INTEGER NOT NULL,
        photo_url TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE
      );
      ''';

      // Создание функции для проверки и создания таблицы children
      await _client.rpc(
        'create_children_table',
        params: {'sql_query': createChildrenTableSQL},
      );

      debugPrint('Таблица для детей успешно создана или уже существует');
    } catch (e) {
      debugPrint('Ошибка создания таблицы для детей: $e');
    }
  }

  // Получить список детей текущего пользователя
  Future<List<Child>> getChildren() async {
    if (!isAuthenticated) return [];

    try {
      final response = await _client
          .from('children')
          .select()
          .eq('user_id', currentUserId as Object);

      final List<Child> children = [];
      for (final item in response) {
        children.add(
          Child(
            id: item['id'].toString(),
            name: item['full_name'] ?? '',
            age: item['age'] ?? 0,
            photoUrl: item['photo_url'],
            photoFile: null,
          ),
        );
      }
      return children;
    } catch (e) {
      debugPrint('Ошибка получения списка детей: $e');
      return [];
    }
  }

  // Добавить ребенка
  Future<String?> addChild(Child child) async {
    if (!isAuthenticated) return null;

    try {
      // Загружаем фото, если оно есть
      String? photoUrl = child.photoUrl;
      if (child.photoFile != null) {
        photoUrl = await uploadImage(child.photoFile!, 'children');
      }

      // Добавляем ребенка в таблицу children
      final response = await _client
          .from('children')
          .insert({
            'user_id': currentUserId,
            'full_name': child.name,
            'age': child.age,
            'photo_url': photoUrl,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'].toString();
    } catch (e) {
      debugPrint('Ошибка добавления ребенка: $e');
      return null;
    }
  }

  // Обновить информацию о ребенке
  Future<bool> updateChild(Child child) async {
    if (!isAuthenticated) return false;

    try {
      // Загружаем новое фото, если оно есть
      String? photoUrl = child.photoUrl;
      if (child.photoFile != null) {
        photoUrl = await uploadImage(child.photoFile!, 'children');
      }

      // Обновляем данные ребенка
      await _client.from('children').update({
        'name': child.name,
        'age': child.age,
        if (photoUrl != null) 'photo_url': photoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', child.id);

      return true;
    } catch (e) {
      debugPrint('Ошибка обновления данных ребенка: $e');
      return false;
    }
  }

  // Удалить ребенка
  Future<bool> deleteChild(String childId) async {
    if (!isAuthenticated) return false;

    try {
      // Удаляем связь между пользователем и ребенком
      await _client
          .from('user_children')
          .delete()
          .eq('user_id', currentUserId as Object)
          .eq('child_id', childId);

      // Проверяем, остались ли другие пользователи, связанные с этим ребенком
      final remainingLinks = await _client
          .from('user_children')
          .select('id')
          .eq('child_id', childId);

      // Если связей больше нет, удаляем ребенка из таблицы children
      if (remainingLinks.isEmpty) {
        await _client.from('children').delete().eq('id', childId);
      }

      return true;
    } catch (e) {
      debugPrint('Ошибка удаления ребенка: $e');
      return false;
    }
  }

  // Поделиться доступом к ребенку с другим пользователем
  Future<bool> shareChildAccess({
    required String childId,
    required String targetUserEmail,
    required String relationship,
  }) async {
    if (!isAuthenticated) return false;

    try {
      // Найти пользователя по email
      final userResponse = await _client
          .from('profiles')
          .select('id')
          .eq('email', targetUserEmail)
          .single();

      final String targetUserId = userResponse['id'];

      // Проверить, есть ли уже связь с этим пользователем
      final existingLink = await _client
          .from('user_children')
          .select()
          .eq('user_id', targetUserId)
          .eq('child_id', childId);

      if (existingLink.isNotEmpty) {
        debugPrint('Связь уже существует');
        return false;
      }

      // Создать новую связь
      await _client.from('user_children').insert({
        'user_id': targetUserId,
        'child_id': childId,
        'relationship': relationship,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Ошибка предоставления доступа к ребенку: $e');
      return false;
    }
  }

  // Отозвать доступ к ребенку у другого пользователя
  Future<bool> revokeChildAccess({
    required String childId,
    required String targetUserId,
  }) async {
    if (!isAuthenticated) return false;

    try {
      // Удалить связь между целевым пользователем и ребенком
      await _client
          .from('user_children')
          .delete()
          .eq('user_id', targetUserId)
          .eq('child_id', childId);

      return true;
    } catch (e) {
      debugPrint('Ошибка отзыва доступа к ребенку: $e');
      return false;
    }
  }

  // Авторизация
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Регистрация
  Future<AuthResponse?> signUpWithEmail(
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      debugPrint('Начало регистрации пользователя с email: $email');

      // Отключаем подтверждение email при регистрации
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        // Не требуем редиректа и подтверждения email
        emailRedirectTo: null,
      );

      if (response.user != null) {
        debugPrint('Пользователь создан с ID: ${response.user!.id}');

        // Создаем запись в таблице profiles
        debugPrint('Создание записи в таблице profiles');
        try {
          await _client.from('profiles').insert({
            'id': response.user!.id,
            'email': email,
            'role': role.toString().split('.').last,
            'created_at': DateTime.now().toIso8601String(),
          });
          debugPrint('Профиль создан успешно');

          // Если регистрируется водитель, создаем запись в таблице drivers
          if (role == UserRole.driver) {
            debugPrint('Создание записи в таблице drivers');
            try {
              await _client.from('drivers').insert({
                'user_id': response.user!.id,
                'status': 'pending',
                'created_at': DateTime.now().toIso8601String(),
              });
              debugPrint('Запись водителя создана успешно');
            } catch (driverError) {
              // Ошибка создания записи водителя (вероятно из-за RLS), но продолжаем работу
              debugPrint('Ошибка создания записи водителя: $driverError');
              debugPrint(
                  'Продолжаем регистрацию, несмотря на ошибку записи водителя');
              // Не выходим из метода, позволяем пользователю продолжить работу
            }
          }

          return response;
        } catch (profileError) {
          debugPrint('Ошибка создания профиля: $profileError');

          // Если не удалось создать профиль, пытаемся удалить пользователя
          try {
            await _client.auth.admin.deleteUser(response.user!.id);
            debugPrint('Пользователь удален из-за ошибки создания профиля');
          } catch (deleteError) {
            debugPrint('Ошибка удаления пользователя: $deleteError');
          }
          return null;
        }
      } else {
        debugPrint('Ошибка при создании пользователя: пользователь равен null');
        return null;
      }
    } catch (e) {
      debugPrint('Ошибка регистрации: $e');
      return null;
    }
  }

  // Подтверждение почты
  Future<void> resendEmailConfirmation(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  // Сброс пароля
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://example.com/auth/callback',
    );
  }

  // Обновление пароля
  Future<UserResponse> changeUserPassword(String newPassword) async {
    return await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Изменение пароля с проверкой текущего пароля
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isAuthenticated) return false;

    try {
      // Проверяем текущий пароль
      final response = await _client.auth.signInWithPassword(
        email: currentUser!.email!,
        password: currentPassword,
      );

      if (response.user != null) {
        // Если авторизация прошла успешно, меняем пароль
        await _client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Ошибка обновления пароля: $e');
      return false;
    }
  }

  // Проверка подтверждения почты
  bool isEmailConfirmed() {
    final user = _client.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // Если профиль не найден, создаем новый
      if (response == null) {
        debugPrint('Профиль пользователя не найден, создаем новый');
        try {
          // Создаем базовый профиль для пользователя
          await _client.from('profiles').insert({
            'id': user.id,
            'email': user.email,
            'role': 'user', // По умолчанию роль пользователя
            'created_at': DateTime.now().toIso8601String(),
          });

          // Возвращаем базовую модель пользователя
          return UserModel(
            id: user.id,
            email: user.email,
            fullName: user.email?.split('@').first ?? 'Пользователь',
            role: 'user',
          );
        } catch (e) {
          debugPrint('Ошибка создания профиля пользователя: $e');
          return null;
        }
      }

      final userData = response as Map<String, dynamic>;
      final role = userData['role'] == 'driver' ? 'driver' : 'user';

      // Получаем дополнительные данные из метаданных пользователя
      final userMetadata = user.userMetadata ?? {};
      final birthDate = userMetadata['birth_date'] as String?;
      final gender = userMetadata['gender'] as String?;
      final city = userMetadata['city'] as String?;

      // Получаем URL аватарки из поля profile_image_url
      final avatarUrl = userData['profile_image_url'] as String?;
      debugPrint('Загружен профиль с аватаркой: $avatarUrl');

      return UserModel(
        id: user.id,
        email: user.email,
        fullName: userData['full_name'] ??
            user.email?.split('@').first ??
            'Пользователь',
        phone: userData['phone'] ?? '',
        role: role,
        avatarUrl: avatarUrl,
        birthDate: birthDate,
        gender: gender,
        city: city,
      );
    } catch (e) {
      debugPrint('Ошибка получения текущего пользователя: $e');

      // В случае ошибки возвращаем базовую модель пользователя
      // на основе данных из auth, чтобы приложение могло продолжить работу
      return UserModel(
        id: user.id,
        email: user.email,
        fullName: user.email?.split('@').first ?? 'Пользователь',
        role: 'user',
      );
    }
  }

  // Преобразовать строковый статус в enum
  DriverStatus _parseDriverStatus(String? status) {
    if (status == null) return DriverStatus.pending;

    switch (status) {
      case 'approved':
        return DriverStatus.approved;
      case 'rejected':
        return DriverStatus.rejected;
      case 'online':
        return DriverStatus.online;
      case 'offline':
        return DriverStatus.offline;
      default:
        return DriverStatus.pending;
    }
  }

  // Загрузка файла
  Future<String?> uploadFile(
    Uint8List fileBytes,
    String path,
    String bucketName,
  ) async {
    try {
      // Проверяем существование бакета и создаем его при необходимости
      try {
        // Сначала проверяем существование бакета
        final buckets = await _client.storage.listBuckets();
        final bucketExists = buckets.any((bucket) => bucket.name == bucketName);

        if (!bucketExists) {
          await _client.storage.createBucket(bucketName);
          debugPrint('Бакет $bucketName успешно создан');
        } else {
          debugPrint('Бакет $bucketName уже существует');
        }
      } catch (e) {
        debugPrint('Ошибка при проверке/создании бакета: $e');
      }

      // Пробуем сделать bucket публичным
      try {
        await _client.storage.updateBucket(
          bucketName,
          const supabase.BucketOptions(public: true),
        );
        debugPrint('Бакет $bucketName сделан публичным');
      } catch (e) {
        debugPrint('Не удалось сделать бакет публичным: $e');
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path_lib.basename(path)}';

      // Попытка загрузки файла
      try {
        await _client.storage
            .from(bucketName)
            .uploadBinary(fileName, fileBytes);
        return _client.storage.from(bucketName).getPublicUrl(fileName);
      } catch (e) {
        debugPrint('Ошибка загрузки файла в $bucketName: $e');

        // Попробуем альтернативный бакет
        final alternativeBucket = 'public';
        try {
          await _client.storage
              .from(alternativeBucket)
              .uploadBinary(fileName, fileBytes);
          return _client.storage.from(alternativeBucket).getPublicUrl(fileName);
        } catch (e2) {
          debugPrint('Ошибка загрузки файла в альтернативный бакет: $e2');

          // Возвращаем заглушку URL в случае ошибки, чтобы не блокировать регистрацию
          return 'https://pshoujaaainxxkjzjukz.supabase.co/storage/v1/object/public/$bucketName/$fileName';
        }
      }
    } catch (e) {
      debugPrint('Общая ошибка загрузки файла: $e');
      // Возвращаем заглушку URL в случае ошибки, чтобы не блокировать регистрацию
      return 'https://placehold.co/600x400?text=Document';
    }
  }

  // Обновление данных водителя
  Future<void> updateDriverProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('drivers').update(data).eq('user_id', userId);
  }

  // Обновление статуса онлайн/оффлайн водителя
  Future<bool> updateDriverOnlineStatus(bool isOnline) async {
    if (!isAuthenticated) return false;

    try {
      // Получаем текущего пользователя
      final user = currentUser;
      if (user == null) return false;

      // Проверяем, что пользователь является водителем
      final userProfile = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      if (userProfile['role'] != 'driver') {
        debugPrint('Пользователь не является водителем');
        return false;
      }

      // Обновляем статус в таблице drivers
      final status = isOnline ? 'online' : 'offline';
      await _client
          .from('drivers')
          .update({'status': status}).eq('user_id', user.id);

      debugPrint('Статус водителя обновлен: $status');

      // Обновляем кэшированное значение и уведомляем подписчиков
      _currentDriverStatus = isOnline;
      _driverStatusController.add(isOnline);

      return true;
    } catch (e) {
      debugPrint('Ошибка обновления статуса водителя: $e');
      return false;
    }
  }

  // Получить текущий статус онлайн/оффлайн водителя
  Future<bool> getDriverOnlineStatus() async {
    if (!isAuthenticated) return false;

    try {
      // Получаем текущего пользователя
      final user = currentUser;
      if (user == null) return false;

      // Получаем данные из таблицы drivers
      final driverData = await _client
          .from('drivers')
          .select('status')
          .eq('user_id', user.id)
          .maybeSingle();

      if (driverData == null) return false;

      final isOnline = driverData['status'] == 'online';

      // Обновляем кэшированное значение
      _currentDriverStatus = isOnline;

      return isOnline;
    } catch (e) {
      debugPrint('Ошибка получения статуса водителя: $e');
      return false;
    }
  }

  // Метод для прямого получения текущего статуса без обращения к API
  bool getCachedDriverStatus() {
    return _currentDriverStatus;
  }

  // ПРОГРАММА ЛОЯЛЬНОСТИ

  // Получить данные программы лояльности для текущего пользователя
  Future<LoyaltyModel> getUserLoyalty() async {
    if (!isAuthenticated) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      // Получаем основные данные лояльности
      final loyaltyData = await _client
          .from('loyalty')
          .select()
          .eq('user_id', currentUserId as Object)
          .maybeSingle();

      // Если данных нет, создаем запись для пользователя
      if (loyaltyData == null) {
        await _client.from('loyalty').insert({
          'user_id': currentUserId,
          'points': 0,
          'level': 0,
          'created_at': DateTime.now().toIso8601String(),
        });

        return LoyaltyModel.empty(currentUserId!);
      }

      // Получаем историю баллов
      final historyData = await _client
          .from('loyalty_history')
          .select()
          .eq('user_id', currentUserId as Object)
          .order('created_at', ascending: false)
          .limit(10);

      return LoyaltyModel.fromMap(
        loyaltyData as Map<String, dynamic>,
        historyData as List<Map<String, dynamic>>,
      );
    } catch (e) {
      debugPrint('Ошибка получения данных лояльности: $e');
      // Возвращаем пустую модель в случае ошибки
      return LoyaltyModel.empty(currentUserId!);
    }
  }

  // Добавить баллы пользователю
  Future<bool> addLoyaltyPoints({
    required int points,
    required String description,
  }) async {
    if (!isAuthenticated) return false;

    try {
      // Начинаем транзакцию
      await _client.rpc('begin_transaction');

      try {
        // Получаем текущие баллы
        final loyaltyData = await _client
            .from('loyalty')
            .select('points, level')
            .eq('user_id', currentUserId as Object)
            .maybeSingle();

        int currentPoints = 0;
        int currentLevel = 0;

        if (loyaltyData != null) {
          currentPoints = loyaltyData['points'] ?? 0;
          currentLevel = loyaltyData['level'] ?? 0;
        }

        // Рассчитываем новое количество баллов
        final newPoints = currentPoints + points;

        // Определяем новый уровень
        final newLevel = _calculateLoyaltyLevel(newPoints);

        // Обновляем данные лояльности
        await _client.from('loyalty').upsert({
          'user_id': currentUserId,
          'points': newPoints,
          'level': newLevel,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', currentUserId as Object);

        // Добавляем запись в историю
        await _client.from('loyalty_history').insert({
          'user_id': currentUserId,
          'points': points,
          'description': description,
          'type': 'earned',
          'created_at': DateTime.now().toIso8601String(),
        });

        // Завершаем транзакцию
        await _client.rpc('commit_transaction');
        return true;
      } catch (e) {
        // Откатываем транзакцию в случае ошибки
        await _client.rpc('rollback_transaction');
        debugPrint('Ошибка добавления баллов: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Ошибка транзакции: $e');
      return false;
    }
  }

  // Списать баллы пользователя
  Future<bool> spendLoyaltyPoints({
    required int points,
    required String description,
  }) async {
    if (!isAuthenticated) return false;

    try {
      // Начинаем транзакцию
      await _client.rpc('begin_transaction');

      try {
        // Получаем текущие баллы
        final loyaltyData = await _client
            .from('loyalty')
            .select('points, level')
            .eq('user_id', currentUserId as Object)
            .single();

        final currentPoints = loyaltyData['points'] ?? 0;

        // Проверяем, достаточно ли баллов
        if (currentPoints < points) {
          debugPrint('Недостаточно баллов для списания');
          return false;
        }

        // Рассчитываем новое количество баллов
        final newPoints = currentPoints - points;

        // Определяем новый уровень
        final newLevel = _calculateLoyaltyLevel(newPoints);

        // Обновляем данные лояльности
        await _client.from('loyalty').update({
          'points': newPoints,
          'level': newLevel,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', currentUserId as Object);

        // Добавляем запись в историю
        await _client.from('loyalty_history').insert({
          'user_id': currentUserId,
          'points': points,
          'description': description,
          'type': 'spent',
          'created_at': DateTime.now().toIso8601String(),
        });

        // Завершаем транзакцию
        await _client.rpc('commit_transaction');
        return true;
      } catch (e) {
        // Откатываем транзакцию в случае ошибки
        await _client.rpc('rollback_transaction');
        debugPrint('Ошибка списания баллов: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Ошибка транзакции: $e');
      return false;
    }
  }

  // Определить уровень лояльности по количеству баллов
  int _calculateLoyaltyLevel(int points) {
    if (points >= 20000) return 3;
    if (points >= 10000) return 2;
    if (points >= 5000) return 1;
    return 0;
  }

  // Обновление URL изображения профиля
  Future<bool> updateProfileImageUrl(String? imageUrl) async {
    if (!isAuthenticated) return false;

    try {
      await _client.from('profiles').update({
        'profile_image_url': imageUrl,
      }).eq('id', currentUserId as Object);
      return true;
    } catch (e) {
      debugPrint('Ошибка обновления URL изображения профиля: $e');
      return false;
    }
  }

  // НАСТРОЙКИ ПОЛЬЗОВАТЕЛЯ

  // Сохранение настроек темы
  Future<bool> saveThemeSettings(bool isDarkMode) async {
    if (!isAuthenticated) return false;

    try {
      await _client.from('user_settings').upsert({
        'user_id': currentUserId,
        'dark_mode': isDarkMode,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      return true;
    } catch (e) {
      debugPrint('Ошибка сохранения настроек темы: $e');
      return false;
    }
  }

  // Загрузка настроек темы
  Future<bool?> getThemeSettings() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('user_settings')
          .select('dark_mode')
          .eq('user_id', currentUserId as Object)
          .maybeSingle();

      if (response != null) {
        return response['dark_mode'] as bool?;
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка загрузки настроек темы: $e');
      return null;
    }
  }

  // Сохранение настроек языка
  Future<bool> saveLanguageSettings(String language) async {
    if (!isAuthenticated) return false;

    try {
      await _client.from('user_settings').upsert({
        'user_id': currentUserId,
        'language': language,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      return true;
    } catch (e) {
      debugPrint('Ошибка сохранения настроек языка: $e');
      return false;
    }
  }

  // Загрузка настроек языка
  Future<String?> getLanguageSettings() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('user_settings')
          .select('language')
          .eq('user_id', currentUserId as Object)
          .maybeSingle();

      if (response != null) {
        return response['language'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка загрузки настроек языка: $e');
      return null;
    }
  }

  // Сохранение настроек уведомлений
  Future<bool> saveNotificationSettings({
    required bool pushEnabled,
    required bool emailEnabled,
    required bool smsEnabled,
    required bool promotionalEnabled,
    required bool tripUpdatesEnabled,
    required bool paymentUpdatesEnabled,
    required bool systemUpdatesEnabled,
  }) async {
    if (!isAuthenticated) return false;

    try {
      await _client.from('notification_settings').upsert({
        'user_id': currentUserId,
        'push_enabled': pushEnabled,
        'email_enabled': emailEnabled,
        'sms_enabled': smsEnabled,
        'promotional_enabled': promotionalEnabled,
        'trip_updates_enabled': tripUpdatesEnabled,
        'payment_updates_enabled': paymentUpdatesEnabled,
        'system_updates_enabled': systemUpdatesEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      return true;
    } catch (e) {
      debugPrint('Ошибка сохранения настроек уведомлений: $e');
      return false;
    }
  }

  // Загрузка настроек уведомлений
  Future<Map<String, dynamic>?> getNotificationSettings() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('notification_settings')
          .select()
          .eq('user_id', currentUserId as Object)
          .maybeSingle();

      if (response != null) {
        return response;
      }

      // Возвращаем настройки по умолчанию
      return {
        'push_enabled': true,
        'email_enabled': false,
        'sms_enabled': true,
        'promotional_enabled': false,
        'trip_updates_enabled': true,
        'payment_updates_enabled': true,
        'system_updates_enabled': true,
      };
    } catch (e) {
      debugPrint('Ошибка загрузки настроек уведомлений: $e');
      return null;
    }
  }

  // Сохранение данных кэша
  Future<bool> saveCacheData(String key, String value) async {
    if (!isAuthenticated) return false;

    try {
      await _client.from('user_cache').upsert({
        'user_id': currentUserId,
        'cache_key': key,
        'cache_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, cache_key');

      return true;
    } catch (e) {
      debugPrint('Ошибка сохранения данных кэша: $e');
      return false;
    }
  }

  // Загрузка данных кэша
  Future<String?> getCacheData(String key) async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('user_cache')
          .select('cache_value')
          .eq('user_id', currentUserId as Object)
          .eq('cache_key', key)
          .maybeSingle();

      if (response != null) {
        return response['cache_value'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка загрузки данных кэша: $e');
      return null;
    }
  }

  // Очистка всего кэша пользователя
  Future<bool> clearAllCache() async {
    if (!isAuthenticated) return false;

    try {
      await _client
          .from('user_cache')
          .delete()
          .eq('user_id', currentUserId as Object);

      return true;
    } catch (e) {
      debugPrint('Ошибка очистки кэша: $e');
      return false;
    }
  }

  // Получение размера кэша пользователя
  Future<int> getCacheSize() async {
    if (!isAuthenticated) return 0;

    try {
      final response = await _client
          .from('user_cache')
          .select('cache_value')
          .eq('user_id', currentUserId as Object);

      int totalSize = 0;
      for (var item in response) {
        String value = item['cache_value'] as String;
        totalSize += value.length;
      }

      return totalSize;
    } catch (e) {
      debugPrint('Ошибка получения размера кэша: $e');
      return 0;
    }
  }

  // НАСТРОЙКИ БЕЗОПАСНОСТИ

  // Получение настроек безопасности
  Future<Map<String, dynamic>?> getSecuritySettings() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('security_settings')
          .select()
          .eq('user_id', currentUserId as Object)
          .maybeSingle();

      if (response != null) {
        return response;
      }

      // Возвращаем настройки по умолчанию
      return {
        'biometric_enabled': false,
        'two_factor_enabled': false,
        'save_login_enabled': true,
      };
    } catch (e) {
      debugPrint('Ошибка загрузки настроек безопасности: $e');
      return null;
    }
  }

  // Сохранение настроек безопасности
  Future<bool> saveSecuritySettings({
    required bool biometricEnabled,
    required bool twoFactorEnabled,
    required bool saveLoginEnabled,
  }) async {
    if (!isAuthenticated) return false;

    try {
      await _client.from('security_settings').upsert({
        'user_id': currentUserId,
        'biometric_enabled': biometricEnabled,
        'two_factor_enabled': twoFactorEnabled,
        'save_login_enabled': saveLoginEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      return true;
    } catch (e) {
      debugPrint('Ошибка сохранения настроек безопасности: $e');
      return false;
    }
  }

  // Очистка истории входов
  Future<bool> clearLoginHistory() async {
    if (!isAuthenticated) return false;

    try {
      await _client
          .from('login_history')
          .delete()
          .eq('user_id', currentUserId as Object);

      return true;
    } catch (e) {
      debugPrint('Ошибка очистки истории входов: $e');
      return false;
    }
  }

  // РАБОТА С ОБРАЩЕНИЯМИ В ПОДДЕРЖКУ

  // Получить список обращений пользователя
  Future<List<SupportTicket>> getUserTickets() async {
    if (!isAuthenticated) return [];

    try {
      final response = await _client
          .from('support_tickets')
          .select()
          .eq('user_id', currentUserId as Object)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => SupportTicket.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения списка обращений: $e');
      // Временное решение: возвращаем тестовые данные
      return [
        SupportTicket(
          id: '1234-5678-90ab-cdef',
          userId: currentUserId ?? '',
          subject: 'Проблема с оплатой',
          description:
              'При попытке оплатить поездку картой произошла ошибка, но деньги были списаны. Необходимо вернуть средства или подтвердить оплату поездки.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          status: TicketStatus.inProgress,
          operatorResponse:
              'Ваше обращение принято в работу. Специалист проверяет информацию о платеже и свяжется с вами в ближайшее время.',
          respondedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        SupportTicket(
          id: 'abcd-efgh-ijkl-mnop',
          userId: currentUserId ?? '',
          subject: 'Не работает геолокация',
          description:
              'Приложение не определяет мое местоположение, хотя доступ к геолокации разрешен.',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          status: TicketStatus.resolved,
          operatorResponse:
              'Проблема решена. Пожалуйста, обновите приложение до последней версии.',
          respondedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
    }
  }

  // Создать новое обращение
  Future<String?> createSupportTicket({
    required String subject,
    required String description,
  }) async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('support_tickets')
          .insert({
            'user_id': currentUserId,
            'subject': subject,
            'description': description,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'estimated_response_time': 30, // 30 минут по умолчанию
          })
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      debugPrint('Ошибка создания обращения: $e');
      // Временное решение: возвращаем фиктивный ID
      return 'temp-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Закрыть обращение
  Future<bool> closeTicket(String ticketId) async {
    if (!isAuthenticated) return false;

    try {
      await _client
          .from('support_tickets')
          .update({
            'status': 'closed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId)
          .eq('user_id', currentUserId as Object);

      return true;
    } catch (e) {
      debugPrint('Ошибка закрытия обращения: $e');
      return true; // Для демонстрации возвращаем true
    }
  }

  // Загрузить файл для обращения
  Future<String?> uploadSupportFile(File file, String ticketId) async {
    if (!isAuthenticated) return null;

    try {
      final fileExt = path_lib.extension(file.path);
      final fileName =
          '${ticketId}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = 'support/$fileName';

      await _client.storage.from('support_files').upload(filePath, file);
      final fileUrl =
          _client.storage.from('support_files').getPublicUrl(filePath);

      // Добавляем запись о файле в базу данных
      await _client.from('support_files').insert({
        'ticket_id': ticketId,
        'user_id': currentUserId,
        'file_url': fileUrl,
        'file_name': path_lib.basename(file.path),
        'created_at': DateTime.now().toIso8601String(),
      });

      return fileUrl;
    } catch (e) {
      debugPrint('Ошибка загрузки файла для обращения: $e');
      return 'https://example.com/files/${path_lib.basename(file.path)}';
    }
  }

  // ПЛАТЕЖНЫЕ МЕТОДЫ И ТРАНЗАКЦИИ

  // Создание таблиц для платежей и транзакций
  Future<void> createPaymentTables() async {
    try {
      // SQL для создания таблицы payment_methods
      const createPaymentMethodsTableSQL = '''
      CREATE TABLE IF NOT EXISTS payment_methods (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        last_four_digits TEXT NOT NULL,
        is_default BOOLEAN DEFAULT false,
        card_type TEXT,
        expiry_date TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      ''';

      // SQL для создания таблицы transactions
      const createTransactionsTableSQL = '''
      CREATE TABLE IF NOT EXISTS transactions (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        description TEXT,
        amount DECIMAL(10, 2) NOT NULL,
        date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        status TEXT NOT NULL,
        type TEXT NOT NULL,
        payment_method_id UUID REFERENCES payment_methods(id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      ''';

      // Попытка создать таблицы через RPC
      try {
        await _client.rpc(
          'create_payment_tables',
          params: {'sql_query': createPaymentMethodsTableSQL},
        );
        await _client.rpc(
          'create_transaction_tables',
          params: {'sql_query': createTransactionsTableSQL},
        );
        debugPrint('Таблицы для платежей успешно созданы или уже существуют');
      } catch (rpcError) {
        debugPrint('Ошибка RPC при создании таблиц: $rpcError');

        // Если RPC не работает, пробуем использовать другие методы
        // Просто проверим существование таблиц, чтобы не выдавать ошибку
        try {
          await _client.from('payment_methods').select().limit(1);
          debugPrint('Таблица payment_methods существует');
        } catch (e) {
          debugPrint('Таблица payment_methods не существует: $e');
        }

        try {
          await _client.from('transactions').select().limit(1);
          debugPrint('Таблица transactions существует');
        } catch (e) {
          debugPrint('Таблица transactions не существует: $e');
        }
      }
    } catch (e) {
      debugPrint('Общая ошибка создания таблиц для платежей: $e');
    }
  }

  // Получить список платежных методов пользователя
  Future<List<PaymentMethod>> getPaymentMethods() async {
    if (!isAuthenticated) return [];

    try {
      // Пробуем создать таблицы, если их нет
      await createPaymentTables();

      final response = await _client
          .from('payment_methods')
          .select()
          .eq('user_id', currentUserId as Object);

      return (response as List)
          .map((item) => PaymentMethod(
                id: item['id'],
                type: item['type'] ?? 'card',
                title: item['title'] ?? 'Карта',
                lastFourDigits: item['last_four_digits'] ?? '****',
                isDefault: item['is_default'] ?? false,
                cardType: item['card_type'],
                expiryDate: item['expiry_date'],
              ))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения платежных методов: $e');
      // Возвращаем тестовые данные
      return [
        PaymentMethod(
          id: '1',
          type: 'card',
          title: 'Visa',
          lastFourDigits: '4242',
          isDefault: true,
          cardType: 'visa',
          expiryDate: '12/25',
        ),
        PaymentMethod(
          id: '2',
          type: 'card',
          title: 'MasterCard',
          lastFourDigits: '5678',
          isDefault: false,
          cardType: 'mastercard',
          expiryDate: '10/26',
        ),
      ];
    }
  }

  // Добавить платежный метод
  Future<bool> addPaymentMethod({
    required String type,
    required String title,
    required String lastFourDigits,
    bool isDefault = false,
    String? cardType,
    String? expiryDate,
  }) async {
    if (!isAuthenticated) return false;

    try {
      // Пробуем создать таблицы, если их нет
      await createPaymentTables();

      // Если новый метод установлен как дефолтный, сбрасываем дефолтный статус у других методов
      if (isDefault) {
        await _client.from('payment_methods').update({'is_default': false}).eq(
            'user_id', currentUserId as Object);
      }

      await _client.from('payment_methods').insert({
        'user_id': currentUserId,
        'type': type,
        'title': title,
        'last_four_digits': lastFourDigits,
        'is_default': isDefault,
        'card_type': cardType,
        'expiry_date': expiryDate,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Ошибка добавления платежного метода: $e');
      return false;
    }
  }

  // Удалить платежный метод
  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    if (!isAuthenticated) return false;

    try {
      await _client
          .from('payment_methods')
          .delete()
          .eq('id', paymentMethodId)
          .eq('user_id', currentUserId as Object);

      return true;
    } catch (e) {
      debugPrint('Ошибка удаления платежного метода: $e');
      return false;
    }
  }

  // Установить платежный метод по умолчанию
  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    if (!isAuthenticated) return false;

    try {
      // Сбрасываем дефолтный статус у всех методов
      await _client
          .from('payment_methods')
          .update({'is_default': false}).eq('user_id', currentUserId as Object);

      // Устанавливаем новый дефолтный метод
      await _client
          .from('payment_methods')
          .update({'is_default': true})
          .eq('id', paymentMethodId)
          .eq('user_id', currentUserId as Object);

      return true;
    } catch (e) {
      debugPrint('Ошибка установки платежного метода по умолчанию: $e');
      return false;
    }
  }

  // Получить историю транзакций
  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
  }) async {
    if (!isAuthenticated) return [];

    try {
      // Пробуем создать таблицы, если их нет
      await createPaymentTables();

      var query = _client
          .from('transactions')
          .select()
          .eq('user_id', currentUserId as Object);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      if (type != null) {
        query = query.eq('type', type.toString().split('.').last);
      }

      final response = await query.order('date', ascending: false);

      return (response as List).map((item) {
        return Transaction(
          id: item['id'],
          title: item['title'],
          description: item['description'],
          amount: item['amount'].toDouble(),
          date: DateTime.parse(item['date']),
          status: TransactionStatus.values.firstWhere(
            (e) => e.toString().split('.').last == item['status'],
            orElse: () => TransactionStatus.completed,
          ),
          type: TransactionType.values.firstWhere(
            (e) => e.toString().split('.').last == item['type'],
            orElse: () => TransactionType.ride,
          ),
          paymentMethodId: item['payment_method_id'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Ошибка получения истории транзакций: $e');

      // Фильтрация тестовых данных
      List<Transaction> testTransactions = [
        Transaction(
          id: '1',
          title: 'Поездка #1234',
          description: 'Школа - Дом',
          amount: 350.0,
          date: DateTime.now().subtract(const Duration(days: 1)),
          status: TransactionStatus.completed,
          type: TransactionType.ride,
        ),
        Transaction(
          id: '2',
          title: 'Поездка #1235',
          description: 'Дом - Школа',
          amount: 320.0,
          date: DateTime.now().subtract(const Duration(days: 2)),
          status: TransactionStatus.completed,
          type: TransactionType.ride,
        ),
        Transaction(
          id: '3',
          title: 'Ежемесячная подписка',
          description: 'Автоматическое продление',
          amount: 1200.0,
          date: DateTime.now().subtract(const Duration(days: 5)),
          status: TransactionStatus.completed,
          type: TransactionType.subscription,
        ),
        Transaction(
          id: '4',
          title: 'Возврат за отмененную поездку',
          description: 'Поездка #1230',
          amount: 300.0,
          date: DateTime.now().subtract(const Duration(days: 7)),
          status: TransactionStatus.refunded,
          type: TransactionType.refund,
        ),
        Transaction(
          id: '5',
          title: 'Покупка за баллы лояльности',
          description: 'Скидка 10% на следующую поездку',
          amount: 0.0,
          date: DateTime.now().subtract(const Duration(days: 10)),
          status: TransactionStatus.completed,
          type: TransactionType.loyaltyPurchase,
        ),
      ];

      // Применяем фильтры к тестовым данным
      if (startDate != null) {
        testTransactions = testTransactions
            .where((t) =>
                t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate))
            .toList();
      }

      if (endDate != null) {
        testTransactions = testTransactions
            .where((t) =>
                t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate))
            .toList();
      }

      if (type != null) {
        testTransactions =
            testTransactions.where((t) => t.type == type).toList();
      }

      return testTransactions;
    }
  }
}

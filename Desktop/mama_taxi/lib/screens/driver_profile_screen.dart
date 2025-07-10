import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/constants.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import 'edit_profile_screen.dart';
import 'driver_loyalty_screen.dart';
import 'support_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_verification_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  UserModel? _driverProfile;
  bool _isLoading = true;
  bool _isOnline = false;

  // Подписка на изменения статуса
  StreamSubscription<bool>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
    _loadDriverStatus();

    // Подписываемся на изменения статуса
    _statusSubscription =
        _supabaseService.driverStatusStream.listen((isOnline) {
      debugPrint('DriverProfileScreen: Получено обновление статуса: $isOnline');
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  @override
  void dispose() {
    // Отписываемся при уничтожении экрана
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDriverProfile() async {
    try {
      final driver = await _supabaseService.getCurrentUser();
      setState(() {
        _driverProfile = driver;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки профиля водителя: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Загрузка статуса водителя
  Future<void> _loadDriverStatus() async {
    try {
      final isOnline = await _supabaseService.getDriverOnlineStatus();
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки статуса водителя: $e');
    }
  }

  // Обновление статуса водителя
  Future<void> _updateDriverStatus(bool isOnline) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _supabaseService.updateDriverOnlineStatus(isOnline);
      if (success) {
        setState(() {
          _isOnline = isOnline;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOnline ? 'Вы теперь онлайн' : 'Вы теперь офлайн',
            ),
            backgroundColor: isOnline ? Colors.green : Colors.grey,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось обновить статус'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка обновления статуса водителя: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Личный кабинет',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Профиль водителя
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        // Аватар водителя
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            image: _driverProfile?.avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      _driverProfile!.avatarUrl!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _driverProfile?.avatarUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _driverProfile?.fullName ?? 'Имя не указано',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _driverProfile?.phone ?? 'Телефон не указан',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            // Редактирование профиля
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                  userProfile: _driverProfile,
                                ),
                              ),
                            ).then((result) {
                              // Если профиль был обновлен, перезагружаем данные
                              if (result == true) {
                                _loadDriverProfile();
                              }
                            });
                          },
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      ],
                    ),
                  ),

                  // Статус онлайн/офлайн
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Статус',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              _isOnline ? 'Онлайн' : 'Офлайн',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Переключатель онлайн/офлайн
                        Switch(
                          value: _isOnline,
                          onChanged: (value) {
                            _updateDriverStatus(value);
                          },
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFFF654AA),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  // Статистика
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Заработок
                        Expanded(
                          child: Container(
                            height: 112,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Заработок',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  'сегодня',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '4,580₽',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Поездки
                        Expanded(
                          child: Container(
                            height: 112,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Поездок сегодня',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '12',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Меню
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildMenuItem('История заказов', Icons.history),
                        _buildMenuItem('График работы', Icons.calendar_today),
                        _buildMenuItem(
                          'Доходы и выплаты',
                          Icons.monetization_on,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DriverEarningsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          'Программа лояльности',
                          Icons.card_giftcard,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DriverLoyaltyScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem('Настройки', Icons.settings),
                        _buildMenuItem(
                          'Поддержка',
                          Icons.help,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SupportScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          'Документы и верификация',
                          Icons.badge_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DriverVerificationScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.black),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/constants.dart';
import '../widgets/driver_sidebar.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../widgets/custom_yandex_map.dart';

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({super.key});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  // Контроллер для управления нижним баром
  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();

  // Состояния нижнего бара
  double _initialSheetSize = 0.3; // Начальный размер (30% экрана)
  double _minSheetSize = 0.1; // Минимальный размер (10% экрана)
  double _maxSheetSize = 0.7; // Максимальный размер (70% экрана)

  // Статус заказа
  String _orderStatus =
      'available'; // available, assigned, inProgress, completed

  // Текущая поездка (заглушка)
  final Map<String, dynamic> _currentRide = {
    'id': '12345',
    'clientName': 'Анна Иванова',
    'startLocation': 'ул. Ленина, 42',
    'endLocation': 'ул. Пушкина, 15',
    'price': '450₽',
    'distance': '5.2 км',
    'duration': '15 мин',
    'childName': 'Миша',
    'childAge': '10 лет',
    'specialRequirements': 'Детское автокресло',
  };

  // Состояние боковой панели
  bool _isSidebarOpen = false;

  // Сервис для доступа к Supabase
  final SupabaseService _supabaseService = SupabaseService();
  // Текущий пользователь (водитель)
  UserModel? _currentDriver;
  bool _isLoading = true;
  bool _isOnline = false;

  // Подписка на изменения статуса
  StreamSubscription<bool>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _loadDriverStatus();

    // Подписываемся на изменения статуса
    _statusSubscription =
        _supabaseService.driverStatusStream.listen((isOnline) {
      debugPrint('Получено обновление статуса: $isOnline');
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

  // Загрузка данных текущего водителя
  Future<void> _loadDriverData() async {
    try {
      final driver = await _supabaseService.getCurrentUser();
      setState(() {
        _currentDriver = driver;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки данных водителя: $e');
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
      body: Stack(
        children: [
          // Реальная карта на фоне
          const CustomYandexMap(),

          // Верхняя навигационная панель
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 59,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleSidebar,
                      child: const Icon(Icons.menu, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      'Мама такси',
                      style: TextStyle(
                        fontSize: 24,
                        color: AppColors.success,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9999),
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Кнопка "онлайн/офлайн"
          Positioned(
            top: 80,
            right: 16,
            child: GestureDetector(
              onTap: () => _updateDriverStatus(!_isOnline),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isOnline ? AppColors.success : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 12),
                    SizedBox(width: 8),
                    Text(
                      _isOnline ? 'Онлайн' : 'Оффлайн',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Нижний бар с перетаскиванием
          DraggableScrollableSheet(
            initialChildSize: _initialSheetSize,
            minChildSize: _minSheetSize,
            maxChildSize: _maxSheetSize,
            controller: _bottomSheetController,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Индикатор перетаскивания
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),

                      // Секция с информацией в зависимости от статуса
                      if (_orderStatus == 'available')
                        _buildAvailableSection()
                      else if (_orderStatus == 'assigned')
                        _buildAssignedSection()
                      else if (_orderStatus == 'inProgress')
                        _buildInProgressSection()
                      else
                        _buildCompletedSection(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),

          // Боковая панель (выдвигается слева)
          if (_isSidebarOpen)
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx < -10) {
                    _toggleSidebar();
                  }
                },
                child: Row(
                  children: [
                    DriverSidebar(
                      driverName: _currentDriver?.fullName ?? "Загрузка...",
                      driverRating: _currentDriver is DriverModel
                          ? (_currentDriver as DriverModel).rating
                          : '0.0',
                      driverImageUrl: _currentDriver?.avatarUrl,
                      onClose: _toggleSidebar,
                      isOnline: _isOnline,
                      onStatusChange: _updateDriverStatus,
                    ),
                    // Полупрозрачная область для закрытия при нажатии
                    GestureDetector(
                      onTap: _toggleSidebar,
                      child: Container(width: 50, color: Colors.transparent),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _changeOrderStatus,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // Переключение состояния боковой панели
  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  // Изменение статуса заказа (для демонстрации)
  void _changeOrderStatus() {
    setState(() {
      if (_orderStatus == 'available')
        _orderStatus = 'assigned';
      else if (_orderStatus == 'assigned')
        _orderStatus = 'inProgress';
      else if (_orderStatus == 'inProgress')
        _orderStatus = 'completed';
      else
        _orderStatus = 'available';
    });
  }

  // Секция когда нет активных заказов
  Widget _buildAvailableSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Нет активных заказов',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Rubik',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ожидание заказов',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontFamily: 'Rubik',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Статистика за сегодня',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Rubik',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Поездок', '3'),
                    _buildStatItem('Заработано', '1350₽'),
                    _buildStatItem('Онлайн', '4ч 12м'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Секция с назначенным заказом
  Widget _buildAssignedSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Новый заказ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Rubik',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFF3F4F6),
                      child: Icon(Icons.person, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentRide['clientName'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontFamily: 'Rubik',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      _currentRide['price'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                _buildAddressRow(
                  'Откуда',
                  _currentRide['startLocation'],
                  Icons.circle_outlined,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  width: 1,
                  height: 16,
                  color: AppColors.link,
                ),
                _buildAddressRow(
                  'Куда',
                  _currentRide['endLocation'],
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Ребенок',
                  '${_currentRide['childName']}, ${_currentRide['childAge']}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Требования',
                  _currentRide['specialRequirements'],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Отклонить заказ
                          setState(() {
                            _orderStatus = 'available';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.text,
                          side: BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Отклонить'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Принять заказ
                          setState(() {
                            _orderStatus = 'inProgress';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Принять'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Секция с заказом в процессе
  Widget _buildInProgressSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'В пути',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Осталось 10 мин',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFF3F4F6),
                      child: Icon(Icons.person, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentRide['clientName'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontFamily: 'Rubik',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      _currentRide['price'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                _buildAddressRow(
                  'Откуда',
                  _currentRide['startLocation'],
                  Icons.circle_outlined,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  width: 1,
                  height: 16,
                  color: AppColors.link,
                ),
                _buildAddressRow(
                  'Куда',
                  _currentRide['endLocation'],
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Ребенок',
                  '${_currentRide['childName']}, ${_currentRide['childAge']}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Требования',
                  _currentRide['specialRequirements'],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Позвонить
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.text,
                          side: BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone, size: 18),
                            SizedBox(width: 8),
                            Text('Позвонить'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Завершить поездку
                          setState(() {
                            _orderStatus = 'completed';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Завершить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Секция с завершенным заказом
  Widget _buildCompletedSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Поездка завершена',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Rubik',
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildResultItem('Заработано', _currentRide['price']),
                    _buildResultItem('Расстояние', _currentRide['distance']),
                    _buildResultItem('Время', _currentRide['duration']),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                const Text(
                  'Оцените поездку',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Rubik',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 32,
                      color: index < 4
                          ? const Color(0xFFF59E0B)
                          : Colors.grey[300],
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Перейти к новым заказам
                      setState(() {
                        _orderStatus = 'available';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Готов к новым заказам'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательные виджеты
  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Rubik',
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow(String title, String address, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 12),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              address,
              style: const TextStyle(fontSize: 14, fontFamily: 'Rubik'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Rubik',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontFamily: 'Rubik'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Rubik',
          ),
        ),
      ],
    );
  }
}

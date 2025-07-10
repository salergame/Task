import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/driver_schedule_model.dart';
import '../services/driver_schedule_service.dart';
import '../services/supabase_service.dart';

class DriverScheduleScreen extends StatefulWidget {
  const DriverScheduleScreen({super.key});

  @override
  State<DriverScheduleScreen> createState() => _DriverScheduleScreenState();
}

class _DriverScheduleScreenState extends State<DriverScheduleScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late final DriverScheduleService _scheduleService;

  List<DriverScheduleItem> _scheduleItems = [];
  bool _isLoading = true;
  bool _isDriverAvailable = false;
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'day'; // day, week, month

  // Подписка на изменения статуса
  StreamSubscription<bool>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _scheduleService = DriverScheduleService(supabaseService: _supabaseService);
    _loadDriverStatus();
    _loadScheduleData();

    // Подписываемся на изменения статуса
    _statusSubscription =
        _supabaseService.driverStatusStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isDriverAvailable = isOnline;
        });
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  // Инициализация локализации для форматирования дат
  Future<void> _initializeLocale() async {
    await initializeDateFormatting('ru_RU', null);
  }

  // Загрузка статуса водителя
  Future<void> _loadDriverStatus() async {
    try {
      final isOnline = await _supabaseService.getDriverOnlineStatus();
      if (mounted) {
        setState(() {
          _isDriverAvailable = isOnline;
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
          _isDriverAvailable = isOnline;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOnline
                    ? 'Вы теперь доступны для заказов'
                    : 'Вы не доступны для заказов',
              ),
              backgroundColor: isOnline ? Colors.green : Colors.grey,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось обновить статус'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Ошибка обновления статуса водителя: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Загрузка данных расписания
  Future<void> _loadScheduleData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final driverId = _supabaseService.currentUserId;
      if (driverId == null) {
        throw Exception('Не удалось получить ID водителя');
      }

      List<DriverScheduleItem> items = [];

      if (_viewMode == 'day') {
        items = await _scheduleService.getDriverScheduleForDay(
            driverId, _selectedDate);
      } else if (_viewMode == 'week') {
        items = await _scheduleService.getDriverScheduleForWeek(
            driverId, _getStartOfWeek(_selectedDate));
      } else if (_viewMode == 'month') {
        items = await _scheduleService.getDriverScheduleForMonth(
            driverId, _selectedDate);
      }

      // Если данных нет, используем тестовые данные
      if (items.isEmpty) {
        items = _scheduleService.getMockSchedule();
      }

      if (mounted) {
        setState(() {
          _scheduleItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки расписания: $e');
      if (mounted) {
        setState(() {
          _scheduleItems = _scheduleService.getMockSchedule();
          _isLoading = false;
        });
      }
    }
  }

  // Получение начала недели для выбранной даты
  DateTime _getStartOfWeek(DateTime date) {
    final difference = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - difference);
  }

  // Смена месяца
  void _changeMonth(int months) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + months,
        _selectedDate.day,
      );
    });
    _loadScheduleData();
  }

  // Смена режима просмотра (день, неделя, месяц)
  void _changeViewMode(String mode) {
    if (_viewMode != mode) {
      setState(() {
        _viewMode = mode;
      });
      _loadScheduleData();
    }
  }

  // Цвет статуса заказа
  Color _getRideTypeColor(RideType rideType) {
    switch (rideType) {
      case RideType.regular:
        return Colors.grey.shade600;
      case RideType.childTaxi:
        return const Color(0xFFD97706); // amber
      case RideType.premium:
        return const Color(0xFF6366F1); // indigo
      case RideType.delivery:
        return const Color(0xFF10B981); // emerald
      default:
        return Colors.grey.shade600;
    }
  }

  // Название типа заказа
  String _getRideTypeName(RideType rideType) {
    switch (rideType) {
      case RideType.regular:
        return 'Обычная поездка';
      case RideType.childTaxi:
        return 'Детское такси';
      case RideType.premium:
        return 'Премиум';
      case RideType.delivery:
        return 'Доставка';
      default:
        return 'Обычная поездка';
    }
  }

  // Виджет для элемента расписания
  Widget _buildScheduleItem(DriverScheduleItem item) {
    final hasSpecialRequirements = item.specialRequirements != null &&
        item.specialRequirements!.isNotEmpty;

    final startTimeFormatted = DateFormat('HH:mm').format(item.startTime);
    final endTimeFormatted = DateFormat('HH:mm').format(item.endTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: _getRideTypeColor(item.rideType),
            width: 4,
          ),
          top: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          right: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          bottom: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$startTimeFormatted - $endTimeFormatted',
                      style: const TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.rideType == RideType.childTaxi)
                          const Icon(
                            Icons.child_care,
                            size: 14,
                            color: Color(0xFFD97706),
                          ),
                        if (item.rideType == RideType.childTaxi)
                          const SizedBox(width: 4),
                        Text(
                          _getRideTypeName(item.rideType),
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 14,
                            color: _getRideTypeColor(item.rideType),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '₽${item.fare.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 10.5,
                  color: Colors.black,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item.pickupAddress} → ${item.dropoffAddress}',
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            if (hasSpecialRequirements &&
                item.specialRequirements!.containsKey('childSeat'))
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Требуется детское кресло (${item.specialRequirements!['childSeat']['age']} лет)',
                        style: const TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _openRouteMap(item.pickupAddress, item.dropoffAddress);
                    },
                    icon: const Icon(
                      Icons.map_outlined,
                      size: 16,
                      color: Color(0xFF4B5563),
                    ),
                    label: const Text('Маршрут'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF4B5563),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showContactOptions();
                    },
                    icon: const Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: Color(0xFF4B5563),
                    ),
                    label: const Text('Связаться'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF4B5563),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Открыть маршрут на карте
  void _openRouteMap(String pickup, String dropoff) {
    // Здесь можно было бы открыть маршрут на карте или перейти на экран карты
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Открываем маршрут: $pickup → $dropoff'),
      ),
    );
  }

  // Показать опции связи с клиентом
  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Связаться с клиентом',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF5EC7C3)),
              title: const Text('Позвонить'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Звоним клиенту...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Color(0xFF5EC7C3)),
              title: const Text('Отправить сообщение'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Открываем чат...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'График работы',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 24,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          child: const Icon(
            Icons.event_note,
            size: 17.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/driver/profile');
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                backgroundImage:
                    AssetImage('assets/images/avatar_placeholder.png'),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadScheduleData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Секция статуса
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Статус',
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                _updateDriverStatus(!_isDriverAvailable),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isDriverAvailable
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(9999),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isDriverAvailable
                                        ? Icons.check_circle_outline
                                        : Icons.cancel_outlined,
                                    size: 14,
                                    color: _isDriverAvailable
                                        ? const Color(0xFF047857)
                                        : const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isDriverAvailable
                                        ? 'Доступен для работы'
                                        : 'Не доступен для работы',
                                    style: TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _isDriverAvailable
                                          ? const Color(0xFF047857)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Секция месяца и режима просмотра
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Месяц и кнопки смены месяца
                          Container(
                            height: 50,
                            padding: const EdgeInsets.only(top: 12, bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('LLLL yyyy', 'ru_RU')
                                      .format(_selectedDate)
                                      .capitalizeFirst(),
                                  style: const TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _changeMonth(-1),
                                      icon: const Icon(Icons.chevron_left),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _changeMonth(1),
                                      icon: const Icon(Icons.chevron_right),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Переключатель режима просмотра
                          Container(
                            height: 48,
                            margin: const EdgeInsets.only(bottom: 8),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                _buildViewModeButton('day', 'День'),
                                const SizedBox(width: 12),
                                _buildViewModeButton('week', 'Неделя'),
                                const SizedBox(width: 12),
                                _buildViewModeButton('month', 'Месяц'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Содержимое расписания
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 237,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _viewMode == 'day'
                                ? 'Сегодня, ${DateFormat('d MMMM', 'ru_RU').format(_selectedDate).toLowerCase()}'
                                : _viewMode == 'week'
                                    ? '${DateFormat('d', 'ru_RU').format(_getStartOfWeek(_selectedDate))} - ${DateFormat('d MMMM', 'ru_RU').format(_getStartOfWeek(_selectedDate).add(const Duration(days: 6))).toLowerCase()}'
                                    : DateFormat('LLLL yyyy', 'ru_RU')
                                        .format(_selectedDate)
                                        .capitalizeFirst(),
                            style: const TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_scheduleItems.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text(
                                  'Нет запланированных поездок на этот период',
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            ..._scheduleItems
                                .map((item) => _buildScheduleItem(item))
                                .toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Кнопка переключения режима просмотра
  Widget _buildViewModeButton(String mode, String label) {
    final isSelected = _viewMode == mode;

    return GestureDetector(
      onTap: () => _changeViewMode(mode),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFED56AE) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(9999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFED56AE).withOpacity(0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}

// Расширение для первой заглавной буквы в строке
extension StringExtension on String {
  String capitalizeFirst() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}

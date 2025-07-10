import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../models/user_schedule_model.dart';
import '../services/user_schedule_service.dart';
import '../services/supabase_service.dart';

class UserScheduleScreen extends StatefulWidget {
  const UserScheduleScreen({Key? key}) : super(key: key);

  @override
  State<UserScheduleScreen> createState() => _UserScheduleScreenState();
}

class _UserScheduleScreenState extends State<UserScheduleScreen> {
  // Текущая дата
  late DateTime _selectedDate;
  // Контроллер для списка с датами
  final PageController _pageController = PageController(initialPage: 0);
  // Режим отображения (день, неделя, месяц)
  String _viewMode = 'day';
  // Индикатор загрузки
  bool _isLoading = false;
  // Запланированные поездки
  List<UserScheduledRide> _scheduledRides = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initializeData();
  }

  // Инициализация данных
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    // Инициализируем локализацию для правильного отображения дат
    await initializeDateFormatting('ru_RU', null);

    // Получаем данные из сервиса или используем демо-данные
    _loadScheduledRides();

    setState(() => _isLoading = false);
  }

  // Загрузка данных из сервиса
  Future<void> _loadScheduledRides() async {
    final userScheduleService =
        Provider.of<UserScheduleService>(context, listen: false);

    // Для демонстрации используем демо-данные
    setState(() {
      _scheduledRides = userScheduleService.getDemoScheduledRides();
    });

    // В реальном приложении:
    // final rides = await userScheduleService.getScheduledRidesForDate(_selectedDate);
    // setState(() {
    //   _scheduledRides = rides;
    // });
  }

  // Обработка смены даты
  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    _loadScheduledRides();
  }

  // Обработка изменения режима отображения
  void _onViewModeChanged(String mode) {
    setState(() {
      _viewMode = mode;
    });
    _loadScheduledRides();
  }

  // Переход к предыдущему периоду (день, неделя, месяц)
  void _goToPreviousPeriod() {
    DateTime newDate;
    switch (_viewMode) {
      case 'day':
        newDate = _selectedDate.subtract(const Duration(days: 1));
        break;
      case 'week':
        newDate = _selectedDate.subtract(const Duration(days: 7));
        break;
      case 'month':
        newDate = DateTime(
            _selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
        break;
      default:
        newDate = _selectedDate;
    }
    _onDateChanged(newDate);
  }

  // Переход к следующему периоду (день, неделя, месяц)
  void _goToNextPeriod() {
    DateTime newDate;
    switch (_viewMode) {
      case 'day':
        newDate = _selectedDate.add(const Duration(days: 1));
        break;
      case 'week':
        newDate = _selectedDate.add(const Duration(days: 7));
        break;
      case 'month':
        newDate = DateTime(
            _selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
        break;
      default:
        newDate = _selectedDate;
    }
    _onDateChanged(newDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        title: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.black),
            const SizedBox(width: 10),
            Text(
              'Расписание',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                Provider.of<SupabaseService>(context)
                        .currentUser
                        ?.userMetadata?['avatar_url'] ??
                    'https://via.placeholder.com/32',
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Секция выбора месяца и стрелок навигации
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy', 'ru').format(_selectedDate),
                            style: const TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: _goToPreviousPeriod,
                                child: Container(
                                  width: 26,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Icon(Icons.chevron_left,
                                      color: Colors.black),
                                ),
                              ),
                              InkWell(
                                onTap: _goToNextPeriod,
                                child: Container(
                                  width: 26,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Icon(Icons.chevron_right,
                                      color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Кнопки выбора режима отображения
                      Row(
                        children: [
                          _buildViewModeButton('day', 'День'),
                          const SizedBox(width: 12),
                          _buildViewModeButton('week', 'Неделя'),
                          const SizedBox(width: 12),
                          _buildViewModeButton('month', 'Месяц'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Заголовок "Предстоящие поездки"
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 20, bottom: 10),
                  child: Row(
                    children: [
                      Text(
                        'Предстоящие поездки',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // Отображение текущей даты
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        _isTodaySelected()
                            ? 'Сегодня, ${DateFormat('dd MMMM', 'ru').format(_selectedDate)}'
                            : DateFormat('dd MMMM', 'ru').format(_selectedDate),
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                // Список запланированных поездок
                Expanded(
                  child: _scheduledRides.isEmpty
                      ? Center(
                          child: Text(
                            'Нет запланированных поездок',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _scheduledRides.length,
                          itemBuilder: (context, index) {
                            return _buildScheduledRideCard(
                                _scheduledRides[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Переход к экрану добавления новой поездки
        },
        backgroundColor: const Color(0xFF5EC7C3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Проверяет, выбрана ли текущая дата
  bool _isTodaySelected() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // Создает кнопку выбора режима отображения
  Widget _buildViewModeButton(String mode, String title) {
    final isSelected = _viewMode == mode;

    return InkWell(
      onTap: () => _onViewModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFED56AE) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  // Создает карточку запланированной поездки
  Widget _buildScheduledRideCard(UserScheduledRide ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Шапка карточки с информацией о сервисе и цене
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_taxi, size: 18, color: Colors.black),
                        const SizedBox(width: 5),
                        Text(
                          'Мама такси',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ride.formattedDateTime,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                Text(
                  '₽${ride.price.toInt()}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Информация о ребенке
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    ride.childPhotoUrl ?? 'https://via.placeholder.com/32',
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.childName ?? 'Ребенок',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.cake, size: 13.5, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          '${ride.childAge} лет',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Адреса начала и конца поездки
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.circle_outlined, size: 12, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      ride.startAddress,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      ride.endAddress,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Логика для изменения поездки
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEB5CAC),
                      side: const BorderSide(color: Color(0xFFEB5CAC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      minimumSize: const Size(0, 38),
                    ),
                    child: const Text('Изменить'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Логика для отслеживания поездки
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEB5CAC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      minimumSize: const Size(0, 38),
                    ),
                    child: const Text('Отследить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

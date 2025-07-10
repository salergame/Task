import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/payment_history_model.dart';
import '../services/driver_earnings_service.dart';
import '../services/supabase_service.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({Key? key}) : super(key: key);

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late final DriverEarningsService _earningsService;

  bool _isLoading = true;
  late DriverEarnings _earnings;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _earningsService = DriverEarningsService(supabaseService: _supabaseService);
    _loadEarningsData();
  }

  // Инициализация локализации для форматирования дат
  Future<void> _initializeLocale() async {
    await initializeDateFormatting('ru', null);
  }

  // Загрузка данных о заработке
  Future<void> _loadEarningsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final driverId = _supabaseService.currentUserId;
      if (driverId == null) {
        throw Exception('Не удалось получить ID водителя');
      }

      final earnings =
          await _earningsService.getDriverEarnings(driverId, _selectedMonth);

      setState(() {
        _earnings = earnings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки данных о заработке: $e');

      // Используем демо-данные
      setState(() {
        _earnings = DriverEarnings.demo();
        _isLoading = false;
      });
    }
  }

  // Изменение месяца
  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
    });
    _loadEarningsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9F7),
      appBar: AppBar(
        title: const Text(
          'Доходы и выплаты',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          child: const Icon(
            Icons.monetization_on_outlined,
            size: 17.5,
          ),
        ),
        leadingWidth: 40,
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
              onRefresh: _loadEarningsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Общий доход за месяц
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Общий доход за месяц',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _earningsService
                                .formatAmount(_earnings.totalAmount),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF53CFC4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'За ${_earningsService.getFormattedMonth(_earnings.month).toLowerCase()}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Разделение доходов
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Разделение доходов',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Доход за поездки
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.directions_car_outlined,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Доход за поездки',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _earningsService
                                      .formatAmount(_earnings.rideEarnings),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Бонусы и акции
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.card_giftcard,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Бонусы и акции',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _earningsService
                                      .formatAmount(_earnings.bonusEarnings),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // История поездок
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'История поездок',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Список истории платежей
                          ..._earnings.history
                              .map((item) => _buildHistoryItem(item))
                              .toList(),
                        ],
                      ),
                    ),

                    // Кнопки для переключения месяца
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => _changeMonth(-1),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_back_ios, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Предыдущий месяц',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _changeMonth(1),
                            child: Row(
                              children: [
                                Text(
                                  'Следующий месяц',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Нижний отступ
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // Элемент истории платежей
  Widget _buildHistoryItem(PaymentHistoryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    item.getIcon(),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _earningsService.formatPaymentDate(item.date),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          Text(
            _earningsService.formatAmount(item.amount, withPlus: true),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

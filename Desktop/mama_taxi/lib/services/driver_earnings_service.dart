import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_history_model.dart';
import 'supabase_service.dart';
import 'package:intl/intl.dart';

class DriverEarningsService {
  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseService _supabaseService;

  DriverEarningsService({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  // Получить заработок водителя за указанный месяц
  Future<DriverEarnings> getDriverEarnings(
      String driverId, DateTime month) async {
    try {
      // Начало и конец месяца
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // Получаем историю платежей
      final historyResponse = await _client
          .from('driver_payments')
          .select()
          .eq('driver_id', driverId)
          .gte('date', startOfMonth.toIso8601String())
          .lte('date', endOfMonth.toIso8601String())
          .order('date', ascending: false);

      // Конвертируем историю в объекты
      final history = (historyResponse as List)
          .map<PaymentHistoryItem>((item) => PaymentHistoryItem.fromJson(item))
          .toList();

      // Получаем итоговые суммы
      final totalAmount =
          history.fold<double>(0, (sum, item) => sum + item.amount);

      // Суммы по категориям
      final rideEarnings = history
          .where((item) =>
              item.type == PaymentType.ride ||
              item.type == PaymentType.specialRide ||
              item.type == PaymentType.emergency ||
              item.type == PaymentType.childCare ||
              item.type == PaymentType.premium)
          .fold<double>(0, (sum, item) => sum + item.amount);

      final bonusEarnings = history
          .where((item) => item.type == PaymentType.bonus)
          .fold<double>(0, (sum, item) => sum + item.amount);

      return DriverEarnings(
        totalAmount: totalAmount,
        month: startOfMonth,
        rideEarnings: rideEarnings,
        bonusEarnings: bonusEarnings,
        history: history,
      );
    } catch (e) {
      debugPrint('Ошибка получения данных о заработке: $e');

      // Возвращаем демо-данные в случае ошибки
      return DriverEarnings.demo();
    }
  }

  // Получить форматированное название месяца
  String getFormattedMonth(DateTime month, {String locale = 'ru'}) {
    try {
      final formatter = DateFormat('LLLL yyyy', locale);
      final formatted = formatter.format(month);
      return formatted[0].toUpperCase() + formatted.substring(1);
    } catch (e) {
      // Если произошла ошибка с форматированием, используем стандартный формат
      final List<String> russianMonths = [
        'Январь',
        'Февраль',
        'Март',
        'Апрель',
        'Май',
        'Июнь',
        'Июль',
        'Август',
        'Сентябрь',
        'Октябрь',
        'Ноябрь',
        'Декабрь'
      ];

      return '${russianMonths[month.month - 1]} ${month.year}';
    }
  }

  // Форматировать дату поездки
  String formatPaymentDate(DateTime date) {
    try {
      final List<String> russianMonths = [
        'января',
        'февраля',
        'марта',
        'апреля',
        'мая',
        'июня',
        'июля',
        'августа',
        'сентября',
        'октября',
        'ноября',
        'декабря'
      ];

      return '${date.day} ${russianMonths[date.month - 1]}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      // Если произошла ошибка, используем стандартный формат
      return DateFormat('dd.MM, HH:mm').format(date);
    }
  }

  // Форматировать сумму в рублях
  String formatAmount(double amount, {bool withPlus = false}) {
    final isPositive = amount >= 0;
    final formattedAmount = amount.abs().toStringAsFixed(0);
    final sign = (withPlus && isPositive) ? '+' : '';
    return '$sign$formattedAmount₽';
  }
}

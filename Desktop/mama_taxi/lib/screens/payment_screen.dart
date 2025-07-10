import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/payment_model.dart';
import '../utils/constants.dart';
import '../widgets/add_payment_method_modal.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoadingPaymentMethods = true;
  bool _isLoadingTransactions = true;
  List<PaymentMethod> _paymentMethods = [];
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  late TabController _tabController;

  // Фильтры для транзакций
  TransactionType? _selectedTransactionType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPaymentMethods();
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Загрузка платежных методов
  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoadingPaymentMethods = true;
    });

    try {
      final paymentMethods = await _supabaseService.getPaymentMethods();
      setState(() {
        _paymentMethods = paymentMethods;
        _isLoadingPaymentMethods = false;
      });

      // Показываем сообщение о тестовых данных
      if (_paymentMethods.isNotEmpty && _paymentMethods[0].id == '1') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Используются тестовые данные для платежных методов'),
            backgroundColor: AppColors.info,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка загрузки платежных методов: $e');
      setState(() {
        _isLoadingPaymentMethods = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки платежных методов: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Загрузка истории транзакций
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final transactions = await _supabaseService.getTransactions(
        startDate: _startDate,
        endDate: _endDate,
        type: _selectedTransactionType,
      );
      setState(() {
        _transactions = transactions;
        _filteredTransactions = transactions;
        _isLoadingTransactions = false;
      });

      // Показываем сообщение о тестовых данных
      if (_transactions.isNotEmpty && _transactions[0].id == '1') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Используются тестовые данные для транзакций'),
            backgroundColor: AppColors.info,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка загрузки истории транзакций: $e');
      setState(() {
        _isLoadingTransactions = false;
        _filteredTransactions = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки истории транзакций: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Фильтрация транзакций
  void _filterTransactions() {
    setState(() {
      _isLoadingTransactions = true;
    });

    _loadTransactions();
  }

  // Сброс фильтров
  void _resetFilters() {
    setState(() {
      _selectedTransactionType = null;
      _startDate = null;
      _endDate = null;
    });
    _loadTransactions();
  }

  // Добавление нового платежного метода
  Future<void> _showAddPaymentMethodModal() async {
    final result = await showModalBottomSheet<PaymentMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPaymentMethodModal(),
    );

    if (result != null) {
      try {
        final success = await _supabaseService.addPaymentMethod(
          type: result.type,
          title: result.title,
          lastFourDigits: result.lastFourDigits,
          isDefault: result.isDefault,
          cardType: result.cardType,
          expiryDate: result.expiryDate,
        );

        if (success) {
          _loadPaymentMethods();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Способ оплаты успешно добавлен'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось добавить способ оплаты'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Удаление платежного метода
  Future<void> _deletePaymentMethod(String paymentMethodId) async {
    try {
      final success =
          await _supabaseService.deletePaymentMethod(paymentMethodId);
      if (success) {
        setState(() {
          _paymentMethods.removeWhere((method) => method.id == paymentMethodId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Платежный метод успешно удален'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось удалить платежный метод'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Установка платежного метода по умолчанию
  Future<void> _setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      final success =
          await _supabaseService.setDefaultPaymentMethod(paymentMethodId);
      if (success) {
        await _loadPaymentMethods(); // Перезагружаем список платежных методов
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Платежный метод установлен по умолчанию'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось установить платежный метод по умолчанию'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPaymentMethodsTab(),
                  _buildTransactionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.8),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF3F4F6),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 15.5),
            const Text(
              'Оплата и счета',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Способы оплаты'),
          Tab(text: 'История транзакций'),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsTab() {
    return _isLoadingPaymentMethods
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Сохраненные способы оплаты',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 16),
                if (_paymentMethods.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'У вас нет сохраненных способов оплаты',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: _paymentMethods
                        .map((method) => _buildPaymentMethodCard(method))
                        .toList(),
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showAddPaymentMethodModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Добавить способ оплаты'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    IconData cardIcon;
    if (method.cardType == 'visa') {
      cardIcon = Icons.credit_card;
    } else if (method.cardType == 'mastercard') {
      cardIcon = Icons.credit_card;
    } else {
      cardIcon = Icons.credit_card;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: method.isDefault ? AppColors.primary : AppColors.border,
          width: method.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                cardIcon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.title,
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '**** ${method.lastFourDigits}${method.expiryDate != null ? ' • ${method.expiryDate}' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (method.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'По умолчанию',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'delete') {
                  _deletePaymentMethod(method.id);
                } else if (value == 'default') {
                  _setDefaultPaymentMethod(method.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Сделать основным'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Удалить'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return _isLoadingTransactions
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildTransactionFilters(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'История операций',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_filteredTransactions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'У вас нет истории транзакций',
                              style: TextStyle(
                                fontFamily: 'Rubik',
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: _buildTransactionsList(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
  }

  Widget _buildTransactionFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фильтры',
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showDateRangePickerDialog(),
                icon: const Icon(Icons.date_range, color: AppColors.primary),
                tooltip: 'Выбрать период',
              ),
              IconButton(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                tooltip: 'Сбросить фильтры',
              ),
            ],
          ),
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Период: ${DateFormat('dd.MM.yyyy').format(_startDate!)} - ${DateFormat('dd.MM.yyyy').format(_endDate!)}',
                style: const TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TransactionType?>(
          value: _selectedTransactionType,
          hint: const Text('Тип операции'),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textSecondary),
          items: [
            const DropdownMenuItem<TransactionType?>(
              value: null,
              child: Text('Все операции'),
            ),
            ...TransactionType.values.map((type) {
              return DropdownMenuItem<TransactionType>(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTransactionType = value;
            });
            _filterTransactions();
          },
        ),
      ),
    );
  }

  Future<void> _showDateRangePickerDialog() async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _endDate ?? DateTime.now(),
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
      });
      _filterTransactions();
    }
  }

  List<Widget> _buildTransactionsList() {
    // Группировка транзакций по дате
    final Map<String, List<Transaction>> groupedTransactions = {};

    for (final transaction in _filteredTransactions) {
      final dateKey = DateFormat('dd.MM.yyyy').format(transaction.date);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    // Сортировка дат в обратном порядке (от новых к старым)
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd.MM.yyyy').parse(a);
        final dateB = DateFormat('dd.MM.yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    final List<Widget> result = [];

    for (final dateKey in sortedDates) {
      result.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            dateKey,
            style: const TextStyle(
              fontFamily: 'Rubik',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );

      for (final transaction in groupedTransactions[dateKey]!) {
        result.add(_buildTransactionCard(transaction));
      }
    }

    return result;
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final formattedAmount = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    ).format(transaction.amount);

    final formattedTime = DateFormat('HH:mm').format(transaction.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                transaction.type.icon,
                color: transaction.status == TransactionStatus.refunded
                    ? AppColors.info
                    : AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.type == TransactionType.refund
                    ? '+$formattedAmount'
                    : transaction.amount > 0
                        ? '-$formattedAmount'
                        : formattedAmount,
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: transaction.type == TransactionType.refund
                      ? AppColors.success
                      : transaction.amount > 0
                          ? AppColors.text
                          : AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: transaction.status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 12,
                      color: transaction.status.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

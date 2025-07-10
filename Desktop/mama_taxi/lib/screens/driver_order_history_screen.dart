import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/supabase_service.dart';
import '../widgets/primary_button.dart';

class DriverOrderHistoryScreen extends StatefulWidget {
  const DriverOrderHistoryScreen({super.key});

  @override
  State<DriverOrderHistoryScreen> createState() =>
      _DriverOrderHistoryScreenState();
}

class _DriverOrderHistoryScreenState extends State<DriverOrderHistoryScreen> {
  final OrderService _orderService = OrderService(
    supabaseService: SupabaseService(),
  );
  bool _isLoading = true;
  List<OrderModel> _orderHistory = [];

  // Фильтры
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showCompleted = true;
  bool _showCancelled = true;

  // Пагинация
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMoreOrders = true;

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  Future<void> _loadOrderHistory({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _orderHistory = [];
        _hasMoreOrders = true;
      });
    }

    if (!_hasMoreOrders && !reset) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<OrderModel> newOrders;

      // Используем демо-данные для отладки
      if (const bool.fromEnvironment('USE_DEMO_DATA', defaultValue: true)) {
        newOrders = _orderService.getDemoOrderHistory();
      } else {
        newOrders = await _orderService.getOrderHistory(
          startDate: _startDate,
          endDate: _endDate,
          limit: _pageSize,
          offset: _currentPage * _pageSize,
        );
      }

      // Применяем фильтры по статусу
      final filteredOrders = newOrders
          .where((order) =>
              (order.isCompleted && _showCompleted) ||
              (order.isCancelled && _showCancelled))
          .toList();

      if (mounted) {
        setState(() {
          if (reset) {
            _orderHistory = filteredOrders;
          } else {
            _orderHistory.addAll(filteredOrders);
          }
          _currentPage++;
          _hasMoreOrders = newOrders.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки истории заказов: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _showCompleted = true;
      _showCancelled = true;
    });
    _loadOrderHistory(reset: true);
  }

  void _applyFilters() {
    _loadOrderHistory(reset: true);
  }

  Future<void> _selectDateRange() async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _endDate ?? DateTime.now(),
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).primaryColor,
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
      _loadOrderHistory(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'История заказов',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          child: const Icon(
            Icons.history,
            size: 17.5,
          ),
        ),
        leadingWidth: 40,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'date') {
                _selectDateRange();
              } else if (value == 'reset') {
                _resetFilters();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Выбрать период'),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Text('Сбросить фильтры'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading && _orderHistory.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _orderHistory.isEmpty
                    ? _buildEmptyState()
                    : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('dd.MM.yyyy').format(_startDate!)} - ${DateFormat('dd.MM.yyyy').format(_endDate!)}',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadOrderHistory(reset: true);
                    },
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              FilterChip(
                label: const Text('Завершенные'),
                selected: _showCompleted,
                checkmarkColor: Colors.white,
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: _showCompleted ? Colors.white : Colors.black87,
                  fontFamily: 'Manrope',
                ),
                onSelected: (selected) {
                  setState(() {
                    _showCompleted = selected;
                  });
                  _loadOrderHistory(reset: true);
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Отмененные'),
                selected: _showCancelled,
                checkmarkColor: Colors.white,
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: _showCancelled ? Colors.white : Colors.black87,
                  fontFamily: 'Manrope',
                ),
                onSelected: (selected) {
                  setState(() {
                    _showCancelled = selected;
                  });
                  _loadOrderHistory(reset: true);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'История заказов пуста',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Завершенные заказы появятся здесь',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Сбросить фильтры',
            onPressed: _resetFilters,
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoading &&
            _hasMoreOrders &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadOrderHistory();
          return true;
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orderHistory.length + (_hasMoreOrders ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orderHistory.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final order = _orderHistory[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с информацией о заказе
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    order.statusIcon,
                    color: order.statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.isCompleted ? 'Заказ выполнен' : 'Заказ отменен',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        order.formattedCompletedAt ?? order.formattedCreatedAt,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${order.price.toStringAsFixed(0)} ₽',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Информация о маршруте
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.startAddress,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 9),
                    child: SizedBox(
                      height: 20,
                      child: VerticalDivider(
                        color: Colors.grey,
                        thickness: 1,
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.flag_outlined,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.endAddress,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Дополнительная информация
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.isCompleted)
                  _buildInfoItem(
                    Icons.payment,
                    'Оплата',
                    order.isPaid ? 'Оплачено' : 'Не оплачено',
                  ),
                if (order.paymentMethod != null)
                  _buildInfoItem(
                    Icons.credit_card,
                    'Способ',
                    order.paymentMethod!,
                  ),
                if (order.clientName != null)
                  _buildInfoItem(
                    Icons.person_outline,
                    'Клиент',
                    order.clientName!,
                  ),
                if (order.childCount != null && order.childCount! > 0)
                  _buildInfoItem(
                    Icons.child_care,
                    'Дети',
                    order.childCount.toString(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade700,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

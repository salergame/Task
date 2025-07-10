import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/supabase_service.dart';
import '../widgets/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverActiveOrdersScreen extends StatefulWidget {
  const DriverActiveOrdersScreen({super.key});

  @override
  State<DriverActiveOrdersScreen> createState() =>
      _DriverActiveOrdersScreenState();
}

class _DriverActiveOrdersScreenState extends State<DriverActiveOrdersScreen> {
  final OrderService _orderService = OrderService(
    supabaseService: SupabaseService(),
  );
  bool _isLoading = true;
  List<OrderModel> _activeOrders = [];

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
    _orderService.subscribeToActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Используем демо-данные для отладки
      if (const bool.fromEnvironment('USE_DEMO_DATA', defaultValue: true)) {
        _activeOrders = _orderService.getDemoActiveOrders();
      } else {
        _activeOrders = await _orderService.getActiveOrders();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки активных заказов: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _callClient(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      debugPrint('Ошибка при звонке клиенту: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось совершить звонок'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startRide(String orderId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _orderService.startRide(orderId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Поездка началась'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка начала поездки: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось начать поездку'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await _loadActiveOrders();
    }
  }

  Future<void> _completeRide(String orderId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _orderService.completeOrder(orderId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Поездка завершена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка завершения поездки: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось завершить поездку'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await _loadActiveOrders();
    }
  }

  Future<void> _cancelRide(String orderId) async {
    // Показываем диалог для ввода причины отмены
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Причина отмены'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Укажите причину отмены',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _orderService.cancelOrder(orderId, reason);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заказ отменен'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка отмены заказа: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось отменить заказ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await _loadActiveOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Активные заказы',
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
            Icons.directions_car_outlined,
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
              onRefresh: _loadActiveOrders,
              child: _activeOrders.isEmpty
                  ? _buildEmptyState()
                  : _buildOrdersList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.car_rental,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'У вас нет активных заказов',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Активные заказы появятся здесь',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Обновить',
            onPressed: _loadActiveOrders,
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeOrders.length,
      itemBuilder: (context, index) {
        final order = _activeOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    // Определяем действия в зависимости от статуса заказа
    Widget actionButtons;
    if (order.status == OrderStatus.accepted) {
      actionButtons = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: PrimaryButton(
              text: 'Начать поездку',
              onPressed: () => _startRide(order.id),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _cancelRide(order.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Отменить'),
          ),
        ],
      );
    } else if (order.status == OrderStatus.inProgress) {
      actionButtons = PrimaryButton(
        text: 'Завершить поездку',
        onPressed: () => _completeRide(order.id),
        color: Colors.green,
      );
    } else {
      actionButtons = Container();
    }

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
            // Заголовок с информацией о клиенте
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: order.clientAvatarUrl != null
                      ? NetworkImage(order.clientAvatarUrl!)
                      : const AssetImage('assets/images/avatar_placeholder.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.clientName ?? 'Клиент',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (order.clientPhone != null)
                        GestureDetector(
                          onTap: () => _callClient(order.clientPhone!),
                          child: Text(
                            order.clientPhone!,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        order.statusIcon,
                        color: order.statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.statusText,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: order.statusColor,
                        ),
                      ),
                    ],
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
            // Детали заказа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  Icons.access_time,
                  'Время',
                  order.formattedCreatedAt,
                ),
                _buildDetailItem(
                  Icons.attach_money,
                  'Стоимость',
                  '${order.price.toStringAsFixed(0)} ₽',
                ),
                if (order.childCount != null && order.childCount! > 0)
                  _buildDetailItem(
                    Icons.child_care,
                    'Дети',
                    order.childCount.toString(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Кнопки действий
            actionButtons,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
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

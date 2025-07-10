import 'package:flutter/material.dart';
import 'package:mama_taxi/services/admin_service.dart';
import 'package:mama_taxi/utils/constants.dart';
import 'package:mama_taxi/widgets/custom_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _pendingDrivers = [];
  List<Map<String, dynamic>> _recentActions = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Проверяем права администратора
      final isAdmin = await _adminService.isAdmin();
      if (!isAdmin) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Недостаточно прав для доступа к админ-панели'),
            backgroundColor: AppColors.error,
          ),
        );

        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // Загружаем данные для дашборда
      final stats = await _adminService.getAdminStats();
      final pendingDrivers = await _adminService.getPendingDrivers();
      final recentActions = await _adminService.getRecentActions(10);

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _pendingDrivers = pendingDrivers;
        _recentActions = recentActions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки данных: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель Мама Такси'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Обзор'),
            Tab(text: 'Водители'),
            Tab(text: 'Логи'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildDriversTab(),
                _buildLogsTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Статистика', style: AppTextStyles.heading),
          const SizedBox(height: 16),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          const Text('Активные поездки', style: AppTextStyles.subheading),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _adminService.getActiveRides(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Ошибка загрузки данных: ${snapshot.error}',
                    style: AppTextStyles.error,
                  ),
                );
              }

              final rides = snapshot.data ?? [];

              if (rides.isEmpty) {
                return const Center(
                  child: Text('Нет активных поездок'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rides.length,
                itemBuilder: (context, index) {
                  final ride = rides[index];
                  final driver = ride['driver'] as Map<String, dynamic>?;
                  final client = ride['client'] as Map<String, dynamic>?;

                  return Card(
                    child: ListTile(
                      title: Text(
                        'Поездка #${ride['id'] ?? 'N/A'}',
                        style: AppTextStyles.subtitle,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Водитель: ${driver?['full_name'] ?? 'Неизвестно'}'),
                          Text(
                              'Клиент: ${client?['full_name'] ?? 'Неизвестно'}'),
                          Text('Сумма: ${ride['amount'] ?? 0} руб.'),
                        ],
                      ),
                      trailing: const Icon(Icons.car_rental),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Активные поездки',
          '${_stats['activeRides'] ?? 0}',
          Icons.directions_car,
          AppColors.primary,
        ),
        _buildStatCard(
          'Ожидают проверки',
          '${_stats['pendingDrivers'] ?? 0}',
          Icons.pending_actions,
          AppColors.warning,
        ),
        _buildStatCard(
          'Поездок сегодня',
          '${_stats['completedToday'] ?? 0}',
          Icons.check_circle,
          AppColors.success,
        ),
        _buildStatCard(
          'Выручка сегодня',
          '${_stats['revenueToday'] ?? 0} ₽',
          Icons.payments,
          AppColors.info,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriversTab() {
    return _pendingDrivers.isEmpty
        ? const Center(
            child: Text('Нет водителей, ожидающих проверки'),
          )
        : ListView.builder(
            itemCount: _pendingDrivers.length,
            itemBuilder: (context, index) {
              final driver = _pendingDrivers[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ExpansionTile(
                  title: Text(
                    driver['full_name'] ?? 'Неизвестно',
                    style: AppTextStyles.subtitle,
                  ),
                  subtitle: Text(
                    'Телефон: ${driver['phone'] ?? 'Не указан'}',
                  ),
                  leading: CircleAvatar(
                    backgroundImage: driver['profile_image_url'] != null
                        ? NetworkImage(driver['profile_image_url'])
                        : null,
                    child: driver['profile_image_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Документы водителя:',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _adminService.getDriverDocuments(
                              driver['id'],
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Ошибка загрузки документов: ${snapshot.error}',
                                    style: AppTextStyles.error,
                                  ),
                                );
                              }

                              final documents = snapshot.data ?? [];

                              if (documents.isEmpty) {
                                return const Center(
                                  child: Text('Документы не загружены'),
                                );
                              }

                              return Column(
                                children: documents.map((doc) {
                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                          doc['document_type'] ?? 'Документ'),
                                      subtitle: Text(
                                        'Загружен: ${doc['created_at'] ?? 'Неизвестно'}',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.visibility),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(
                                                  doc['document_type'] ??
                                                      'Документ'),
                                              content: doc['file_url'] != null
                                                  ? Image.network(
                                                      doc['file_url'],
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) return child;
                                                        return Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            value: loadingProgress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : const Text(
                                                      'Невозможно загрузить изображение'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: const Text('Закрыть'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Решение:',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Одобрить',
                                  color: AppColors.success,
                                  onPressed: () async {
                                    final commentController =
                                        TextEditingController();
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Подтверждение'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Вы уверены, что хотите одобрить документы этого водителя?',
                                            ),
                                            const SizedBox(height: 16),
                                            TextField(
                                              controller: commentController,
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'Комментарий (опционально)',
                                                border: OutlineInputBorder(),
                                              ),
                                              maxLines: 3,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Отмена'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Подтвердить'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (result == true) {
                                      // Показываем индикатор загрузки
                                      if (!mounted) return;

                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => const AlertDialog(
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 16),
                                              Text('Обработка...'),
                                            ],
                                          ),
                                        ),
                                      );

                                      try {
                                        final success =
                                            await _adminService.approveDriver(
                                          driver['id'],
                                          commentController.text,
                                        );

                                        if (!mounted) return;
                                        Navigator.of(context)
                                            .pop(); // Закрываем диалог загрузки

                                        if (success) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Водитель успешно одобрен'),
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          );
                                          _loadData(); // Обновляем данные
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Не удалось одобрить водителя'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        Navigator.of(context)
                                            .pop(); // Закрываем диалог загрузки

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Ошибка: $e'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomButton(
                                  text: 'Отклонить',
                                  color: AppColors.error,
                                  onPressed: () async {
                                    final commentController =
                                        TextEditingController();
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Отклонение'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Вы уверены, что хотите отклонить документы этого водителя?',
                                            ),
                                            const SizedBox(height: 16),
                                            TextField(
                                              controller: commentController,
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'Причина отклонения (обязательно)',
                                                border: OutlineInputBorder(),
                                              ),
                                              maxLines: 3,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Отмена'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (commentController.text
                                                  .trim()
                                                  .isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Необходимо указать причину отклонения'),
                                                    backgroundColor:
                                                        AppColors.error,
                                                  ),
                                                );
                                                return;
                                              }
                                              Navigator.of(context).pop(true);
                                            },
                                            child: const Text('Подтвердить'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (result == true) {
                                      // Показываем индикатор загрузки
                                      if (!mounted) return;

                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => const AlertDialog(
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 16),
                                              Text('Обработка...'),
                                            ],
                                          ),
                                        ),
                                      );

                                      try {
                                        final success =
                                            await _adminService.rejectDriver(
                                          driver['id'],
                                          commentController.text,
                                        );

                                        if (!mounted) return;
                                        Navigator.of(context)
                                            .pop(); // Закрываем диалог загрузки

                                        if (success) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Водитель успешно отклонен'),
                                              backgroundColor: AppColors.info,
                                            ),
                                          );
                                          _loadData(); // Обновляем данные
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Не удалось отклонить водителя'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        Navigator.of(context)
                                            .pop(); // Закрываем диалог загрузки

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Ошибка: $e'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
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
            },
          );
  }

  Widget _buildLogsTab() {
    return _recentActions.isEmpty
        ? const Center(
            child: Text('Нет записей о действиях'),
          )
        : ListView.builder(
            itemCount: _recentActions.length,
            itemBuilder: (context, index) {
              final action = _recentActions[index];
              final admin = action['admin'] as Map<String, dynamic>?;
              final details = action['details'] as Map<String, dynamic>?;

              String actionText = 'Неизвестное действие';
              IconData actionIcon = Icons.info;
              Color actionColor = AppColors.primary;

              // Определение типа действия
              switch (action['action_type']) {
                case 'driver_verification_approved':
                  actionText = 'Одобрение водителя';
                  actionIcon = Icons.check_circle;
                  actionColor = AppColors.success;
                  break;
                case 'driver_verification_rejected':
                  actionText = 'Отклонение водителя';
                  actionIcon = Icons.cancel;
                  actionColor = AppColors.error;
                  break;
                case 'login':
                  actionText = 'Вход в систему';
                  actionIcon = Icons.login;
                  actionColor = AppColors.info;
                  break;
                case 'logout':
                  actionText = 'Выход из системы';
                  actionIcon = Icons.logout;
                  actionColor = AppColors.warning;
                  break;
              }

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: actionColor.withOpacity(0.2),
                    child: Icon(actionIcon, color: actionColor),
                  ),
                  title: Text(
                    actionText,
                    style: AppTextStyles.subtitle,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Администратор: ${admin?['full_name'] ?? 'Неизвестно'}'),
                      Text('Дата: ${action['created_at'] ?? 'Неизвестно'}'),
                      if (details != null && details['comment'] != null)
                        Text('Комментарий: ${details['comment']}'),
                    ],
                  ),
                  isThreeLine: details != null && details['comment'] != null,
                ),
              );
            },
          );
  }
}
